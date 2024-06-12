::  test %peek for %naxplanation
::
/+  *test, v=test-mesa-gall
=+  [nec-life=2 bud-life=3]
=+  (nec-bud:v [nec-life bud-life] nec=0 bud=0)
|%
++  dbug  `?`&
++  make-roof
  |=  [pax=path val=cage]
  ^-  roof
  |=  [lyc=gang pov=path vis=view bem=beam]
  ^-  (unit (unit cage))
  ?.  &(=(s.bem pax) |(=(vis %x) =(vis [%$ %x]) =(vis [%g %x])))  [~ ~]
  ``val
::
++  nec-scry-roof
  scry:(mesa.nec now=~1111.1.1 eny=`@`0xdead.beef *roof)
::
++  bud-scry-roof
  scry:(mesa.bud now=~1111.1.1 eny=`@`0xdead.beef *roof)
::
++  test-watch
  %-  run-chain
  |.  :-  %|
  ::
  =/  poke-plea  [%x /ge/pok [%0 %m noun/0]]
  =/  poke-path  //x/1//flow/0/~nec/poke/~bud/for/1
  =/  ack-path   //x/1//flow/0/~bud/ack/~nec/bak/1
  =/  nax-path   //x/1//flow/0/~bud/nax/~nec/bak/1
  ::
  =/  ack-wire   /flow/int/for/~bud/0/0/1
  =/  vane-wire  /flow/out/bak/~nec/0/0/1
  =/  nax-wire   /flow/ext/for/~bud/0/0/1
  ::
  =/  make-poke=[%make-poke space:mesa spar:ames path]
    [%make-poke %publ^life=bud-life [~bud ack-path] poke-path]
  =/  plea-roof  (make-roof poke-path message+!>(plea/poke-plea))
  ::  preamble
  ::
  =^  *  mesa.nec
    (mesa-call:v mesa.nec [~[/poke] [%plea ~bud poke-plea] plea-roof])
  ::
  =^  *  mesa.nec
    (mesa-call:v mesa.nec ~[ack-wire /poke] make-poke plea-roof)
  ::
  =/  message=mess:mesa
    [%poke [~bud ack-path] [~nec poke-path] auth=&+*@uxJ page=message/poke-plea]
  ::
  ~?  >  dbug  'place %naxplanation payload in namespace'
  =^  *  mesa.bud
    %:  mesa-call-with-dude:v  mesa.bud
      :^    *goof
          ~[//unix]
        [%mess lane=`*@ux message]
      plea-roof
    ==
  ::
  =/  full-nax-path  (weld /mess/0//publ/[(scot %ud nec-life)]//x/1/[%$] nax-path)
  =/  make-peek  [%make-peek %publ^life=bud-life ~bud nax-path]
  ~?  >  dbug  '~nec hears %nack, produces %make-peek request'
  =^  error-moves  mesa.nec
    %:    mesa-check-take:v  mesa.nec  [now=~1111.1.1 eny=`@`0xdead.beef plea-roof]
      :+  ack-wire  ~[/poke]
      [%mesa %response %page ~bud^ack-path &+0x0 `page`message/[%ack error=&]]
    ::
      :~  :-  ~[/poke]
          [%pass nax-wire %m make-peek]
      ==
    ==
  ::
  :-  error-moves  |.  :-  %|
  ::  start
  ::
  ~?  >  dbug  'naxplanation payload is accesible at /flow/0/~bud/nax/~nec/bak/1'
  =/  moves-1
    %+  expect-eq
    !>  nax/*goof
    !>  !<  page
        =<  ?>  ?=(%message p)  q
        (mesa-scry-payload:v mesa.bud ~bud nax-path)
  ::
  :-  moves-1  |.  :-  %|
  ~?  >  dbug  '~nec starts %peeking for the naxplanation on ~bud'
  ::
  =/  naxplanation=*  *error:mesa
  =/  nax-roof        (make-roof nax-path message+!>(naxplanation))
  ::
  =^  moves-x  mesa.nec
    (mesa-call:v mesa.nec [~[nax-wire /poke] make-peek nax-roof])
  ~?  >  dbug  '~bud gives ~nec the first fragment'
  =^  moves-y  mesa.bud     (mesa-reply:v mesa.bud ~[/unix-pact] moves-x nax-roof)
  ~?  >  dbug  '~nec hears complete message'
  =^  moves-page  mesa.nec  (mesa-reply:v mesa.nec ~[/unix-pact] moves-y nax-roof)
  ::
  :-  (mesa-expect-msg:v moves-page nax/naxplanation)  |.  :-  %|
  ~?  >  dbug  '~nec takes %naxplanation from ~bud, given by the packet layer'
  =^  moves-3  mesa.nec
    %:    mesa-check-take:v  mesa.nec
        [~1111.1.1 0xdead.beef *roof]
      ?>  ?=([[^ [%give %response *]] *] moves-page)
      [wire=i.duct duct=t.duct %mesa gift.card]:i.moves-page
    ::
      :~  :-  ~[/poke]
          [%give %done `*error:mesa]
      ==
    ==
  :-  moves-3  |.  :-  %&
    %+  expect-eq
    !>  0
    !>  =<  next-bone.ossuary
        %:  mesa-scry-peer:v
          mesa.bud
          [~1111.1.10 0xdead.beef *roof]
          [~bud ~nec]
        ==
--
