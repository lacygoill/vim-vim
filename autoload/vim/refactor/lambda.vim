" Interface {{{1
fu vim#refactor#lambda#main(...) abort "{{{2
    if !a:0
        let &opfunc = 'vim#refactor#lambda#main'
        return 'g@l'
    endif

    " TODO: A lambda is not always better than an eval string.
    " Make the function support the reverse refactoring (`{_, v -> v}` → `'v:val'`).
    let view = winsaveview()

    " TODO: Sanity check: make sure the found quotes are *after* `map(`/`filter(`.
    let s2 = s:search_closing_quote() | let [lnum2, col2] = getcurpos()[1:2] | norm! v
    let s1 = s:search_opening_quote() | let [lnum1, col1] = getcurpos()[1:2] | norm! y

    let bang = type(a:1) == v:t_number ? a:1 : v:true
    if !vim#util#we_can_refactor(
        \ [s1, s2],
        \ lnum1, col1,
        \ lnum2, col2,
        \ bang,
        \ view,
        \ 'map/filter {expr2}', 'lambda',
        \ ) | return | endif

    if @" =~# '\Cv:key'
        let new_expr = '{i, v -> ' .. s:get_expr(@") .. '}'
    else
        let new_expr = '{_, v -> ' .. s:get_expr(@") .. '}'
    endif

    call vim#util#put(
        \ new_expr,
        \ lnum1, col1,
        \ lnum2, col2,
        \ )
endfu
"}}}1
" Core {{{1
fu s:search_closing_quote() abort "{{{2
    if !vim#util#search('\m\C\<\%(map\|filter\)(', 'be') | return 0 | endif
    let pos = getcurpos()
    norm! %
    if getcurpos() == pos | return 0 | endif
    return search('["'']', 'bW')
endfu

def s:search_opening_quote(): number #{{{2
    let char = getline('.')->strpart(col('.') - 1)[0]
    let pat = char == '"' ? '\\\@1<!"' : "'\\@1<!''\\@!"
    return search(pat, 'bW')
enddef

fu s:get_expr(captured_text) abort "{{{2
    let expr = a:captured_text
    let quote = expr[-1:-1]
    let is_single_quoted = quote is# "'"
    let expr = substitute(expr, '^\s*' .. quote .. '\|' .. quote .. '\s*$', '', 'g')
    if is_single_quoted
        let expr = substitute(expr, "''", "'", 'g')
    else
        let expr = eval('"' .. expr .. '"')
    endif
    let expr = substitute(expr, 'v:val', 'v', 'g')
    let expr = substitute(expr, 'v:key', 'i', 'g')
    return expr
endfu

