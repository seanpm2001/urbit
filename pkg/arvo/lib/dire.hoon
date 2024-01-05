!:
|%
+$  plat
  $@  @                                       ::  measure atom
  $^  $%  [[%c ~] (pair (pair step step) @)]  ::  cut slice
          [[%m ~] (pair (pair step step) @)]  ::  measure slice
          [[%s ~] p=plot]                     ::  subslice
      ==                                      ::
  (pair step @)                               ::  prefix
+$  plot  $^  [l=plot r=plot]                 ::  concatenate
          [a=bloq b=(list plat)]              ::  serialize
--
::
|%
::  atom ops
::
+|  %atomics
::
::  +rig: convert between bloqs
::
++  rig
  |=  [[a=bloq b=bloq] c=step]
  ^-  step
  ?:  =(a b)  c
  ?:  (gth a b)
    (lsh [0 (sub a b)] c)
  =/  d  [0 (sub b a)]
  =/  e  (rsh d c)
  ?:(=(0 (end d c)) e +(e))
::
::  +fax: encode a plot
::
++  fax
  :: ~/  %fax
  |=  p=plot
  ^-  (pair step @)
  =<  +
  |-  ^-  (trel bloq step @)
  ?^  -.p
    =/  l  $(p l.p)
    =/  r  $(p r.p)
    =/  s  (rig [p.l p.r] q.l)
    [p.r (add q.r s) (add r.l (lsh [p.r s] r.r))]
  ::
  ?~  b.p  [a.p 0 0]
  =;  c=(pair step @)
    =/  d  ^$(b.p t.b.p)
    [a.p (add p.c p.d) (add q.c (lsh [a.p p.c] q.d))]
  ::
  ?@  i.b.p
    [(met a.p i.b.p) i.b.p]
  ?-  -.i.b.p
    @       [p.i.b.p (end [a.p p.i.b.p] q.i.b.p)]
    [%c ~]  [q.p.i.b.p (cut a.p [p q]:i.b.p)]
    [%m ~]  =+((cut a.p [p q]:i.b.p) [(met a.p -) -])
    [%s ~]  =/  e  $(p p.i.b.p)
            [(rig [p.e a.p] q.e) r.e]
  ==
::
::  +nac: reverse +can
::
++  nac
  |=  [a=bloq b=(list (pair step step)) c=@]
  ^-  (list @)
  ?~  b  ~
  [(cut a [i.b] c) $(b t.b)]
::
::  +dew: dry +hew
::
++  dew
  |=  [a=bite b=* c=@]
  ^-  *
  =<  -
  =/  [d=bloq e=step]  ?^(a a [a 0])
  |-  ^-  (pair * step)
  ?@  b
    [(cut d [e b] c) (add e b)]
  =^  f  e  $(b -.b)
  =^  g  e  $(b +.b)
  [[f g] e]
::
::  +hew: cut many
::
++  hew
  |=  [a=bite c=@]
  =/  d=[=bloq =step]  ?^(a a [a 0])
  |*  b=*
  ^+  [b d]
  ?@  b
    [(cut bloq.d [step.d b] c) bloq.d (add step.d b)]
  =^  f  d  $(b -.b)
  =^  g  d  $(b +.b)
  [[f g] d]
::
++  clz
  |=  [a=bite b=@]
  (sub ?@(a (bex a) (mul (bex bloq.a) step.a)) (met 0 b))
::
++  ctz
  |=  a=@
  ?:  =(0 a)  0
  =|  i=@ud
  |-(?:(=(1 (cut 0 [i 1] a)) i $(i +(i))))
::
++  ham  :: popcount
  |=  a=@
  ?:  =(0 a)  0
  =|  n=@ud
  =/  m  (dec (met 0 a))
  |-  ^-  @ud
  =?  n  =(1 (cut 0 [m 1] a))
    +(n)
  ?:(=(0 m) n $(m (dec m)))
::
::  binary tree ops
::
+|  %arboric
::
++  bao
  |=  n=@ud
  =|  i=@ud
  =|  s=(list)
  |-  ^-  *
  ?:  =(i n)
    =^  d  s  s
    |-(?~(s d $(d [i.s d], s t.s)))
  ::
  =/  d=*  i
  =.  i  +(i)
  =/  j  (ctz i)
  |-  ^-  *
  ?:  =(0 j)
    ^$(s [d s])
  =^  e  s  s
  $(d [e d], j (dec j))
::
++  unroll
  |=  d=*
  =|  s=(list [axe=@ d=*])
  =/  a  1
  |-  ^+  s
  ?@  d
    ?~  s  ~
    $(d d.i.s, a axe.i.s, s t.s)
  :-  [a d]
  $(d -.d, a (peg a 2), s [[(peg a 3) +.d] s])
