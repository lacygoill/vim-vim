vim9

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
# Refactor {{{2

com -bang -bar -buffer -range=% Refactor vim#refactor#general#main(<line1>, <line2>, <bang>0)

# RefBar {{{2

com -bang -bar -buffer -nargs=? -complete=custom,vim#refactor#bar#complete
    \ RefBar vim#refactor#bar#main(<bang>0, <q-args>)

# RefDot {{{2

# Refactor dot concatenation operator:{{{
#
#     a . b   →  a..b
#     a.b     →  a..b
#     a .. b  →  a..b
#}}}
com -bang -bar -buffer -range=% RefDot vim#refactor#dot#main(<bang>0, <line1>, <line2>)

# RefHeredoc {{{2

com -bang -bar -buffer -nargs=* -complete=custom,vim#refactor#heredoc#complete
    \ RefHeredoc vim#refactor#heredoc#main(<bang>0, <q-args>)

# RefLambda {{{2

com -bang -bar -buffer RefLambda vim#refactor#lambda#main(<bang>0)

# RefMethod {{{2

com -bang -bar -buffer RefMethod vim#refactor#method#main(<bang>0)

# RefQuote {{{2

com -bar -buffer -range=% RefQuote <line1>,<line2>s/"\(.\{-}\)"/'\1'/gce

# RefSubstitute {{{2

com -bang -bar -buffer RefSubstitute vim#refactor#substitute#main#main(<bang>0)

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

com -bar -buffer -range RefTernary vim#refactor#ternary#main(<line1>, <line2>)
#}}}2
# RefVim9 {{{2

com -bar -buffer -range=% RefVim9 vim#refactor#vim9#main(<line1>, <line2>)
#}}}1
# Mappings {{{1

nno <buffer><nowait> <c-]> <cmd>call vim#jumpToTag()<cr>
nno <buffer><nowait> -h <cmd>call vim#getHelpurl()<cr>

noremap <buffer><expr><nowait> [m brackets#move#regex('fu', v:false)
noremap <buffer><expr><nowait> ]m brackets#move#regex('fu', v:true)

noremap <buffer><expr><nowait> [M brackets#move#regex('endfu', v:false)
noremap <buffer><expr><nowait> ]M brackets#move#regex('endfu', v:true)

sil! repmap#make#repeatable({
    mode: '',
    buffer: true,
    from: expand('<sfile>:p') .. ':' .. expand('<slnum>'),
    motions: [
        {bwd: '[m', fwd: ']m'},
        {bwd: '[M', fwd: ']M'},
        ]})

# TODO: When should we install visual mappings?

nno <buffer><expr><nowait> =rb vim#refactor#bar#main()

# TODO: should we turn those into operators (same thing for `=rq` and maybe `=rt`)?
nno <buffer><nowait> =rd <cmd>RefDot<cr>
xno <buffer><nowait> =rd <c-\><c-n><cmd>*RefDot<cr>

nno <buffer><expr><nowait> =rh vim#refactor#heredoc#main()
nno <buffer><expr><nowait> =rl vim#refactor#lambda#main()
# TODO: Merge `=rL` with `=rl`.{{{
#
# When pressing `=rl` on an eval string, it should be refactored into a legacy lambda.
# When pressing `=rl` on a legacy lambda, it should be refactored into a Vim9 lambda.
#
# You'll need to merge `#new()` with `#main()`.
#}}}
nno <buffer><expr><nowait> =rL vim#refactor#lambda#new()
nno <buffer><expr><nowait> =rm vim#refactor#method#call#main()
nno <buffer><expr><nowait> =r- vim#refactor#method#splitjoin#main()

nno <buffer><nowait> =rq <cmd>RefQuote<cr>
xno <buffer><nowait> =rq <c-\><c-n><cmd>*RefQuote<cr>

nno <buffer><expr><nowait> =rs vim#refactor#substitute#main()

xno <buffer><nowait> =rt <c-\><c-n><cmd>*RefTernary<cr>

# Options {{{1
# cms {{{2

if getline(1) =~ '^vim9\%[script]\>'
    setl cms=#%s
    &l:com = 'sO:# -,mO:#  ,eO:##,:#'
endif

# flp {{{2

&l:flp = '^\s*"\=\s*\%(\d\+[.)]\|[-*+]\)\s\+'
#                      ├──────┘  ├───┘
#                      │         └ recognize unordered lists
#                      └ recognize numbered lists
# }}}1
# Variables {{{1

b:mc_chain =<< trim END
    file
    keyn
    omni
    tags
    ulti
    abbr
    c-n
    dict
END

# Teardown {{{1

b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe')
    .. '| call vim#undoFtplugin()'

