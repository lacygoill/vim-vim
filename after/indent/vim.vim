vim9

# Don't re-indent a continuation line.{{{
#
# It's  annoying  when  you try  to  insert  a  backslash  in front  of  several
# consecutive lines, from visual-block mode.  It breaks the process.
#}}}
setl indk-=0\\
# Don't re-indent a continuation line comment.
exe 'setl indk-=0=\"\\\ '
# don't re-indent when inserting `}`
setl indk-==}
# Original value:{{{
#
#     0{,0},0),0],:,!^F,o,O,e,=end,=},=else,=cat,=fina,=END,0\,0="\
#
# ... set from $VIMRUNTIME/indent/vim.vim
#}}}

# When I exchange the position of 2 lines which are prefixed with a backslash,
# I don't want one of them to be re-indented.
g:vim_indent_cont = 0

# Teardown {{{1

b:undo_indent = get(b:, 'undo_indent', 'exe')
    .. '| set indk<'
