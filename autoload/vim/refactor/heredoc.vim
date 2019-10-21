" Interface {{{1
fu vim#refactor#heredoc#main(bang, ...) abort "{{{2
    let view = winsaveview()
    let s:finish = function('s:error', [view])
    if index(a:000, '-help') >= 0
        return s:print_help()
    elseif ! s:syntax_is_correct(a:000)
        return s:finish('invalid syntax, run `:RefHeredoc -help` for more info')
    else
        let [notrim, marker] = s:get_args(a:000)
        if marker is# '' | return s:finish('invalid marker') | endif
    endif

    let s1 = s:search_let()
    let [lnum1, col1] = [line('.'), col('.')]
    let s2 = search('=[ \t\n\\]*\[', 'W')
    let [lnum2, col2] = [line('.'), col('.')]
    let s3 = search('=[ \t\n\\]*\[', 'eW') | norm! %
    let [lnum3, col3] = [line('.'), col('.')]

    let args = [lnum1, lnum3, col1, col3, view]
    if index([s1, s2, s3], 0) >= 0
    \ || ! call('s:contains_original_line', args)
    \ || s:contains_empty_or_commented_line(lnum1, lnum3)
        return s:finish('list assignment not found')
    elseif ! a:bang && call('s:confirm', args) isnot# 'y'
        return s:finish('')
    endif

    let indent = matchstr(getline(lnum2), '^\s*')
    " the assignment may be followed by a bar and another command
    " it needs to be on a separate line to not interfere when Vim looks for the end marker
    exe 'keepj keepp '..lnum3..'s/\s*|\s*/\r'..indent..'/e'
    let items = s:get_items(lnum1, lnum3)
    let args = [items, notrim, marker, indent]
    let new_assignment = call('s:get_new_assignment', args)
    let args = [new_assignment, lnum2, col2, lnum3, col3]
    call call('s:put', args)
    call winrestview(view)
endfu

fu vim#refactor#heredoc#complete(_a, _l, _p) abort "{{{2
    return join(['-help', '-notrim'], "\n")
endfu
"}}}1
" Core {{{1
fu s:print_help() abort "{{{2
    let help =<< trim END
        Usage: RefHeredoc[!] [-help] [-notrim] [marker]
        Refactor current list assignment into a heredoc (see `:h :let-heredoc`).

          -help    print this help
          -notrim  do not write the optional trim argument
          !        refactor without asking for confirmation

        Examples:

          RefHeredoc
          RefHeredoc -notrim
          RefHeredoc MyCustomMarker
          RefHeredoc! -notrim MyCustomMarker
    END
    echo join(help, "\n")
endfu

fu s:error(view, msg) abort "{{{2
    " Why `winrestview()` instead of `cursor()`?{{{
    "
    " Restoring the cursor position does not the guarantee that the view will be
    " preserved. I want it preserved.
    "}}}
    " Why restoring the view *before* echo'ing the message?{{{
    "
    " If the view changes, the screen will be redrawn.
    " And if the screen is redrawn, the message on the command-line may be erased.
    " That should not happen since we use `winrestview()`, but better be safe.
    "}}}
    call winrestview(a:view)
    if a:msg isnot# ''
        echohl ErrorMsg
        echo 'RefHeredoc: '..a:msg
        echohl NONE
    endif
endfu

fu s:syntax_is_correct(args) abort "{{{2
    let args = join(a:args)
    return args =~# '^\%(-notrim\s*\)\=\%(\S\+\)\=$'
endfu

fu s:search_let() abort "{{{2
    let syntax_was_enabled = exists('g:syntax_on')
    try
        if ! syntax_was_enabled | syn enable | endif
        let [g, s1] = [0, 1]
        while s1 > 0 && g < 999
            let s1 = search('\<\%(let\|const\=\)\>', 'bW'..(g == 0 ? 'c' : ''))
            let synstack = synstack(line('.'), col('.'))
            let syngroup = get(map(synstack, {_,v -> synIDattr(v, 'name')}), -1, '')
            if syngroup is# 'vimLet' | break | endif
            let g += 1
        endwhile
    finally
        if ! syntax_was_enabled | syn off | endif
    endtry
    return s1
