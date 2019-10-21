" Commands {{{1
" Refactor {{{2

com -bar -bang -buffer -range=% Refactor call vim#refactor#general#main(<line1>,<line2>, <bang>0)

" RefIf {{{2

com -bar -buffer -complete=custom,vim#refactor#if#complete -nargs=1
\ RefIf call vim#refactor#if#main('ex', <q-args>)

" RefDot {{{2

" Refactor dot concatenation operator:{{{
"
"     a . b   →  a..b
"     a.b     →  a..b
"     a .. b  →  a..b
"}}}
com -bar -buffer -range=% RefDot call vim#refactor#dot#main(<line1>,<line2>)

" RefHeredoc {{{2

com -bang -bar -buffer -complete=custom,vim#refactor#heredoc#complete -nargs=*
\ RefHeredoc call vim#refactor#heredoc#main(<bang>0, <f-args>)

" RefQuote {{{2

com -bar -buffer -range=% RefQuote <line1>,<line2>s/"\(.\{-}\)"/'\1'/gce

" RefTernary {{{2
" Usage  {{{3
" select an if / else(if) / endif construct, and execute `:RefTernary`.
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
"         return a:mode.'unmap'
"     else
"         return a:mode.(s:has_flag_p(a:flags, 'r') ? 'map' : 'noremap')
"     endif
"
"         →
"
"     return s:has_flag_p(a:flags, 'u')
"        \ ?     a:mode.'unmap'
"        \ :     a:mode.(s:has_flag_p(a:flags, 'r') ? 'map' : 'noremap')

" Code  {{{3

com -bar -buffer -range RefTernary call vim#refactor#ternary#main(<line1>,<line2>)
"}}}2
" RefVval {{{2

com -bar -buffer -range RefVval call vim#refactor#vval#main('ex')
"}}}1
" Mappings {{{1

nno <buffer><nowait><silent> K :<c-u>exe 'help ' . vim#helptopic()<cr>

nno <buffer><nowait><silent> <c-]> :<c-u>call vim#jump_to_tag()<cr>

" The default Vim ftplugin:
"
"     $VIMRUNTIME/ftplugin/vim.vim
"
" … defines the buffer-local  ["  ]"  mappings. I don't want them, because
" I use other global mappings (same keys), which are more powerful (support
" more filetypes).
"
" In theory, we could disable these mappings by setting one of the variable:
"
"    - no_vim_maps       (only vim ftplugin mappings)
"    - no_plugin_maps    (all ftplugin mappings)
"
" Unfortunately, the Vim ftplugin doesn't check the existence of these
" variables, contrary to a few others like `$VIMRUNTIME/ftplugin/mail.vim`.

sil! nunmap <buffer> ["
sil! nunmap <buffer> ]"
sil! vunmap <buffer> ["
sil! vunmap <buffer> ]"
"  │
"  └ If we change the filetype from  `vim` to `python`, then from `python` back to `vim`,
"    we have an error, because `set ft=vim` only loads our ftplugin. It doesn't load the one
"    in the vimruntime, because of a guard (`if exists('b:did_ftplugin')`).
"    So, the mappings are not installed again.

noremap <buffer><expr><nowait><silent> [[ lg#motion#regex#rhs('{{',0)
noremap <buffer><expr><nowait><silent> ]] lg#motion#regex#rhs('{{',1)

noremap <buffer><expr><nowait><silent> [m lg#motion#regex#rhs('fu',0)
noremap <buffer><expr><nowait><silent> ]m lg#motion#regex#rhs('fu',1)

noremap <buffer><expr><nowait><silent> [M lg#motion#regex#rhs('endfu',0)
noremap <buffer><expr><nowait><silent> ]M lg#motion#regex#rhs('endfu',1)

if stridx(&rtp, 'vim-lg-lib') >= 0
    call lg#motion#repeatable#make#all({
        \ 'mode': '',
        \ 'buffer': 1,
        \ 'from': expand('<sfile>:p').':'.expand('<slnum>'),
        \ 'motions': [
        \     {'bwd': '[m',  'fwd': ']m'},
        \     {'bwd': '[M',  'fwd': ']M'},
        \     {'bwd': '[[',  'fwd': ']]'},
        \ ]})
endif

nno <buffer><nowait><silent> =rd :<c-u>RefDot<cr>
xno <buffer><nowait><silent> =rd :RefDot<cr>

nno <buffer><nowait><silent> =rh :<c-u>set opfunc=vim#refactor#heredoc#main<cr>g@l

nno <buffer><nowait><silent> =ri :<c-u>set opfunc=vim#refactor#if#main<cr>g@l

