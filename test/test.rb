#!/usr/bin/env ruby

# This requires Ruby 2.5.0 or later because it uses a new syntax for rescuing
# exceptions in a block with needing to make an extra begin/end pair.

require 'open3'
require 'pathname'
require 'set'
require 'sqlite3'  # gem install sqlite3
require_relative 'graph'
require_relative 'expand_brackets'

class AnticipatedError < RuntimeError
end

# Don't automatically change directory because maybe people want to test one
# nixcrpkgs repository using the test script from another one.  But do give an
# early, friendly warning if they are running in the wrong directory.
def check_directory!
  return if File.directory?('pretend_stdenv')
  $stderr.puts "You should run this script from the nixcrpkgs directory."
  dir = Pathname(__FILE__).parent.parent
  $stderr.puts "Try running these commands:\n  cd #{dir}\n  test/test.rb"
  exit 1
end

def substitute_definitions(defs, str)
  str.gsub(/\$([\w-]+)/) do |x|
    defs.fetch($1)
  end
end

def parse_derivation_list(filename)
  defs = {}
  all_paths = Set.new
  all_attrs = {}
  File.foreach(filename).with_index do |line, line_index|
    line.strip!

    # Handle empty lines and comments.
    next if line.empty? || line.start_with?('#')

    # Handle variable definitions (e.g. "define windows = win32,win64").
    if line.start_with?('define')
      md = line.match(/^define\s+([\w-]+)\s*=\s*(.*)$/)
      if !md
        raise AnticipatedError, "Invalid definition syntax."
      end
      name, value = md[1], md[2]
      defs[name] = value
      next
    end

    # Expand variable definitions (e.g. $windows expands to "win32,win64").
    line = substitute_definitions(defs, line)

    # Figure out which parts of the line are attribute paths with brackets and
    # which are attributes.
    items = line.split(' ')
    attr_defs, path_items = items.partition { |p| p.include?('=') }

    # Expand any brackets in the attribute paths to get the complete list of
    # paths specified on this line.
    paths = path_items.flat_map { |p| expand_brackets(p) }.map(&:to_sym)

    # Process attribute definitions on the line, like "priority=1".
    attrs = {}
    attr_defs.each do |attr_def|
      md = attr_def.match(/^(\w+)=(\d+)$/)
      if !md
        raise AnticipatedError, "Invalid attribute definition: #{attr_def.inspect}."
      end
      name, value = md[1], md[2]
      case name
      when 'priority', 'slow'
        attrs[name.to_sym] = value.to_i
      else
        raise AnticipatedError, "Unrecognized attribute: #{name.inspect}."
      end
    end

    # Record the paths for this line and the attributes for those paths,
    # overriding previous attributes values if necessary.
    all_paths += paths
    if !attrs.empty?
      paths.each do |path|
        (all_attrs[path] ||= {}).merge!(attrs)
      end
    end
  rescue AnticipatedError => e
    raise AnticipatedError, "#{filename}:#{line_index + 1}: error: #{e}"
  end

  if all_paths.empty?
    raise AnticipatedError, "#{filename} specifies no paths"
  end

  all_paths.each do |path|
    if !path.match?(/^[\w.-]+$/)
      raise "Invalid characters in path name: #{path}"
    end
  end

  { defs: defs, paths: all_paths.to_a, attrs: all_attrs }
end

# Make a hash holding the priority of each Nix attribute path we want to build.
# This routine determines the default priority.
def make_path_priority_map(settings)
  attrs = settings.fetch(:attrs)
  m = {}
  settings.fetch(:paths).each do |path|
    m[path] = attrs.fetch(path, {}).fetch(:priority, 0)
  end
  m
end

# Make a hash holding the relative build time of each Nix attribute path we want
# to build.  This routine detrmines the default time, and what "slow" means.
def make_path_time_map(settings)
  attrs = settings.fetch(:attrs)
  m = {}
  settings.fetch(:paths).each do |path|
    m[path] = attrs.fetch(path, {})[:slow] ? 100 : 1
  end
  m
end

def instantiate_drvs(paths)
  cmd = 'nix-instantiate ' + paths.map { |p| "-A #{p}" }.join(' ')
  stdout_str, stderr_str, status = Open3.capture3(cmd)
  if !status.success?
    $stderr.puts stderr_str
    raise AnticipatedError, "Failed to instantiate derivations."
  end
  paths.zip(stdout_str.split.map(&:to_sym)).to_h
end