::
::  packet de/serialization
::
+|  %packets
::
::    > :(add 8 336 1.128)
::    1.472
::
++  pact
  =>  |%
      +$  name  [p=ship q=rift r=path s=bloq t=num=@udF]
      +$  data  [tot=@udF aut=@ux dat=@]
      +$  lane  $@  @ux
                $%  [%if p=@ifF q=@udE]
                    [%is p=@isH q=@udE]
                ==
      +$  next  (list lane)
      +$  pact  $%  [%page p=name q=data r=next]
                    [%peek p=name]
                    [%poke p=name q=name r=data]
                ==
      --
  ::
  |%
  ++  en
    |=  pak=pact
    ^-  plot
    =/  bod=plot
      ?-  -.pak
        %page  [(en:^name p.pak) (en:^data q.pak) (en:^next r.pak)]
        %peek  (en:^name p.pak)
        %poke  [(en:^name p.pak) (en:^name q.pak) (en:^data r.pak)]
      ==
    =/  hed=plot
      =/  nex=@B
        ?.  ?=(%page -.pak)  0b0
        ?~  r.pak            0b0
        ?^  t.r.pak          0b11
        ?:(?=([%if *] i.r.pak) 0b1 0b10)
      =/  hop  0 :: XX
      (en:head nex -.pak hop (mug q:(fax bod)))
    [hed bod]
  ::
  ++  de
    |=  a=bite
    |=  dat=@
    ^-  [pact bloq step]
    =+  ^=  [hed b]  ((de:head a) dat)
    =+  ^=  [pac c]
      ?-  typ.hed
        %page  =^  nam  b  ((de:^name b) dat)
               =^  dat  b  ((de:^data b) dat)
               =^  nex  b  ((de:^next b nex.hed) ^dat)
               [[typ.hed nam dat nex] b]
      ::
        %peek  =^  nam  b  ((de:^name b) dat)
              [[typ.hed nam] b]
      ::
        %poke  =^  nam  b  ((de:^name b) dat)
               =^  dam  b  ((de:^name b) dat)
               =^  dat  b  ((de:^data b) dat)
               [[typ.hed nam dam dat] b]
      ==
    =/  gum
      (end [0 20] (mug (cut -.c [(rig [-.b -.c] +.b) +.c] dat)))
    ?>(=(gum.hed gum) [pac c])
  --
::
++  head
  |%
  ++  en
    |=  [nex=@B typ=?(%page %peek %poke) hop=@ gum=@F]
    ^-  plot
    =/  tip  ?-(typ %page 0b1, %peek 0b10, %poke 0b11)
    =.  hop  (min 7 hop)
    =*  tok  [32 ~tasfyn-partyv]
    :-  bloq=0
    [[2 0] [2 nex] [3 ver=1] [2 tip] [3 hop] [20 gum] tok ~]
  ::
  ++  de
    |=  a=bite
    =/  b=[bloq step]  [0 ?@(a 0 (rig [bloq.a 0] step.a))]
    |=  dat=@
    ^-  [[nex=@B typ=?(%page %peek %poke) hop=@ gum=@F] bloq step]
    =+  [[res nex ver tip hop gum tok] b]=((hew b dat) [2 2 3 2 3 20 32])
    ?>  =(0 res)
    ?>  =(1 ver)
    ?>  =(~tasfyn-partyv tok)
    =/  typ  ?+(tip !! %0b1 %page, %0b10 %peek, %0b11 %poke)
    [[nex typ hop gum] b]
  --
