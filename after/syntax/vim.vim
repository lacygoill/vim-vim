" Make Vim color the custom commands `:Pab` and `:Aab` as builtin Ex commands.
" How did you find the syntax for this line of code?{{{
"
"     :e /tmp/vim.vim
"     :put ='inorea'
"     /inorea
"     !s
"     vimAbb~
"
"     :e $VIMRUNTIME/syntax/vim.vim
"     /vimAbb
"}}}
syn keyword vimAbb Aab Pab skipwhite nextgroup=vimMapMod,vimMapLhs
" TODO: Comment how `skipwhite` and `nextgroup` work.