# We want there to be a one-to-one mapping between paths in the derivations.txt
# list and derivations, so we can make a graph of dependencies of the
# derivations and each derivation in the graph will have a unique path in the
# derivations.txt list.
def check_paths_are_unique!(path_drv_map)
  set = Set.new
  path_drv_map.each do |key, drv|
    if set.include?(drv)
      raise AnticipatedError, "The derivation #{key} is the same as " \
        "other derivations in the list.  Maybe use the 'omni' namespace."
    end
    set << drv
  end
end

def map_compose(map1, map2)
  map1.transform_values &map2.method(:fetch)
end

def nix_db
  return $db if $db
  $db = SQLite3::Database.new '/nix/var/nix/db/db.sqlite', readonly: true
end

def get_build_status(drvs)
  drv_list_str = drvs.map { |d| "\"#{d}\"" }.join(", ")
  query = <<END
select d.path, v.id
from ValidPaths d
left join DerivationOutputs o on d.id == o.drv
left join ValidPaths v on o.path == v.path
where d.path in (#{drv_list_str});
END
  r = {}
  nix_db.execute(query) do |drv, output_id|
    drv = drv.to_sym
    output_built = !output_id.nil?
    r[drv] = r.fetch(drv, true) && output_built
  end
  r
end

# Returns a map that maps every derivation path to a list of derivation paths
# that it refers to, for all derivations in the Nix store.
def get_drv_graph
  map = {}
  query = <<END
select r1.path, r2.path
from Refs r
join ValidPaths r1 on r1.id == referrer
join ValidPaths r2 on r2.id == reference
where r1.path like '%.drv' and r2.path like '%.drv';
END
  nix_db.execute(query) do |drv1, drv2|
    drv1 = drv1.to_sym
    drv2 = drv2.to_sym
    (map[drv1] ||= []) << drv2
    map[drv2] ||= []
  end
  map
end

def graph_restrict_nodes(graph, allowed_nodes)
  graph = restricted_transitive_closure(graph, Set.new(allowed_nodes))
  transitive_reduction(graph)
end

def graph_unmap(graph, map)
  rmap = {}
  map.each do |k, v|
    raise "Mapping is not one-to-one: multiple items map to #{v}" if rmap.key?(v)
    rmap[v] = k
  end
  gu = {}
  graph.each do |parent, children|
    gu[rmap.fetch(parent)] = children.map do |child|
      rmap.fetch(child)
    end
  end
  gu
end

def print_drv_stats(built_map)
  built_count = built_map.count { |drv, built| built }
  puts "Derivations built: #{built_count} out of #{built_map.size}"
end

def output_graphviz(path_state)
  path_graph = path_state.fetch(:graph)
  path_priority_map = path_state.fetch(:priority_map)
  path_time_map = path_state.fetch(:time_map)
  path_built_map = path_state.fetch(:built_map)

  # Breaks a path name into two parts: subgraph name, component name.
  # For example, for :"linux32.qt.examples", returns ["linux32", "qt.examples"].
  decompose = lambda do |path|
    r = path.to_s.split('.', 2)
    r.size == 2 ? r : [nil, path.to_s]
  end

  # Make one subgraph for each system (e.g. 'linux32', 'win32').  Decide which
  # paths to show in the graph, excluding omni.* paths because the make the
  # graphs really messy.
  subgraph_names = Set.new
  visible_paths = []
  path_graph.each_key do |path|
    subgraph, component = decompose.(path)
    next if subgraph == 'omni'
    subgraph_names << subgraph
    visible_paths << path
  end

  File.open('paths.gv', 'w') do |f|
    f.puts "digraph {"
    f.puts "node ["
    f.puts "colorscheme=\"accent3\""
    f.puts "]"
    subgraph_names.sort.each do |subgraph_name|
      # Output the subgraphs and the nodes in them.
      f.puts "subgraph \"cluster_#{subgraph_name}\" {"
      f.puts "label=\"#{subgraph_name}\";"
      path_graph.each do |path, deps|
        subgraph, component = decompose.(path)
        next if subgraph != subgraph_name
        more_attrs = ''

        # Show nodes that are built with a green background.
        if path_built_map.fetch(path)
          more_attrs << " style=filled fillcolor=\"1\""
        end

        # Draw high-priority nodes with a thick pen.
        if path_priority_map.fetch(path) > 0
          more_attrs << " penwidth=3"
        end

        # Draw slow nodes as a double octagon.
        if path_time_map.fetch(path) > 10
          more_attrs << " shape=doubleoctagon"
        end
        f.puts "\"#{path}\" [label=\"#{component}\"#{more_attrs}]"
      end
      f.puts "}"
    end

    # Output dependencies between nodes.
    visible_paths.each do |path|
      path_graph.fetch(path).each do |dep|
        next if decompose.(dep).first == 'omni'
        f.puts "\"#{path}\" -> \"#{dep}\""
      end
    end
    f.puts "}"
  end
end

def make_build_plan(path_state)
  path_graph = path_state.fetch(:graph)
  path_priority_map = path_state.fetch(:priority_map)
  path_time_map = path_state.fetch(:time_map)
  path_built_map = path_state.fetch(:built_map)

  # It's handy to be able to get all the dependencies of a node in one step, and
  # we will use that frequently to calculate how expensive it is to build a
  # node and to make the toplogical sort.
  path_graph = transitive_closure(path_graph).freeze

  # The paths we need to build.  In the future we could filter this by priority.
  required_paths = Set.new(path_graph.keys).freeze

  # built_paths: The set of paths that are already built.  We will mutate this
  # as we simulate our build plan.
  built_paths = Set.new
  path_built_map.each do |path, built|
    built_paths << path if built
  end

  # List of paths to build.  Each path should only be built once all the paths it
  # depends on are built.  I know nix-build can take care of that for us, but it's
  # nice to see the precise order of what is going to be built so we can tell when
  # slow things will get built.
  build_plan = []

  # Computes the time to build a path, taking into account what has already been
  # built.
  calculate_time = lambda do |path|
    deps = path_graph.fetch(path) + [path]
    deps.reject! &built_paths.method(:include?)
    deps.map(&path_time_map.method(:fetch)).sum
  end

  # Adds plans to build this path and all of its unbuilt depedencies.
  add_to_build_plan = lambda do |path|
    deps = path_graph.fetch(path) + [path]

    # Remove dependencies that are already built.
    deps.reject! &built_paths.method(:include?)

    # Topological sort
    deps.sort! do |p1, p2|
      case
      when path_graph.fetch(p1).include?(p2) then 1
      when path_graph.fetch(p2).include?(p1) then -1
      else 0
      end
    end

    deps.each do |path|
      build_plan << path
      built_paths << path
    end
  end

  while true
    unbuilt_required_paths = required_paths - built_paths
    break if unbuilt_required_paths.empty?

    # Find the maximum priority of the unbuilt required paths.
    max_priority = nil
    unbuilt_required_paths.each do |path|
      priority = path_priority_map.fetch(path)
      if !max_priority || priority > max_priority
        max_priority = priority
      end
    end

    top_priority_paths = unbuilt_required_paths.select do |path|
      path_priority_map.fetch(path) == max_priority
    end

    target = top_priority_paths.min_by(&calculate_time)

    add_to_build_plan.(target)
  end

  build_plan
end

def build_paths(path_graph, path_built_map, build_plan, keep_going: true)
  path_built_map = path_built_map.dup
  path_graph = transitive_closure(path_graph)
  build_plan.each do |path|
    if !path_graph.fetch(path).all?(&path_built_map.method(:fetch))
      # One of the dependencies of this path has not been built, presumably
      # because there was an error.
      puts "# skipping #{path}"
      next
    end

    print "nix-build -A #{path}"
    system("nix-build -A #{path} > /dev/null 2> /dev/null")

    if $?.success?
      path_built_map[path] = true
      puts
    else
      puts " # failed"
      return false if !keep_going
    end
  end
  true
end

begin
  check_directory!
  settings = parse_derivation_list('test/derivations.txt')
  path_drv_map = instantiate_drvs(settings.fetch(:paths))
  check_paths_are_unique!(path_drv_map)
  drvs = path_drv_map.values.uniq
  drv_built_map = get_build_status(drvs)
  global_drv_graph = get_drv_graph
  drv_graph = graph_restrict_nodes(global_drv_graph, drvs)
  path_state = {
    graph: graph_unmap(drv_graph, path_drv_map).freeze,
    priority_map: make_path_priority_map(settings).freeze,
    time_map: make_path_time_map(settings).freeze,
    built_map: map_compose(path_drv_map, drv_built_map).freeze,
  }.freeze
  output_graphviz(path_state)
  build_plan = make_build_plan(path_state)
  print_drv_stats(drv_built_map)
  success = build_paths(path_state[:graph], path_state[:built_map], build_plan)
  exit(1) if !success
rescue AnticipatedError => e
  $stderr.puts e
end
