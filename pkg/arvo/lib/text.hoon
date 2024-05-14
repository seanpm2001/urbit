  ::  /lib/text
::::
::  Some common text conversion routines targeted towards beginners.
::  See also https://docs.urbit.org/language/hoon/reference/zuse/2d_7,
::  which require head tags on JSON-style values.
::
|%
::  Conversions from atom to text.
++  from-da      (cury scot %da)
++  from-dr      (cury scot %dr)
++  from-p       (cury scot %p)
++  from-rd      (cury scot %rd)
++  from-rh      (cury scot %rh)
++  from-rq      (cury scot %rq)
++  from-rs      (cury scot %rs)
++  from-ub      (cury scot %ub)
++  from-ud      (cury scot %ud)
++  from-ux      (cury scot %ux)
++  from-path    (cork spud crip)
++  from-number  :(cork rlyd r-co:co crip)
++  from-int     (cork (d-co:co 1) crip)
::  Conversions from text to atom.
++  to-da      (cury slav %da)
++  to-dr      (cury slav %dr)
++  to-p       (cury slav %p)
++  to-bin     (cury slav %ub)
++  to-int     (cury slav %ud)
++  to-hex     (cury slav %ux)
++  to-double  (cury slav %rd)
++  to-half    (cury slav %rh)
++  to-quad    (cury slav %rq)
++  to-float   (cury slav %rs)
++  to-path    stab
++  to-number  |=(=cord (need (ne:dejs-soft:format [%n cord])))
++  to-int     |=(=cord (need (ni:dejs-soft:format [%n cord])))
::  Aliases
++  from-tape  crip
++  to-tape    trip
--
