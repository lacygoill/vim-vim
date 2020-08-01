" Make Vim highlight custom commands like `:Plug` similar to builtin Ex commands.{{{
"
" With a  twist: we  want them  to be italicized,  so that  we can't  conflate a
" custom command with a builtin one.
"
" If you don't care about this distinction, you could get away with just:
"
"     hi link vimUsrCmd vimCommand
"}}}
call lg#syntax#derive('vimUsrCmd', 'vimCommand', 'term=italic cterm=italic gui=italic')

" The default `vimUsrCmd` highlights too much.{{{
"
"     $VIMRUNTIME/syntax/vim.vim
"     /vimUsrCmd
"
"     syn match vimUsrCmd       '^\s*\zs\u\w*.*$'
"                                            ^^
"                                            ✘
"
" https://github.com/vim/vim/issues/6587
"}}}
syn clear vimUsrCmd
syn match vimUsrCmd '^\s*\zs\u\%(\w*\)\@>(\@!'
"                                     ^-----^
"                                     don't highlight a custom Vim function
"                                     invoked without ":call" in a Vim9 script

" `:h line-continuation-comment` is not highlighted inside a dictionary
call vim#syntax#override_vimOperGroup()
" TODO: Remove this functions call once this issue is fixed:
" https://github.com/vim/vim/issues/6592

