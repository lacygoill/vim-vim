" Commands {{{1
" Refactor {{{2

com! -bar -bang -buffer -range=% Refactor call vim#refactor(<line1>,<line2>, <bang>0)

cnorea <expr> <buffer> refactor  getcmdtype() ==# ':' && getcmdline() ==# 'refactor'
\                                ?    'Refactor'
\                                :    'refactor'

" RefDots {{{2
com! -bar -buffer -range=% RefDots <line1>,<line2>s/ \. /./gce

cnorea <expr> <buffer> refdots  getcmdtype() ==# ':' && getcmdline() ==# 'refdots'
\                                ?    'Refdots'
\                                :    'refdots'

" RefIf {{{2
" Usage  {{{3
" select an if / else(if) / endif construct, and execute `:RefIf`.
" It will perform this conversion:

"         if var == 1                 let val = var == 1
"             let val = 'foo'         \?            'foo'
"         elseif var == 2             \:        var == 2
"             let val = 'bar'    →    \?            'bar'
"         else                        \:            'baz'
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
" return s:has_flag_p(a:flags, 'u')
" \?         a:mode.'unmap'
" \:         a:mode.(s:has_flag_p(a:flags, 'r') ? 'map' : 'noremap')

" Code  {{{3

com! -bar -buffer -range RefIf call vim#ref_if(<line1>,<line2>)

cnorea <expr> <buffer> refif  getcmdtype() ==# ':' && getcmdline() ==# 'refif'
\                             ?    'RefIf'
\                             :    'refif'

" RefQuotes {{{2

com! -bar -buffer -range=% RefQuotes <line1>,<line2>s/"\(.\{-}\)"/'\1'/gce

cnorea <expr> <buffer> refquotes  getcmdtype() ==# ':' && getcmdline() ==# 'refquotes'
\                                ?    'Refquotes'
\                                :    'refquotes'

" RefVval {{{2

com! -bar -buffer -range RefVval call vim#ref_v_val()

cnorea <expr> <buffer> refvval  getcmdtype() ==# ':' && getcmdline() ==# 'refvval'
\                               ?    'RefVval'
\                               :    'refvval'

" Mappings {{{1

" The default Vim ftplugin:
"         $VIMRUNTIME/ftplugin/vim.vim
"
" … defines the buffer-local `["`, `]"` mappings. I don't want them, because
" I use other global mappings (same keys), which are more powerful (support
" more filetypes).
"
" In theory, we could disable these mappings by setting one of the variable:
"
"         • no_vim_maps       (only vim ftplugin mappings)
"         • no_plugin_maps    (all ftplugin mappings)
"
" Unfortunately, the Vim ftplugin doesn't check the existence of these
" variables, contrary to a few others like `$VIMRUNTIME/ftplugin/mail.vim`.

sil! nunmap  <buffer>  ["
sil! nunmap  <buffer>  ]"
sil! vunmap  <buffer>  ["
sil! vunmap  <buffer>  ]"
"  │
"  └ If we change the filetype from  `vim` to `python`, then from `python` back to `vim`,
"    we have an error, because `set ft=vim` only loads our ftplugin. It doesn't load the one
"    in the vimruntime, because of a guard (`if exists('b:did_ftplugin')`).
"    So, the mappings are not installed again.

nno  <buffer><nowait><silent>  [[   :<c-u>call myfuncs#sections_custom('\v\{{3}%(\d+)?\s*$', 0)<cr>
nno  <buffer><nowait><silent>  ]]   :<c-u>call myfuncs#sections_custom('\v\{{3}%(\d+)?\s*$', 1)<cr>

xno  <buffer><nowait><silent>  [[   :<c-u>exe 'norm! gv' <bar> call myfuncs#sections_custom('\v\{{3}%(\d+)?\s*$', 0)<cr>
xno  <buffer><nowait><silent>  ]]   :<c-u>exe 'norm! gv' <bar> call myfuncs#sections_custom('\v\{{3}%(\d+)?\s*$', 1)<cr>