endfu

fu s:get_args(args) abort "{{{2
    let notrim = index(a:args, '-notrim') >= 0
    let args = substitute(join(a:args), '\C-\%(help\|notrim\)', '', 'g')
    let marker = matchstr(args, '\S\+\s*$')
    if marker is# ''
        let marker = 'END'
    elseif marker !~# '\L\S*'
        let marker = ''
    endif
    return [notrim, marker]
endfu

fu s:contains_original_line(...) abort "{{{2
    let [lnum1, lnum3, col1, col3, view] = a:000
    let [lnum0, col0] = [view.lnum, view.col]
    return (lnum0 > lnum1 && lnum0 < lnum3)
    \ || (lnum0 == lnum1 && col0 >= (col1 - 1))
    \ || (lnum0 == lnum3 && col0 <= (col3 - 1))
endfu

fu s:contains_empty_or_commented_line(lnum1, lnum3) abort "{{{2
    let lines = getline(a:lnum1, a:lnum3)
    return match(lines, '^\s*"\%(\\ \)\@!\|^\s*$') != -1
endfu

fu s:confirm(...) abort "{{{2
    let [lnum1, lnum3, col1, col3; rest] = a:000
    let fen_save = &l:fen
    let pat = '\%'..lnum1..'l\%'..col1..'c\_.*\%'..lnum3..'l\%'..col3..'c.'
    let id = matchadd('IncSearch', pat)
    try
        setl nofen
        echohl Question
        redraw | echo 'Refactor into heredoc (y/N)?'
        echohl NONE
        let answer = ''
        while index(['y', 'n', "\e"], answer) == -1
            let answer = nr2char(getchar())
        endwhile
        redraw!
    catch /Vim:Interrupt/
        echohl ErrorMsg | redraw | echo 'Interrupt' | echohl NONE
    finally
        let &l:fen = fen_save
        call matchdelete(id)
    endtry
    return answer
endfu

fu s:get_items(lnum1, lnum3) abort "{{{2
    let lines = getline(a:lnum1, a:lnum3)
    " remove possible comments inside the list (`:h line-continuation-comment`)
    call filter(lines, {_,v -> v !~# '^\s*"\\ '})
    let list_value = join(lines)
    let pat = '[,[]\s*\\\=\s*\([''"]\)\zs.\{-}\ze\1\s*\\\=[,\]]'
    let items = []
    let l:Item = {m -> m[1] is# "'"
    \ ? substitute(m[0], "''", "'", 'g')
    \ : eval('"'..m[0]..'"')
    \ }
    let l:Rep = {m -> add(items, l:Item(m))[0]}
    call substitute(list_value, pat, l:Rep, 'g')
    call map(items, {_,v -> v isnot# '' ? repeat(' ', &l:sw)..v : v})
    return items
endfu

fu s:get_new_assignment(...) abort "{{{2
    let [items, notrim, marker, indent] = a:000
    let assignment =
    \ [printf('=<< %s%s', notrim ? '' : 'trim ', marker)]
    \ + items
    \ + [marker]
    call map(assignment, {i,v -> i == 0 || v is# '' ? v : indent..v})
    if notrim
        call map(assignment, {_,v -> trim(v, " \t")})
    endif
    return assignment
endfu

fu s:put(...) abort "{{{2
    let [new_assignment, lnum2, col2, lnum3, col3] = a:000
    let [cb_save, sel_save] = [&cb, &sel]
    let reg_save = ['"', getreg('"'), getregtype('"')]
    try
        set cb-=unnamed cb-=unnamedplus sel=inclusive
        let @" = join(new_assignment, "\n")
        exe 'norm! '..lnum2..'G'..col2..'|v'..lnum3..'G'..col3..'|p'
    finally
        let [&cb, &sel] = [cb_save, sel_save]
        call call('setreg', reg_save)
    endtry
endfu

