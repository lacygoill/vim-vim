" Interface {{{1
fu vim#refactor#heredoc#main(...) abort "{{{2
    if !a:0
        let &opfunc = 'vim#refactor#heredoc#main'
        return 'g@l'
    endif
    let view = winsaveview()

    " opfunc
    if a:0 == 1 && type(a:1) == v:t_string
        let [bang, arg] = [v:true, []]
    " Ex cmd, 1 argument
    elseif a:0 == 1 && type(a:1) == v:t_number
        let [bang, arg] = [a:1, []]
    " Ex cmd, 2 arguments
    else
        let [bang, arg] = [a:1, a:2]
    endif

    if index(arg, '-help') >= 0
        return s:print_help()
    elseif !s:syntax_is_correct(arg)
        return s:error('invalid syntax, run `:RefHeredoc -help` for more info')
    else
        let [notrim, marker] = s:get_args(arg)
        if marker == '' | return s:error('invalid marker') | endif
    endif

    let s1 = s:search_let() | let [lnum1, col1] = getcurpos()[1 : 2]
    let s2 = s:search_opening_bracket() | let [lnum2, col2] = getcurpos()[1 : 2]
    let s3 = s:search_closing_bracket() | let [lnum3, col3] = getcurpos()[1 : 2]

    if !vim#util#we_can_refactor(
        \ [s1, s2, s3],
        \ lnum1, col1,
        \ lnum3, col3,
        \ bang,
        \ view,
        \ 'list assignment', 'heredoc',
        \ ) | return | endif

    let indent = getline(lnum2)->matchstr('^\s*')
    call s:break_bar(lnum3, indent)

    let items = s:get_items(lnum1, lnum3)
    let new_assignment = s:get_new_assignment(
        \ items, notrim, marker, indent)
    call vim#util#put(
        \ new_assignment,
        \ lnum2, col2,
        \ lnum3, col3,
        \ )

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

fu s:syntax_is_correct(args) abort "{{{2
    let args = join(a:args)
    return args =~# '^\%(-notrim\s*\)\=\%(\S\+\)\=$'
endfu

fu s:error(msg) abort "{{{2
    echohl ErrorMsg
    echo a:msg
    echohl NONE
endfu

fu s:get_args(args) abort "{{{2
    let notrim = index(a:args, '-notrim') >= 0
    let args = join(a:args)->substitute('\C-\%(help\|notrim\)', '', 'g')
    let marker = matchstr(args, '\S\+\s*$')
    if marker == ''
        let marker = 'END'
    elseif marker !~# '\L\S*'
        let marker = ''
    endif
    return [notrim, marker]
endfu

fu s:search_let() abort "{{{2
    return vim#util#search('\m\C\<\%(let\|var\|const\=\)\>', 'b', 'vimLet')
endfu

fu s:search_opening_bracket() abort "{{{2
    return vim#util#search('=[ \t\n\\]*\[')
endfu

fu s:search_closing_bracket() abort "{{{2
    let s = vim#util#search('=[ \t\n\\]*\[', 'e')
    if s > 0
        norm! %
    endif
    return s
endfu

fu s:break_bar(lnum, indent) abort "{{{2
    " The list assignment may be followed by a bar and another command:{{{
    "
    "     let list = ['a', 'b', 'c'] | echo 'some other command'
    "
    " in which case, it needs to be on a separate line:
    "
    "     let list = ['a', 'b', 'c']
    "     echo 'some other command'
    "
    " otherwise, the refactoring would give:
    "
    "     let list =<< trim END
    "         a
    "         b
    "         c
    "     END | echo 'some other command'
    "
    " and what follows the bar would interfere when Vim looks for the `END` marker.
    "}}}
    exe 'keepj keepp ' .. a:lnum .. 's/\s*|\s*/\r' .. a:indent .. '/e'
endfu

fu s:get_items(lnum1, lnum3) abort "{{{2
    let lines = getline(a:lnum1, a:lnum3)
    " remove possible comments inside the list (`:h line-continuation-comment`)
    call filter(lines, {_, v -> v !~# '^\s*"\\ '})
    let list_value = join(lines)
    let pat = '[,[]\s*\\\=\s*\([''"]\)\zs.\{-}\ze\1\s*\\\=[,\]]'
    let items = []
    let l:Item = {m -> m[1] is# "'"
        \ ? substitute(m[0], "''", "'", 'g')
        \ : eval('"' .. m[0] .. '"')
        \ }
    let l:Rep = {m -> add(items, Item(m))[0]}
    call substitute(list_value, pat, Rep, 'g')
    call map(items, {_, v -> v != '' ? repeat(' ', shiftwidth()) .. v : v})
    return items
endfu

fu s:get_new_assignment(...) abort "{{{2
    let [items, notrim, marker, indent] = a:000
    let assignment =
        \ [printf('=<< %s%s', notrim ? '' : 'trim ', marker)]
        \ + items
        \ + [marker]
    call map(assignment, {i, v -> i == 0 || v == '' ? v : indent .. v})
    if notrim
        call map(assignment, {_, v -> trim(v, " \t")})
    endif
    return assignment
endfu