nno  <buffer><nowait><silent>  [m   :<c-u>call myfuncs#sections_custom('^\s*fu\%[nction]!\s\+', 0)<cr>
nno  <buffer><nowait><silent>  ]m   :<c-u>call myfuncs#sections_custom('^\s*fu\%[nction]!\s\+', 1)<cr>

xno  <buffer><nowait><silent>  [m   :<c-u>exe 'norm! gv' <bar> call myfuncs#sections_custom('^\s*fu\%[nction]!\s\+', 0)<cr>
xno  <buffer><nowait><silent>  ]m   :<c-u>exe 'norm! gv' <bar> call myfuncs#sections_custom('^\s*fu\%[nction]!\s\+', 1)<cr>

ono  <buffer><nowait><silent>  [m   :<c-u>call myfuncs#sections_custom('^\s*fu\%[nction]!\s\+', 0)<cr>
ono  <buffer><nowait><silent>  ]m   :<c-u>call myfuncs#sections_custom('^\s*fu\%[nction]!\s\+', 1)<cr>


nno  <buffer><nowait><silent>  [M   :<c-u>call myfuncs#sections_custom('^\s*endfu\%[nction]\s*$', 0)<cr>
nno  <buffer><nowait><silent>  ]M   :<c-u>call myfuncs#sections_custom('^\s*endfu\%[nction]\s*$', 1)<cr>

xno  <buffer><nowait><silent>  [M   :<c-u>exe 'norm! gv' <bar> call myfuncs#sections_custom('^\s*endfu\%[nction]\s*$', 0)<cr>
xno  <buffer><nowait><silent>  ]M   :<c-u>exe 'norm! gv' <bar> call myfuncs#sections_custom('^\s*endfu\%[nction]\s*$', 1)<cr>

