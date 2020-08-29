" TODO: Check whether some refactoring commands could be turned into operators.{{{
"
" ---
"
" Make sure that:
"
"    - all operators can be invoked via an Ex command
"    - the latter supports a bang
"    - without a bang, the refactored text is highlighted, and the command asks for your confirmation
"}}}

" Commands {{{1
" Refactor {{{2

com -bang -bar -buffer -range=% Refactor call vim#refactor#general#main(<line1>,<line2>, <bang>0)

" RefBar {{{2

com -bang -bar -buffer -nargs=? -complete=custom,vim#refactor#bar#complete
    \ RefBar call vim#refactor#bar#main(<bang>0, <f-args>)

" RefDot {{{2

" Refactor dot concatenation operator:{{{
"
"     a . b   →  a..b
"     a.b     →  a..b
"     a .. b  →  a..b
"}}}
com -bang -bar -buffer -range=% RefDot call vim#refactor#dot#main(<bang>0, <line1>,<line2>)

" RefHeredoc {{{2

com -bang -bar -buffer -nargs=* -complete=custom,vim#refactor#heredoc#complete
    \ RefHeredoc call vim#refactor#heredoc#main(<bang>0, <f-args>)

" RefLambda {{{2

com -bang -bar -buffer RefLambda call vim#refactor#lambda#main(<bang>0)

" RefMethod {{{2

com -bang -bar -buffer RefMethod call vim#refactor#method#main(<bang>0)

" RefQuote {{{2

com -bar -buffer -range=% RefQuote <line1>,<line2>s/"\(.\{-}\)"/'\1'/gce

" RefSubstitute {{{2

com -bang -bar -buffer RefSubstitute call vim#refactor#substitute#main#main(<bang>0)

" RefTernary {{{2
" Usage  {{{3

" Select an `if / else(if) / endif` block, and execute `:RefTernary`.
" It will perform this conversion:

"         if var == 1                 let val = var == 1
"             let val = 'foo'               \ ?     'foo'
"         elseif var == 2                   \ : var == 2
"             let val = 'bar'    →          \ ?     'bar'
"         else                              \ :     'baz'
"             let val = 'baz'
"         endif
"
" Or this one:
"
"     if s:has_flag_p(a:flags, 'u')
"         return a:mode .. 'unmap'
"     else
"         return a:mode .. (s:has_flag_p(a:flags, 'r') ? 'map' : 'noremap')
"     endif
"
"         →
"
"     return s:has_flag_p(a:flags, 'u')
"         \ ?     a:mode .. 'unmap'
"         \ :     a:mode .. (s:has_flag_p(a:flags, 'r') ? 'map' : 'noremap')

" Code  {{{3

com -bar -buffer -range RefTernary call vim#refactor#ternary#main(<line1>,<line2>)
"}}}2
" RefVim9 {{{2

com -bar -buffer -range=% RefVim9 call vim#refactor#vim9#main(<line1>, <line2>)
"}}}1
" Mappings {{{1

nno <buffer><nowait><silent> <c-]> :<c-u>call vim#jump_to_tag()<cr>

noremap <buffer><expr><nowait><silent> [m brackets#move#regex('fu', 0)
noremap <buffer><expr><nowait><silent> ]m brackets#move#regex('fu', 1)

noremap <buffer><expr><nowait><silent> [M brackets#move#regex('endfu', 0)
noremap <buffer><expr><nowait><silent> ]M brackets#move#regex('endfu', 1)

sil! call repmap#make#repeatable({
    \ 'mode': '',
    \ 'buffer': 1,
    \ 'from': expand('<sfile>:p') .. ':' .. expand('<slnum>'),
    \ 'motions': [
    \     {'bwd': '[m', 'fwd': ']m'},
    \     {'bwd': '[M', 'fwd': ']M'},
    \ ]})

" TODO: When should we install visual mappings?

nno <buffer><expr><nowait> =rb vim#refactor#bar#main()

" TODO: should we turn those into operators (same thing for `=rq` and maybe `=rt`)?
nno <buffer><nowait><silent> =rd :<c-u>RefDot<cr>
xno <buffer><nowait><silent> =rd :RefDot<cr>

nno <buffer><expr><nowait> =rh vim#refactor#heredoc#main()
nno <buffer><expr><nowait> =rl vim#refactor#lambda#main()
nno <buffer><expr><nowait> =rm vim#refactor#method#call#main()
nno <buffer><expr><nowait> =r- vim#refactor#method#splitjoin#main()

nno <buffer><nowait><silent> =rq :<c-u>RefQuote<cr>
xno <buffer><nowait><silent> =rq :RefQuote<cr>

nno <buffer><expr><nowait> =rs vim#refactor#substitute#main()

xno <buffer><nowait><silent> =rt :RefTernary<cr>

" Options {{{1
" flp {{{2

let &l:flp = '^\s*"\=\s*\%(\d\+[.)]\|[-*+]\)\s\+'
"                          ├──────┘  ├───┘
"                          │         └ recognize unordered lists
"                          └ recognize numbered lists
" }}}1
" Variables {{{1

let b:mc_chain =<< trim END
    file
    keyn
    omni
    tags
    ulti
    abbr
    c-n
    dict
END

" Teardown {{{1

let b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe')
    \ .. '| call vim#undo_ftplugin()'

