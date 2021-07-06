vim9script

# TODO: Check whether some refactoring commands could be turned into operators.{{{
#
# ---
#
# Make sure that:
#
#    - all operators can be invoked via an Ex command
#    - the latter supports a bang
#    - without a bang, the refactored text is highlighted, and the command asks for your confirmation
#}}}

# Commands {{{1
# RefBar {{{2

command -bang -bar -buffer -nargs=? -complete=custom,vim#refactor#bar#complete
    \ RefBar vim#refactor#bar#main(<bang>0, <q-args>)

# RefDot {{{2

# Refactor dot concatenation operator:{{{
#
#     a . b   →  a..b
#     a.b     →  a..b
#     a .. b  →  a..b
#}}}
command -bang -bar -buffer -range=% RefDot vim#refactor#dot#main(<bang>0, <line1>, <line2>)

# RefHeredoc {{{2

command -bang -bar -buffer -nargs=* -complete=custom,vim#refactor#heredoc#complete
    \ RefHeredoc vim#refactor#heredoc#main(<bang>0, <q-args>)

# RefLambda {{{2

command -bang -bar -buffer RefLambda vim#refactor#lambda#main(<bang>0)

# RefMethod {{{2

command -bang -bar -buffer RefMethod vim#refactor#method#main(<bang>0)

# RefQuote {{{2

command -bar -buffer -range=% RefQuote :<line1>,<line2> substitute/"\(.\{-}\)"/'\1'/gce

# RefSubstitute {{{2

command -bang -bar -buffer RefSubstitute vim#refactor#substitute#main#main(<bang>0)

# RefTernary {{{2
# Usage  {{{3

# Select an `if / else(if) / endif` block, and execute `:RefTernary`.
# It will perform this conversion:

#         if var == 1                 let val = var == 1
#             let val = 'foo'               \ ?     'foo'
#         elseif var == 2                   \ : var == 2
#             let val = 'bar'    →          \ ?     'bar'
#         else                              \ :     'baz'
#             let val = 'baz'
#         endif
#
# Or this one:
#
#     if s:has_flag_p(a:flags, 'u')
#         return a:mode .. 'unmap'
#     else
#         return a:mode .. (s:has_flag_p(a:flags, 'r') ? 'map' : 'noremap')
#     endif
#
#         →
#
#     return s:has_flag_p(a:flags, 'u')
#         \ ?     a:mode .. 'unmap'
#         \ :     a:mode .. (s:has_flag_p(a:flags, 'r') ? 'map' : 'noremap')

# Code  {{{3

command -bar -buffer -range RefTernary vim#refactor#ternary#main(<line1>, <line2>)
#}}}2
#}}}1
# Mappings {{{1

nnoremap <buffer><nowait> <C-]> <Cmd>call vim#jumpToTag()<CR>
nnoremap <buffer><nowait> -h <Cmd>call vim#getHelpurl()<CR>

if expand('%:p') =~ '/syntax/\f\+\.vim$'
    nnoremap <buffer><nowait> gd <Cmd>call vim#jumpToSyntaxDefinition()<CR>
endif

map <buffer><nowait> ]m <Plug>(next-function-start)
map <buffer><nowait> [m <Plug>(prev-function-start)
noremap <buffer><expr> <Plug>(next-function-start) brackets#move#regex('def')
noremap <buffer><expr> <Plug>(prev-function-start) brackets#move#regex('def', v:false)

map <buffer><nowait> ]M <Plug>(next-function-end)
map <buffer><nowait> [M <Plug>(prev-function-end)
noremap <buffer><expr> <Plug>(next-function-end) brackets#move#regex('enddef')
noremap <buffer><expr> <Plug>(prev-function-end) brackets#move#regex('enddef', v:false)

silent! submode#enter('functions-start', 'nx', 'br', ']m', '<Plug>(next-function-start)')
silent! submode#enter('functions-start', 'nx', 'br', '[m', '<Plug>(prev-function-start)')
silent! submode#enter('functions-end', 'nx', 'br', ']M', '<Plug>(next-function-end)')
silent! submode#enter('functions-end', 'nx', 'br', '[M', '<Plug>(prev-function-end)')

# TODO: When should we install visual mappings?

nnoremap <buffer><expr><nowait> =rb vim#refactor#bar#main()

# TODO: should we turn those into operators (same thing for `=rq` and maybe `=rt`)?
nnoremap <buffer><nowait> =rd <Cmd>RefDot<CR>
xnoremap <buffer><nowait> =rd <C-\><C-N><Cmd>:* RefDot<CR>

nnoremap <buffer><expr><nowait> =rh vim#refactor#heredoc#main()
nnoremap <buffer><expr><nowait> =rl vim#refactor#lambda#main()
# TODO: Merge `=rL` with `=rl`.{{{
#
# When pressing `=rl` on an eval string, it should be refactored into a legacy lambda.
# When pressing `=rl` on a legacy lambda, it should be refactored into a Vim9 lambda.
#
# You'll need to merge `#new()` with `#main()`.
#}}}
nnoremap <buffer><expr><nowait> =rL vim#refactor#lambda#new()
nnoremap <buffer><expr><nowait> =rm vim#refactor#method#call#main()
nnoremap <buffer><expr><nowait> =r- vim#refactor#method#splitjoin#main()

nnoremap <buffer><nowait> =rq <Cmd>RefQuote<CR>
xnoremap <buffer><nowait> =rq <C-\><C-N><Cmd>:* RefQuote<CR>

nnoremap <buffer><expr><nowait> =rs vim#refactor#substitute#main()

xnoremap <buffer><nowait> =rt <C-\><C-N><Cmd>:* RefTernary<CR>

# Options {{{1
# commentstring {{{2

if getline(1) =~ '^vim9s\%[cript]\>'
    &l:commentstring = '# %s'
    &l:comments = 'sO:# -,mO:#  ,eO:##,:#'
endif

# formatlistpat {{{2

&l:formatlistpat = '^\s*#\=\s*\%(\d\+[.)]\|[-*+]\)\s\+'
#                                ├──────┘  ├───┘
#                                │         └ recognize unordered lists
#                                └ recognize numbered lists
# }}}1
# Variables {{{1

b:mc_chain =<< trim END
    file
    keyn
    omni
    tags
    ulti
    abbr
    C-n
    dict
END

# Teardown {{{1

b:undo_ftplugin = get(b:, 'undo_ftplugin', 'execute')
    .. '| call vim#undoFtplugin()'