try
    " FIXME:
    " Change the name of the function, the last part (after the last #), so that
    " it doesn't match the right one.
    " Then restart Vim.
    " Suddenly, `g;` doesn't work anymore. Why? It doesn't have anything to do
    " with these motions.
    "
    " Update:
    " The issue is fixed once we add a guard in the repeatable motion plugin file.
    " Try to understand how the issue is fixed.
    " Then, ask yourself whether we should add a guard in ALL autoload files.
    "
    " Update:
    " Here's what I think happens:
    "
    "     1. The function name is wrong and thus doesn't match any existing function.
    "
    "     2. Vim looks for this undefined function
    "            in a file `main`,
    "            inside a directory `motions`,
    "            inside a directory `lg`,
    "            inside a directory in the rtp
    "
    "     3. It resources the file which makes motions repeatable.
    "        The latter contains some mappings, assignments, and calls to functions.
    "        Doing those things several times is probably the cause of the error here.
    "
    "        More generally,  we should never  initialize the state of  a plugin
    "        nor change its interface more than once.
    "        So, you should probably add a guard in all autoload files, where there's
    "        some interface or where we initialize a plugin state via:
    "
    "            • an assignment      ex: let s:myvar = 123
    "            • a function call    ex: call s:init()
    "
    "         Note  that  in general  there  should  be no  interface  (autocmd,
    "         command, mapping) in an autoloaded file.

    " TODO:
    " Try to merge the 2 motions in all modes in 2 mappings using `:noremap`.
    "  This  will  allow  us  to  repeat   them  with  a  single  invocation  of
    " `lg#motions#main#make_repeatable()`.
    "
    " Example:{{{
    "
    "                                        ┌ necessary to get the full name of the mode,
    "                                        │ otherwise in operator-pending mode,
    "                                        │ we would get 'n' instead of 'no'
    "                                        │
    "     noremap  <expr>  <down>  Func(mode(1),1)
    "     noremap  <expr>  <up>    Func(mode(1),0)
    "
    "     fu! Func(mode, is_fwd) abort
    "         let plug_dir = a:is_fwd ? 'fwd' : 'bwd'
    "         let seq = index(['v', 'V', "\<c-v>"], a:mode) >= 0
    "         \?            "\<plug>(return-visual-".plug_dir.')'
    "         \:        a:mode ==# 'no'
    "         \?            "\<plug>(return-op-".plug_dir.')'
    "         \:            "\<plug>(return-normal-".plug_dir.')'
    "         call feedkeys(seq, 'i')
    "         return ''
    "     endfu
    "
    "     nno  <silent>  <plug>(return-normal-bwd)  :<c-u>call search('^\s*return\>', 'bW')<cr>
    "     xno  <silent>  <plug>(return-visual-bwd)  :<c-u>exe 'norm! gv' <bar> call search('^\s*return\>', 'bW')<cr>
    "                                                     └────────────┤
    "                                                                  └ necessary for the search to be done
    "                                                                    in visual mode
    "
    "     ono  <silent>  <plug>(return-op-bwd)      :<c-u>call search('^\s*return\>', 'bW')<cr>
    "
    "     nno  <silent>  <plug>(return-normal-fwd)  :<c-u>call search('^\s*return\>', 'W')<cr>
    "     xno  <silent>  <plug>(return-visual-fwd)  :<c-u>exe 'norm! gv' <bar> call search('^\s*return\>', 'W')<cr>
    "     ono  <silent>  <plug>(return-op-fwd)      :<c-u>call search('^\s*return\>', 'W')<cr>
    "}}}


    " TODO:
    " Visit other filetype plugins, and clean their code regarding motions.
    "
    "         • define motions in the 3 main modes, nvo
    "
    "         • make the code as less verbose as possible (:noremap vs :nno + :xno + :ono)
    "
    "         • update/Check `b:undo_ftplugin`
    call lg#motions#main#make_repeatable(
    \                     { 'mode': 'n',
    \                       'buffer': 1,
    \                       'motions': [
    \                                    {'bwd': '[m',  'fwd': ']m',  'axis': 1 },
    \                                    {'bwd': '[M',  'fwd': ']M',  'axis': 1 },
    \                                    {'bwd': '[[',  'fwd': ']]',  'axis': 1 },
    \                                    {'bwd': '[]',  'fwd': '][',  'axis': 1 },
    \                                  ]})

    call lg#motions#main#make_repeatable(
    \                     { 'mode': 'x',
    \                       'buffer': 1,
    \                       'motions': [
    \                                    {'bwd': '[m',  'fwd': ']m',  'axis': 1 },
    \                                    {'bwd': '[M',  'fwd': ']M',  'axis': 1 },
    \                                    {'bwd': '[[',  'fwd': ']]',  'axis': 1 },
    \                                    {'bwd': '[]',  'fwd': '][',  'axis': 1 },
    \                                  ]})

    call lg#motions#main#make_repeatable(
    \                     { 'mode': 'o',
    \                       'buffer': 1,
    \                       'motions': [
    \                                    {'bwd': '[m',  'fwd': ']m',  'axis': 1 },
    \                                    {'bwd': '[M',  'fwd': ']M',  'axis': 1 },
    \                                    {'bwd': '[[',  'fwd': ']]',  'axis': 1 },
    \                                    {'bwd': '[]',  'fwd': '][',  'axis': 1 },
    \                                  ]})

    " Why making `[]` and `][` repeatable? They don't exist in this file!
    " True. But they are defined in $VIMRUNTIME/ftplugin/vim.vim
catch
    call lg#catch_error()
endtry

nno  <buffer><nowait><silent>  =rd  :<c-u>RefDots<cr>
xno  <buffer><nowait><silent>  =rd  :RefDots<cr>

xno  <buffer><nowait><silent>  =ri  :RefIf<cr>

nno  <buffer><nowait><silent>  =rq  :<c-u>RefQuotes<cr>
xno  <buffer><nowait><silent>  =rq  :RefQuotes<cr>

xno  <buffer><nowait><silent>  =rv  :RefVval<cr>
"                              │││
"                              ││└ v:Val
"                              │└ Refactor
"                              └ fix