::
++  next
  |%
  ++  en
    |=  nex=next:pact
    ^-  plot
    :-  bloq=3
    ?~  nex  ~
    ?:  ?=([[%if *] ~] nex)
      [[4 p] [2 q] ~]:i.nex
    |-  ^-  (list plat)
    =;  one=(list plat)
      ?~(t.nex one (weld one $(nex t.nex)))
    ?-  i.nex
      @        =/  l  (met 3 i.nex)
               ?>  (lth l 255)
               [[1 +(l)] [1 2] [l i.nex] ~]
      [%if *]  [[1 7] [1 0] [4 p] [2 q] ~]:i.nex
      [%is *]  =/  l  (met 3 p.i.nex)
               ?>  (lth l 253)
               [[1 (add 3 l)] [1 1] [l p.i.nex] [2 q.i.nex] ~]
    ==
  ::
  ++  de
    |=  [a=bite b=@B]
    =/  c=[bloq step]  [3 ?@(a 0 (rig [bloq.a 3] step.a))]
    |=  dat=@
    ^-  [next:pact bloq step]
    =<  ?+  b  !!
          %0b0   [~ c]
        ::
          %0b1   =^  if=[@ @]  c  ((hew c dat) 4 2)
                 [[if+if ~] c]
        ::
          %0b10  =^  la  c  (need one)
                 [[la ~] c]
        ::
          %0b11  =|  nex=next:pact
                 |-  ^-  [next:pact bloq step]
                 =/  a  one
                 ?~  a  [(flop nex) c]
                 $(nex [-.u.a nex], c +.u.a)
        ==
    |%
    ++  one
      ^-  (unit [lane:pact bloq step])
      =^  raw  c  ((hew c dat) 1 1)
      ?:  =(0 -.raw)  ~
      ?+  +.raw  !!
        %0  ?>  =(7 -.raw)
            =^  if=[@ @]  c  ((hew c dat) 4 2)
            `[if+if c]
      ::
        %1  ?>  (gte -.raw 3)
            =^  is=[@ @]  c  ((hew c dat) (sub -.raw 3) 2)
            `[is+is c]
      ::
        %2  =^  la  c  ((hew c dat) (dec -.raw))
            `[la c]
      ==
    --
  --
::
::  +name: encoded-path
::
::  range:  { meta[1], her[2^1-4], rif[1-4], typ[2^0-1], pat[2^0-16], boq[0-1], fag[1-4] }
::  max:    { meta[1], her[16],    rif[4],   typ[2],     pat[65.536], boq[1],   fag[4]   }
::          { meta-byte, address,  rift,    path-length, path,       bloq-size, fragment-number }
::  actual: { meta[1], her[16],    rif[4],   typ[2],     pat[309],    boq[1],   fag[4]   }
::
::    > :(add 1 16 4 2 309 4)
::    336
::
++  name
  |%
  ++  en
    |=  [her=@pH rif=@udF pat=path boq=@D num=@udF]
    ^-  plot
    =/  ran  ?~(her 0 (dec (met 0 (met 4 (end 7 her)))))
    =/  ryf  ?~(rif 0 (dec (met 3 rif)))  :: XX is rift always non-zero?
    =/  tap  =-([p=(met 3 -) q=-] `@t`(rap 3 (join '/' pat)))
    ?>  (lth p.tap ^~((bex 16)))
    =/  typ  (dec (met 3 p.tap))
    =/  loq  ?:(=(13 boq) 0 1)
    =/  fag  =-([p=(met 3 -) q=-] (end 5 num))
    :+  bloq=3
      [s+~ 0 [2 ran] [2 ryf] [1 typ] [1 loq] [2 (dec p.fag)] ~]
    [[(bex +(ran)) her] [+(ryf) rif] [+(typ) p.tap] tap [loq (end 3 boq)] fag ~]
  ::
  ++  de
    |=  a=bite
    =/  b=[bloq step]  [0 ?@(a 0 (rig [bloq.a 0] step.a))]
    |=  pat=@
    ^-  [[her=@p rif=@udF pat=path boq=bloq num=@udF] bloq step]
    =+  [[ran ryf typ loq fag] b]=((hew b pat) [2 2 1 1 2])
    =+  [len nex]=[(rig [bloq.b 3] step.b) (bex +(ran))]
    =/  her  (cut 3 [len nex] pat)
    =:  len  (add len nex)
        nex  +(ryf)
      ==
    =/  rif  (cut 3 [len nex] pat)
    =:  len  (add len nex)
        nex  +(typ)
      ==
    =/  tap  (cut 3 [len nex] pat)
    =:  len  (add len nex)
        nex  tap
      ==
    =/  tap
      %+  rash  (cut 3 [len nex] pat)
      (more fas (cook crip (star ;~(less fas prn))))
    =:  len  (add len nex)
        nex  loq
      ==
    =/  boq  ?~(loq 13 (cut 3 [len nex] pat))
    =:  len  (add len nex)
        nex  +(fag)
      ==
    [[her rif tap boq (cut 3 [len nex] pat)] 3 (add len nex)]
  --
::
::  +data: response data
::
::  range:  { meta[1], tot[1-4], lut[0-1], aut[0-255], len[0-32], dat[0-2^252-1] }
::  max:    { meta[1], tot[4],   lut[1],   aut[255],   len[32],   dat[2^252-1]   }
::  actual: { meta[1], tot[4],   lut[1],   aut[96],    len[2],    dat[0-2^10-1]  }
::
::    > :(add 1 4 1 96 2 1.024)
::    1.128
::
++  data
  |%
  ++  en
    |=  [tot=@udF aut=@ux dat=@]
    ^-  plot
    =/  mot  (met 3 (end 5 tot))
    =/  mut  ?:(=(0 aut) 0 1)
    =/  lut  (end 3 (met 3 aut))
    =/  len  (met 3 dat)
    =/  men  (met 3 len)
    :+  bloq=3
      [s+~ 0 [2 (dec mot)] [1 mut] [5 men] ~]
    [[mot tot] [mut lut] [lut aut] [men len] [len dat] ~]
  ::
  ++  de
    |=  a=bite
    =/  b=[bloq step]  [0 ?@(a 0 (rig [bloq.a 0] step.a))]
    |=  dat=@
    ^-  [[tot=@udF aut=@ux dat=@] bloq step]
    =+  ^=  [[bot mut men] b]  ((hew b dat) [2 1 5])
    =+  ^=  [len nex]          [(rig [bloq.b 3] step.b) +(bot)]
    =/  tot  (cut 3 [len nex] dat)
    =:  len  (add len nex)
        nex  mut
      ==
    =/  lut  (cut 3 [len nex] dat)
    =:  len  (add len nex)
        nex  lut
      ==
    =/  aut  (cut 3 [len nex] dat)
    =:  len  (add len nex)
        nex  men
      ==
    =/  lat  (cut 3 [len nex] dat)
    =:  len  (add len nex)
        nex  lat
      ==
    [[tot aut (cut 3 [len nex] dat)] 3 (add len nex)]
  --
--
