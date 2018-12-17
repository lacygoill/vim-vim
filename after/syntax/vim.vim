" Make Vim color the custom commands `:Pab` and `:Aab` as builtin Ex commands.
" How did you find the syntax for this line of code?{{{
"
"     :e /tmp/vim.vim
"     :put ='inorea'
"     /inorea
"     !s
"         → vimAbb
"
"     :e $VIMRUNTIME/syntax/vim.vim
"     /vimAbb
"}}}
syn keyword vimAbb Aab Pab skipwhite nextgroup=vimMapMod,vimMapLhs

" TODO: Comment how `skipwhite` and `nextgroup` work.{{{
"
" Read `:h syn-nextgroup`.
" Test this code:
"
"     syn clear

"     syn match  xFoobar  'Foo.\{-}Bar'  contains=xFoo
"     syn match  xFoo     'Foo'	     contained nextgroup=xFiller
"     syn region xFiller  start='.'  matchgroup=xBar  end='Bar'  contained

"     hi link xFoobar  DiffAdd
"     hi link xFoo     DiffChange
"     hi link xFiller  DiffDelete
"     hi link xBar     DiffText

"     " ( one ( two ( three ( four ) five ) six ) seven )

"     " syn region par1 matchgroup=par1 start='(' end=')' contains=par2
"     " syn region par2 matchgroup=par2 start='(' end=')' contains=par3 contained
"     " syn region par3 matchgroup=par3 start='(' end=')' contains=par1 contained
"     " hi par1 ctermfg=red guifg=red
"     " hi par2 ctermfg=blue guifg=blue
"     " hi par3 ctermfg=darkgreen guifg=darkgreen

" On this text:
"
"     Foo hello Bar xxxx Foo world Bar xxxx
"}}}