nno <buffer><nowait><silent> =rq :<c-u>RefQuote<cr>
xno <buffer><nowait><silent> =rq :RefQuote<cr>

xno <buffer><nowait><silent> =rt :RefTernary<cr>

nno <buffer><nowait><silent> =rv :<c-u>set opfunc=vim#refactor#vval#main<cr>g@l

" Options {{{1
" flp {{{2
"
"                          ┌ recognize numbered lists
"                          ├─────┐
let &l:flp = '\v^\s*"?\s*%(\d+[.)]|[-*+])\s+'
"                                  ├───┘
"                                  └ recognize unordered lists

" ofu {{{2
"
" Set the function invoked when we press `C-x C-o`.

"             ┌ Found here:    http://vim.wikia.com/wiki/Omni_completion
"             │ Defined here:  /usr/share/vim/vim74/autoload/syntaxcomplete.vim
"             │
setl omnifunc=syntaxcomplete#Complete
" }}}1
" Variables {{{1

" The matchit plugin uses these 3 patterns to make `%` cycle through the
" keyword `function`, `return` and `endfunction`:
"
"         \<fu\%[nction]\>:\<retu\%[rn]\>:\<endf\%[unction]\>
"
" It doesn't work as expected in a function which contains a funcref produced
" by the `function()` function:
"
"         fu MyFunc() abort
"             let myfuncref = function('Foo')
"         endfu
"
" We need to tweak the pattern of the `function` keyword:
"
"         \<fu\%[nction]\>    →    \<fu\%[nction]\>(@!
"                                                  │
"                                                  └ no open parenthesis at the end

let b:match_words =
\                   '\<fu\%[nction]\>(\@!:\<retu\%[rn]\>:\<endf\%[unction]\>,'
\                  .'\<\(wh\%[ile]\|for\)\>:\<brea\%[k]\>:\<con\%[tinue]\>:\<end\(w\%[hile]\|fo\%[r]\)\>,'
\                  .'\<if\>:\<el\%[seif]\>:\<en\%[dif]\>,'
\                  .'\<try\>:\<cat\%[ch]\>:\<fina\%[lly]\>:\<endt\%[ry]\>,'
\                  .'\<aug\%[roup]\s\+\%(END\>\)\@!\S:\<aug\%[roup]\s\+END\>'

" We want the keywords to be searched exactly as we've written them in
" `b:match_words`, no matter the value of `&ic`.
let b:match_ignorecase = 0

" How did we get the rest of the value of `b:match_words`?
"         $VIMRUNTIME/ftplugin/vim.vim
"
" The default ftplugin adds `(:)` which is superfluous, because it's already in
" 'mps', and `matchit` includes in its search all the tokens inside 'mps'.

" Rationale:{{{
" We want  as little  methods as  possible, to have  suggestions as  relevant as
" possible, and review all of them as quickly as possible.
" The presently used methods are, imo, the bare minimum.
"
" We put `file` in first position because we know how to detect whether the text
" before the cursor matches a filepath.
" OTOH,  we  can't  be  sure  that  the  text matches  a  tags  name  or  a  tab
" trigger. Therefore, we must give the priority to `file`.
"
" We put  `keyn`, `tags`, `ulti` afterwards,  in this order, because  the latter
" matches the frequency with which I suspect I'll need those methods.
"
" Finally, we add `dict` and `c-n` because they can still be useful from time to
" time. We put them  at the very end because their  suggestions are often noisy,
" i.e. contain a lot of garbage.
"}}}
const b:mc_chain =<< trim END
    file
    keyn
    tags
    ulti
    dict
    abbr
    c-n
END

" Teardown {{{1

let b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe')
    \ ..'
    \ | setl comments< omnifunc<
    \ | unlet! b:match_words b:match_ignorecase b:mc_chain
    \
    \ | exe "unmap <buffer> [["
    \ | exe "unmap <buffer> ]]"
    \ | exe "unmap <buffer> [m"
    \ | exe "unmap <buffer> ]m"
    \ | exe "unmap <buffer> [M"
    \ | exe "unmap <buffer> ]M"
    \
    \ | exe "nunmap <buffer> K"
    \ | exe "nunmap <buffer> =rd"
    \ | exe "nunmap <buffer> =ri"
    \ | exe "nunmap <buffer> =rq"
    \
    \ | exe "xunmap <buffer> =rd"
    \ | exe "xunmap <buffer> =rq"
    \ | exe "xunmap <buffer> =rt"
    \ | exe "xunmap <buffer> =rv"
    \
    \ | delc RefDot
    \ | delc RefHeredoc
    \ | delc RefIf
    \ | delc RefQuote
    \ | delc RefTernary
    \ | delc RefVval
    \ | delc Refactor
    \ '

