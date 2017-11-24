" Commands {{{1
" Refactor {{{2

com! -bar -bang -buffer -range=% Refactor call vim#refactor(<line1>,<line2>, <bang>0)

cnorea <expr> <buffer> refactor getcmdtype() ==# ':' && getcmdline() ==# 'refactor'
\                               ?    'Refactor'
\                               :    'refactor'

" RefIf {{{2
" Usage: {{{3
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

" Command {{{3

com! -buffer -range RefIf call vim#ref_if(<line1>,<line2>)

cnorea <expr> <buffer> refif getcmdtype() ==# ':' && getcmdline() ==# 'refif'
\                            ?    'RefIf'
\                            :    'refif'

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
" variables, contrary to others like `$VIMRUNTIME/ftplugin/mail.vim`.

nunmap <buffer> ["
nunmap <buffer> ]"

nno <buffer> <nowait> <silent> [[   :<C-U>let g:motion_to_repeat = '[['
                                    \ <Bar> call myfuncs#sections_custom('\v\{{3}%(\d+)?\s*$', 0)<cr>

nno <buffer> <nowait> <silent> ]]   :<C-U>let g:motion_to_repeat = ']]'
                                    \ <Bar> call myfuncs#sections_custom('\v\{{3}%(\d+)?\s*$', 1)<cr>

nno <buffer> <nowait> <silent> [m   :<C-U>let g:motion_to_repeat = '[m'
                                    \ <Bar> call myfuncs#sections_custom('^\s*fu\%[nction]!\s\+', 0)<cr>

nno <buffer> <nowait> <silent> ]m   :<C-U>let g:motion_to_repeat = ']m'
                                    \ <Bar> call myfuncs#sections_custom('^\s*fu\%[nction]!\s\+', 1)<cr>

nno <buffer> <nowait> <silent> [M   :<C-U>let g:motion_to_repeat = '[M'
                                    \ <Bar> call myfuncs#sections_custom('^\s*endfu\%[nction]\s*$', 0)<cr>

nno <buffer> <nowait> <silent> ]M   :<C-U>let g:motion_to_repeat = ']M'
                                    \ <Bar> call myfuncs#sections_custom('^\s*endfu\%[nction]\s*$', 1)<cr>

" Options {{{1
" window-local {{{2
augroup my_vim
    au! *            <buffer>
    au  BufWinEnter  <buffer>  setl fdm=marker
                           \ | let &l:fdt = 'vim#fold_text()'
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
\                         | exe 'cuna   <buffer> refactor'
\                         | exe 'cuna   <buffer> refif'
\                         | delcommand Refactor
\                         | delcommand RefIf
\                       "
