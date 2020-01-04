if exists('g:autoloaded_vim#refactor#method')
    finish
endif
let g:autoloaded_vim#refactor#method = 1

let s:FUNCTION_NAMES = filter(getcompletion('[a-z]', 'function'), {_,v -> v =~# '^[a-z][^#]*\%((\|()\)$'})

" Interface {{{1
fu vim#refactor#method#main(bang) abort "{{{2
    let view = winsaveview()

    call vim#util#search('\%'..col('.')..'c\%'..line('.')..'l\S*\zs(')
    let funcname = matchstr(getline('.'), '\S*\%'..col('.')..'c')
    if match(s:FUNCTION_NAMES, '^\V'..funcname..'\m\%((\|()\)') == -1
        echohl ErrorMsg
        echo 'no builtin function under the cursor'
        echohl NONE
        call winrestview(view)
    endif
    norm! v
    " TODO: Do we need to write a `vim#util#jump_to_closing_bracket()` function?{{{
    "
    " If so, here's the code:
    "
    "     let opening_bracket = getline('.')[col('.')-1]
    "     if index(['<', '(', '[', '{'], opening_bracket) == -1
    "         return
    "     endif
    "     let closing_bracket = {'<': '>', '(': ')', '[': ']', '{': '}'}[opening_bracket]
    "     call searchpair(opening_bracket, '', closing_bracket,
    "         \ 'W', 'synIDattr(synID(line("."),col("."),1),"name") =~? "comment\\|string"')
    "
    " But I'm not sure we need it.
    " Maybe `vim#util#search(')')` is enough...
    "}}}
    call vim#util#jump_to_closing_bracket()
    sil norm! y
    "     let s2 = s:search_closing_quote() | let [lnum2, col2] = getcurpos()[1:2] | norm! v
    "     let s1 = s:search_opening_quote() | let [lnum1, col1] = getcurpos()[1:2] | norm! y

    "     if !vim#util#we_can_refactor(
    "         \ [s1, s2],
    "         \ lnum1, col1,
    "         \ lnum2, col2,
    "         \ a:bang,
    "         \ view,
    "         \ 'map/filter {expr2}', 'lambda',
    "         \ ) | return | endif

    "     if @" =~# '\Cv:key'
    "         let new_expr = '{i,v -> '..s:get_expr(@")..'}'
    "     else
    "         let new_expr = '{_,v -> '..s:get_expr(@")..'}'
    "     endif

    "     call vim#util#put(
    "         \ new_expr,
    "         \ lnum1, col1,
    "         \ lnum2, col2,
    "         \ )
endfu
"}}}1
" Core {{{1
