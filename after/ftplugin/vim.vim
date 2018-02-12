" Commands {{{1
" Refactor {{{2

com! -bar -bang -buffer -range=% Refactor call vim#refactor(<line1>,<line2>, <bang>0)

cnorea <expr> <buffer> refactor  getcmdtype() is# ':' && getcmdline() is# 'refactor'
\                                ?    'Refactor'
\                                :    'refactor'

" RefDots {{{2
com! -bar -buffer -range=% RefDots <line1>,<line2>s/ \. /./gce

cnorea <expr> <buffer> refdots  getcmdtype() is# ':' && getcmdline() is# 'refdots'
\                                ?    'Refdots'
\                                :    'refdots'

" RefIf {{{2
" Usage  {{{3
" select an if / else(if) / endif construct, and execute `:RefIf`.
" It will perform this conversion:

"         if var ==# 1                 let val = var ==# 1
"             let val = 'foo'          \?            'foo'
"         elseif var ==# 2             \:        var ==# 2
"             let val = 'bar'    →     \?            'bar'
"         else                         \:            'baz'
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

cnorea <expr> <buffer> refif  getcmdtype() is# ':' && getcmdline() is# 'refif'
\                             ?    'RefIf'
\                             :    'refif'

" RefQuotes {{{2

com! -bar -buffer -range=% RefQuotes <line1>,<line2>s/"\(.\{-}\)"/'\1'/gce

cnorea <expr> <buffer> refquotes  getcmdtype() is# ':' && getcmdline() is# 'refquotes'
\                                ?    'Refquotes'
\                                :    'refquotes'

" RefVval {{{2

com! -bar -buffer -range RefVval call vim#ref_v_val()

cnorea <expr> <buffer> refvval  getcmdtype() is# ':' && getcmdline() is# 'refvval'
\                               ?    'RefVval'
\                               :    'refvval'

" Mappings {{{1

" The default Vim ftplugin:
"         $VIMRUNTIME/ftplugin/vim.vim
"
" … defines the buffer-local  ["  ]"  mappings. I don't want them, because
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

noremap  <buffer><expr><nowait><silent>  [[  lg#motion#regex#rhs('{{',0)
noremap  <buffer><expr><nowait><silent>  ]]  lg#motion#regex#rhs('{{',1)

noremap  <buffer><expr><nowait><silent>  [m  lg#motion#regex#rhs('fu',0)
noremap  <buffer><expr><nowait><silent>  ]m  lg#motion#regex#rhs('fu',1)

noremap  <buffer><expr><nowait><silent>  [M  lg#motion#regex#rhs('endfu',0)
noremap  <buffer><expr><nowait><silent>  ]M  lg#motion#regex#rhs('endfu',1)

" Why this check?{{{
"
" We're going to call a function installed by `vim-lg-lib`.
" The latter could be disabled if we're debugging.
" So, we need:
"
"     has_key(get(g:, 'plugs', {}), 'vim-lg-lib')
"
" Also, we may source this file manually.
" For example, in `vim-toggle-settings`, we have a mapping to edit
" help files. When we press it the 1st time, the file becomes editable.
" When, we press it a 2nd time, it gets back UNeditable.
" But to do so, we source all `after/ftplugin/help.vim` files in the rtp:
"
"     runtime! after/ftplugin/help.vim
"
" When that happens, Vim hasn't removed the local motions, because:
"
"     • the 1st time we pressed the mapping, we have't removed any local motion
"
"     • the 2nd time, `:runtime!` hasn't fired `FileType`,
"       so `b:undo_ftplugin`  hasn't been executed
"
" Bottome Line:
" This file may be sourced, while the local motions are already repeatable.
" We must avoid trying to make local motions repeatable, if they already are.
" How do we know they already are repeatable?
"
"     exists('b:repeatable_motions') ==# 1
"}}}
" Alternative:{{{
"
"     try
"         if !exists('b:repeatable_motions')
"             call lg#motion#repeatable#make#all(…)
"         endif
"     catch
"         " Why `:unsilent`?{{{
"         "
"         " When a filetype plugin is sourced, it seems we can't echo anything.
"         " If we  need to call a  function in a  filetype plugin, which may  raise an
"         " error, this will prevent `:echom` from working.
"         " MWE:
"         "
"         "                                  ┌ file containing an `:echo[m]` statement
"         "                                  │
"         "     au FileType    potion source some_file  (silent)
"         "     au BufWinEnter *      source some_file  (not silent)
"        "}}}
"         unsilent call lg#catch_error()
"     endtry
"}}}
" Why don't use the alternative?{{{
"
" In   this   case,   calling    `lg#catch_error()`   is   wrong,   because   if
" `lg#motion#repeatable#make#all()`  doesn't   exist,  then  `lg#catch_error()`
" won't either.
"}}}
" Why not checking the existence of the function?{{{
"
" Not reliable, because it's an autoloaded function.
" Maybe it hasn't be sourced, and thus doesn't exist, but can be.
"}}}
if has_key(get(g:, 'plugs', {}), 'vim-lg-lib')
    call lg#motion#repeatable#make#all({
    \        'mode':   '',
    \        'buffer': 1,
    \        'axis':   {'bwd': ',', 'fwd': ';'},
    \        'from':   expand('<sfile>:p').':'.expand('<slnum>'),
    \        'motions': [
    \                     {'bwd': '[m',  'fwd': ']m', },
    \                     {'bwd': '[M',  'fwd': ']M', },
    \                     {'bwd': '[[',  'fwd': ']]', },
    \                   ]
    \ })
endif

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
\                         | exe ' unmap <buffer> [['
\                         | exe ' unmap <buffer> ]]'
\                         | exe ' unmap <buffer> [m'
\                         | exe ' unmap <buffer> ]m'
\                         | exe ' unmap <buffer> [M'
\                         | exe ' unmap <buffer> ]M'
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
