" Interface {{{1
fu vim#refactor#ternary#main(lnum1,lnum2) abort "{{{2
    call search('^\s*\<\%(let\|var\|const\|return\)\>', 'cW', a:lnum2)
    let kwd = getline('.')->matchstr('let\|var\|const\|return')
    if kwd == '' | return | endif
    let expr = getline('.')->matchstr({
        \ 'let': '\m\Clet\s\+\zs.\{-}\ze\s*=',
        \ 'var': '\m\Cvar\s\+\zs.\{-}\ze\s*=',
        \ 'const': '\m\Cconst\s\+\zs.\{-}\ze\s*=',
        \ 'return': '\m\Creturn\s\+\zs.*',
        \ }[kwd])

    let tests = s:get_tests_or_values(a:lnum1, a:lnum2,
        \ '\<if\>',
        \ '\<if\>\s\+\zs.*',
        \ '\<\%(else\|elseif\)\>',
        \ '\<\%(else\|elseif\)\>\s\+\zs.*')

    let values = s:get_tests_or_values(a:lnum1, a:lnum2,
        \ '\<' .. kwd .. '\>',
        \ '\<' .. kwd .. '\>\s\+' .. (kwd isnot# 'return' ? '.\{-}=\s*' : '') .. '\zs.*',
        \ '\<' .. kwd .. '\>',
        \ '\<' .. kwd .. '\>\s\+' .. (kwd isnot# 'return' ? '.\{-}=\s*' : '') .. '\zs.*')

    if empty(tests) || tests ==# [''] || values ==# [''] || len(tests) > len(values)
        return
    endif

    let assignment = [kwd .. ' ' .. (kwd is# 'let' || kwd is# 'var' ? expr .. ' = ' : '')]
    let assignment[0] ..= tests[0]

    " The function should not operate on something like this:{{{
    "
    "     if condition1
    "         let var = 1
    "     elseif condition2
    "         let var = 2
    "     endif
    "
    " A conditional operator `?:` operate on ALL possible cases.
    " Same thing for a combination of multiple `?:`.
    " So, you can't express the previous `if` block with `?:`
    " Because the latter does NOT cover ALL cases.
    " It doesn't cover the cases where condition1 and condition2
    " are false.
    "}}}
    let n_values = len(values)
    let n_tests = len(tests)
    if n_tests == n_values | return | endif

    for i in range(1, n_tests-1)
        let assignment += ['    \ ?     ' .. values[i-1]]
                      \ + ['    \ : ' .. tests[i]]
    endfor
    let assignment += ['    \ ?     ' .. values[-2],
                     \ '    \ :     ' .. values[-1]]
    " Don't forget the space between `\` and `?`, as well as `\` and `:`!{{{
    " Without the space, you may have an error.
    " MWE:
    "
    "         echo map(['foo'], {_, v -> 1
    "             \? v
    "             \: v
    "             \ })
            "}}}

    " make sure our new block is indented like the original one
    let indent_block = getline(a:lnum1)->matchstr('^\s*')
    call map(assignment, {_, v -> indent_block .. v})

    let reg_save = getreginfo('"')
    let @" = join(assignment, "\n")
    try
        exe 'norm! ' .. a:lnum1 .. 'G' .. 'V' .. a:lnum2 .. 'Gp'
    finally
        call setreg('"', reg_save)
    endtry
endfu
"}}}1
" Core {{{1
fu s:get_tests_or_values(lnum1, lnum2, pat1, pat2, pat3, pat4) abort "{{{2
    call cursor(a:lnum1, 1)
    let expressions = [search(a:pat1, 'cW', a:lnum2)->getline()->matchstr(a:pat2)]
    let guard = 0
    while search(a:pat3, 'W', a:lnum2) && guard <= 30
        let expressions += [getline('.')->matchstr(a:pat4)]
        let guard += 1
    endwhile
    return filter(expressions, {_, v -> v != ''})
endfu

