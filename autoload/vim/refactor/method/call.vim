if exists('s:loaded')
    finish
endif
let s:loaded = v:true

const s:FUNCTION_NAMES = getcompletion('[a-z]', 'function')
    \ ->filter({_, v -> v =~# '^[a-z][^#]*\%((\|()\)$'})

" Interface {{{1
function vim#refactor#method#call#main(...) abort "{{{2
    if !a:0
        let &operatorfunc = 'vim#refactor#method#call#main'
        return 'g@l'
    endif
    let view = winsaveview()

    call vim#util#search('\%.c\%.l\S*\zs(')
    let funcname = getline('.')->matchstr('\S*\%.c')
    if match(s:FUNCTION_NAMES, '^\V' .. funcname .. '\m\%((\|()\)') == -1
        echohl ErrorMsg
        echo 'no builtin function under the cursor'
        echohl NONE
        call winrestview(view)
    endif
    normal! v
    " TODO: Do we need to write a `vim#util#jump_to_closing_bracket()` function?{{{
    "
    " If so, here's the code:
    "
    "     let opening_bracket = getline('.')->strpart(col('.') - 1)[0]
    "     if index(['<', '(', '[', '{'], opening_bracket) == -1
    "         return
    "     endif
    "     let closing_bracket = {'<': '>', '(': ')', '[': ']', '{': '}'}[opening_bracket]
    "     call searchpair(opening_bracket, '', closing_bracket,
    "         \ 'W', 'synID(".", col("."), v:true)->synIDattr("name") =~ "\\ccomment\\|string"')
    "
    " But I'm not sure we need it.
    " Maybe `vim#util#search(')')` is enough...
    "}}}
    call vim#util#jump_to_closing_bracket()
    silent normal! y
    "     let s2 = s:search_closing_quote() | let [lnum2, col2] = getcurpos()[1 : 2] | normal! v
    "     let s1 = s:search_opening_quote() | let [lnum1, col1] = getcurpos()[1 : 2] | normal! y

    let bang = typename(a:1) == 'number' ? a:1 : v:true
    "     if !vim#util#weCanRefactor(
    "         \ [s1, s2],
    "         \ lnum1, col1,
    "         \ lnum2, col2,
    "         \ bang,
    "         \ view,
    "         \ 'map/filter {expr2}', 'lambda',
    "         \ )
    "         return
    "     endif

    "     if @" =~# '\Cv:key'
    "         let new_expr = '{i, v -> ' .. s:get_expr(@") .. '}'
    "     else
    "         let new_expr = '{_, v -> ' .. s:get_expr(@") .. '}'
    "     endif

    "     call vim#util#put(
    "         \ new_expr,
    "         \ lnum1, col1,
    "         \ lnum2, col2,
    "         \ )
endfunction
"}}}1