" Options {{{1
" window-local {{{2
augroup my_vim
    au! *            <buffer>
    au  BufWinEnter  <buffer>  setl fdm=marker
                           \ | let &l:fdt = 'fold#text()'
                           \ | setl cocu=nc
                           \ | setl cole=3
                           " We've included markers, the ones used in folds, inside syntax elements using
                           " the `conceal` argument, to hide them. But for this to work, we also have to set
                           " 'concealcursor' and 'conceallevel' properly.
augroup END

" flp {{{2
"
"                                ┌ recognize numbered lists
"                          ┌─────┤
let &l:flp = '\v^\s*"?\s*%(\d+[.)]|[-*+•])\s+'
"                                  └────┤
"                                       └ recognize unordered lists

" kp {{{2
"
" Default program to call when hitting K on a word
setl keywordprg=:help

" If you end up using a complex command, then use a level of indirection.
"
" First define a custom command, then assign it to the option.
"
" https://gist.github.com/romainl/8d3b73428b4366f75a19be2dad2f0987
" This mechanism wouldn't work for other '*prg' options, like:
"
"     • 'cscopeprg'
"     • 'csprg'
"     • 'equalprg'
"     • 'formatprg'
"     • 'grepprg'
"     • 'makeprg'
"
" …  because  they  all  interpret   their  values  as  an  external  program.
" 'keywordprg'  too. But it  can also  interpret it  as a  Vim command,  if it's
" prefixed with a colon.

" ofu {{{2
"
" Set the function invoked when we press `C-x C-o`.

"             ┌─ Found here:    http://vim.wikia.com/wiki/Omni_completion
"             │  Defined here:  /usr/share/vim/vim74/autoload/syntaxcomplete.vim
"             │
setl omnifunc=syntaxcomplete#Complete

" Variables {{{1

" The matchit plugin uses these 3 patterns to make `%` cycle through the
" keyword `function`, `return` and `endfunction`:
"
"         \<fu\%[nction]\>:\<retu\%[rn]\>:\<endf\%[unction]\>
"
" It doesn't work as expected in a function which contains a funcref produced
" by the `function()` function:
"
"         fu! MyFunc() abort
"             let myfuncref = function('Foo')
"         endfu
"
" We need to tweak the pattern of the `function` keyword:
"
"         \<fu\%[nction]\>    →    \<fu\%[nction]\>(@!
"                                                  │
"                                                  └─ no open parenthesis at the end

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

" Teardown {{{1

let b:undo_ftplugin =          get(b:, 'undo_ftplugin', '')
\                     . (empty(get(b:, 'undo_ftplugin', '')) ? '' : '|')
\                     . "
\                           setl cocu< cole< comments< fdm< fdt< kp< omnifunc<
\                         | unlet! b:match_words b:match_ignorecase
\                         | exe 'au!  my_vim * <buffer>'
\                         | exe 'nunmap <buffer> [['
\                         | exe 'nunmap <buffer> ]]'
\                         | exe 'nunmap <buffer> [m'
\                         | exe 'nunmap <buffer> ]m'
\                         | exe 'nunmap <buffer> [M'
\                         | exe 'nunmap <buffer> ]M'
\                         | exe 'xunmap <buffer> [['
\                         | exe 'xunmap <buffer> ]]'
\                         | exe 'xunmap <buffer> [m'
\                         | exe 'xunmap <buffer> ]m'
\                         | exe 'xunmap <buffer> [M'
\                         | exe 'xunmap <buffer> ]M'
\                         | exe 'nunmap <buffer> =rd'
\                         | exe 'nunmap <buffer> =rq'
\                         | exe 'xunmap <buffer> =rd'
\                         | exe 'xunmap <buffer> =ri'
\                         | exe 'xunmap <buffer> =rq'
\                         | exe 'xunmap <buffer> =rv'
\                         | exe 'cuna   <buffer> refactor'
\                         | exe 'cuna   <buffer> refdots'
\                         | exe 'cuna   <buffer> refif'
\                         | exe 'cuna   <buffer> refquotes'
\                         | exe 'cuna   <buffer> refvval'
\                         | delc RefDots
\                         | delc RefIf
\                         | delc RefQuotes
\                         | delc RefVval
\                         | delc Refactor
\                       "
