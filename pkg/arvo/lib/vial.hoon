=>  %1  =>
~%  %v.1  ~  ~
|%
++  vial-version  +
++  via
  ~/  %via
  |=  v=@  ^-  @  +(v)
--  =>
~%  %one  +  ~
|%
++  fat
  ~/  %fat
  |=  [a=* b=*]  42
++  inc
  ~/  %inc
  |=  a=@  ^-  @  +(a)
--
~%  %two  +  ~
|%
++  foo
  ~%  %foo  +  ~
  |_  f=@
    ++  baz
    ~/  %baz
    |=  z=@  ^-  ^  [+(f) +(z)]
  --
++  bar
  ~/  %bar
  |=  d=@  ^-  @  +(d)
--

:: [l=/v.1 s=[& %v.1]]
:: [l=/via/v.1 s=[[& &] [<via battery> %v.1]]
:: [l=/one/v.1 s=[[& &] [<one battery> %v.1]]
:: [l=/fat/one/v.1 s=[[& | & &] <fat battery> ~ <one battery> %v.1]
:: [l=/inc/one/v.1 s=[[& | & &] <inc battery> ~ <one battery> %v.1]
:: [l=/two/one/v.1 s=[[& | & &] [<two battery> ~ <one battery> %v.1]]
:: [l=/foo/two/one/v.1 s=[[& | & | &] <foo battery> ~ <two battery> ~ <one battery> %v.1]
:: [l=/bar/two/one/v.1 s=[[& | & | &] <foo battery> ~ <two battery> ~ <one battery> %v.1]
