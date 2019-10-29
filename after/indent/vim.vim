" Purpose:{{{
"
" I don't want a line to be  automatically re-indented when I insert a backslash
" at the beginning of a line.  It's  annoying when you try to insert a backslash
" in front of  several consecutive lines, from visual-block  mode. It breaks the
" process.
"}}}
setl indk-=0\\
" Original value:{{{
"
"         setl=0{,0},:,0#,!^F,o,O,e,=end,=else,=cat,=fina,=END,0\\
"
" … set from $VIMRUNTIME/indent/vim.vim
"}}}

" When I exchange the position of 2 lines which are prefixed with a backslash,
" I don't want one of them to be reindented.
let g:vim_indent_cont = 0

" Teardown {{{1

let b:undo_indent = get(b:, 'undo_indent', 'exe')
    \ ..'| setl indk<'
