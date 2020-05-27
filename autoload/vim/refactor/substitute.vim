if exists('g:autoloaded_vim#refactor#substitute')
    finish
endif
let g:autoloaded_vim#refactor#substitute = 1

" TODO: add support for some not-too-complex ranges
" Update: Nope.  It's too slow.
" Try to replace `foo` with `bar` in our vimrc.  It's about 20 times slower with
" `setline()`+`substitute()`+`getline()`+`map()`, compared to `:s`.
const s:PAT =
    "\ the substitution could be in a sequence of commands separated by bars
    \ '\C^\%(.*|\)\='
    "\ modifiers
    \ ..'\s*\zs\%(\%(sil\%[ent]!\=\|keepj\%[umps]\|keepp\%[atterns]\)\s*\)\{,3}'
    "\ range
    \ ..'\(-\=\)'
    "\ command
    \ ..'s\(\i\@!.\)\(.\{-}\)\2\(.\{-}\)\2\([gcen]\{,4}\)$'

" Interface {{{1
fu vim#refactor#substitute#main(...) abort "{{{2
    if !a:0
        let &opfunc = 'vim#refactor#substitute#main'
        return 'g@l'
    endif
    let view = winsaveview()

    let s1 = s:search_substitution_start() | let [lnum1, col1] = getcurpos()[1:2]
    let s2 = s:search_substitution_end() | let [lnum2, col2] = getcurpos()[1:2]

    let bang = type(a:1) == v:t_number ? a:1 : v:true
    if !vim#util#we_can_refactor(
        \ [s1, s2],
        \ lnum1, col1,
        \ lnum2, col2,
        \ bang,
        \ view,
        \ 'substitution command', 'setline()+substitute()',
        \ ) | return | endif

    let old = s:get_old_substitution(lnum1)
    let new = s:get_new_substitution(old)

    call vim#util#put(
        \ new,
        \ lnum1, col1,
        \ lnum2, col2,
        \ )

    call winrestview(view)
endfu
"}}}1
" Core {{{1
fu s:search_substitution_start() abort "{{{2
    " TODO: Should we pass the `c` flag?
    " Should we pass it when searching the end of the command too?
    " Did we forget to pass it in other refactoring functions?
    return vim#util#search(s:PAT, 'b')
endfu

fu s:search_substitution_end() abort "{{{2
    return vim#util#search(s:PAT, 'e')
endfu

fu s:get_old_substitution(lnum) abort "{{{2
    return matchstr(getline(a:lnum), s:PAT)
endfu

fu s:get_new_substitution(old) abort "{{{2
    let [range, _, pat, rep, flags] = matchlist(a:old, s:PAT)[1:5]
    let flags = substitute(flags, 'e', '', '')
    " TODO: support case where pattern or replacement contains a single quote
    " TODO: make sure `&`, `~` and `\` are always escaped in the replacement
    " TODO: when Nvim supports the method call operator, refactor the new
    " substitution command to make it more readable; make sure to update the tests
    let lnum = {'': "'.'", '-': "line('.')-1"}[range]
    let new = printf("call setline(%s, substitute(getline(%s), '%s', '%s', '%s'))", lnum, lnum, pat, rep, flags)
    return new
endfu

