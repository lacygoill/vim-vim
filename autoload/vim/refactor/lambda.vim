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
    let s2 = s:SearchClosingQuote() | let [lnum2, col2] = getcurpos()[1 : 2] | norm! v
    let s1 = s:SearchOpeningQuote() | let [lnum1, col1] = getcurpos()[1 : 2] | norm! y

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

fu vim#refactor#lambda#new(...) abort "{{{2
    if !a:0
        let &opfunc = 'vim#refactor#lambda#new'
        return 'g@l'
    endif
    call searchpair('{', '', '}', 'bcW')
    let start = getpos('.')
    call searchpair('{', '', '}', 'W')
    " delete "}"
    call getline('.')
        \ ->substitute('.*\zs\%' .. col('.') .. 'c.', '', '')
        \ ->setline('.')
    call setpos('.', start)
    " replace "{" with "("
    call getline('.')
        \ ->substitute('.*\zs\%' .. col('.') .. 'c.', '(', '')
        \ ->setline('.')
    " replace "->" with "=>"
    call getline('.')
        \ ->substitute('.*\%' .. start[2] .. 'c.\{-}\zs\s*->', ') =>', '')
        \ ->setline('.')
endfu
"}}}1
" Core {{{1
fu s:SearchClosingQuote() abort "{{{2
    " FIXME:  The logic is wrong when we dealing with a nested `map()`/`filter()`.{{{
    "
    " Example:
    "
    "     filter(map(fzf#vim#_buflisted_sorted(), 'bufname(v:val)'), 'len(v:val)')
    "                                                                     ^
    "                                                                     cursor position
    "
    " Press `=rl`:  the refactoring fails.
    " This is not a big issue though.  We should first refactor this line to get
    " rid of the nesting, using the `->` method token:
    "
    "     map(fzf#vim#_buflisted_sorted(), 'bufname(v:val)')->filter('len(v:val)')
    "
    " Then, the current logic is correct, and `=rl` works as expected.
    "}}}
    if !vim#util#search('\m\C\<\%(map\|filter\)(', 'be') | return 0 | endif
    let pos = getcurpos()
    norm! %
    if getcurpos() == pos | return 0 | endif
    return search('["'']', 'bW')
endfu

def s:SearchOpeningQuote(): number #{{{2
    var char = getline('.')->strpart(col('.') - 1)[0]
    var pat = char == '"' ? '\\\@1<!"' : "'\\@1<!''\\@!"
    return search(pat, 'bW')
enddef

fu s:get_expr(captured_text) abort "{{{2
    let expr = a:captured_text
    let quote = expr[-1 : -1]
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

