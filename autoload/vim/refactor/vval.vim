" Interface {{{1
fu vim#refactor#vval#main(bang) abort "{{{2
    let view = winsaveview()

    " TODO: Sanity check: make sure the found quotes are *after* `map(`/`filter(`.
    let s2 = s:search_closing_quote() | let [lnum2, col2] = getcurpos()[1:2] | norm! v
    let s1 = s:search_opening_quote() | let [lnum1, col1] = getcurpos()[1:2] | norm! y

    if ! vim#util#we_can_refactor(
        \ [s1, s2],
        \ lnum1, col1,
        \ lnum2, col2,
        \ a:bang,
        \ view,
        \ 'map/filter {expr2}', 'lambda',
        \ ) | return | endif

    let new_expr = '{i,v -> '..s:get_expr(@")..'}'
    call vim#util#put(
        \ new_expr,
        \ lnum1, col1,
        \ lnum2, col2,
        \ )
endfu
"}}}1
" Core {{{1
fu s:search_closing_quote() abort "{{{2
    if vim#util#search('\m\C\<\%(map\|filter\)(', 'be') | return 0 | endif
    norm! %
    return search('["'']', 'bW')
endfu

fu s:search_opening_quote() abort "{{{2
    let char = matchstr(getline('.'), '\%'..col('.')..'c.')
    let pat = char is# '"' ? '\\\@1<!"' : "'\\@1<!''\\@!"
    return search(pat, 'bW')
endfu

fu s:get_expr(captured_text) abort "{{{2
    let expr = a:captured_text
    let quote = expr[-1:-1]
    let is_single_quoted = quote is# "'"
    let expr = substitute(expr, '^\s*'..quote..'\|'..quote..'\s*$', '', 'g')
    if is_single_quoted
        let expr = substitute(expr, "''", "'", 'g')
    else
        let expr = eval('"'..expr..'"')
    endif
    let expr = substitute(expr, 'v:val', 'v', 'g')
    let expr = substitute(expr, 'v:key', 'k', 'g')
    return expr
endfu

