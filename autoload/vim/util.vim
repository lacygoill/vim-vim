" Interface {{{1
fu vim#util#search(pat, flags = '', syntomatch = '') abort "{{{2
    let [g, s] = [0, 1]
    let syntax_was_enabled = exists('g:syntax_on')
    try
        if !syntax_was_enabled
            call s:warn('enabling syntax to search pattern; might take some time...')
            syn enable
        endif
        return search(a:pat, a:flags .. 'W' .. (g == 0 ? 'c' : ''),
            \ 0, 0, function('s:skip', [a:syntomatch]))
    finally
        if !syntax_was_enabled | syn off | endif
    endtry
endfu

fu s:skip(syntomatch) abort
    let syngroup = synstack('.', col('.'))->map({_, v -> synIDattr(v, 'name')})->get(-1, '')
    if syngroup is# 'vimString'
        return v:true
    endif
    return a:syntomatch != '' && syngroup !~# '\C^\%(' .. a:syntomatch .. '\)$'
endfu

fu vim#util#we_can_refactor(...) abort "{{{2
    let [
        \ search_results,
        \ lnum1, col1,
        \ lnum2, col2,
        \ bang,
        \ view,
        \ this, into_that
        \ ] = a:000

    let [lnum0, col0] = [view.lnum, view.col]
    let l:Finish = function('s:finish', [view])

    " Why `call()`?{{{
    "
    " To avoid repeating the same arguments in several function calls.
    "}}}
    let args = [lnum1, col1, lnum2, col2]
    if index(search_results, 0) >= 0
    \ || !call('s:contains_pos', [lnum0, col0] + args)
    \ || s:contains_empty_or_commented_line(lnum1, lnum2)
        return l:Finish(this .. ' not found')
    elseif !bang && call('s:confirm', ['refactor into ' .. into_that] + args) isnot# 'y'
        return l:Finish()
    else
        return 1
    endif
endfu

fu vim#util#put(...) abort "{{{2
    let [text, lnum1, col1, lnum2, col2; linewise] = a:000
    let [cb_save, sel_save] = [&cb, &sel]
    let reg_save = getreginfo('"')
    try
        set cb= sel=inclusive
        if type(text) == v:t_list
            let @" = join(text, "\n")
        else
            let @" = text
        endif
        call setpos('.', [0, lnum1, col1, 0])
        exe 'norm!' .. (!empty(linewise) ? 'V' : 'v')
        call setpos('.', [0, lnum2, col2, 0])
        norm! p
    finally
        let [&cb, &sel] = [cb_save, sel_save]
        call setreg('"', reg_save)
    endtry
endfu
"}}}1
" Utilities {{{1
fu s:warn(msg) abort "{{{2
    " Sometimes, enabling syntax highlighting takes a few seconds.
    echohl WarningMsg
    echo a:msg
    echohl NONE
endfu

fu s:contains_pos(...) abort "{{{2
    " return 1 iff the position `[lnum0, col0]` is somewhere inside the
    " characterwise text starting at `[lnum1, col1]` and ending at `[lnum2, col2]`
    let [lnum0, col0, lnum1, col1, lnum2, col2] = a:000
    if lnum0 == lnum1 && lnum0 == lnum2
        return col0 >= (col1 - 1) && col0 <= (col2 - 1)
    else
        return (lnum0 > lnum1 && lnum0 < lnum2)
            \ || (lnum0 == lnum1 && col0 >= (col1 - 1))
            \ || (lnum0 == lnum2 && col0 <= (col2 - 1))
    endif
endfu

fu s:contains_empty_or_commented_line(lnum1, lnum2) abort "{{{2
    let lines = getline(a:lnum1, a:lnum2)
    return match(lines, '^\s*"\%(\\ \)\@!\|^\s*$') != -1
endfu

fu s:finish(view, ...) abort "{{{2
    " Why `winrestview()` instead of `cursor()`?{{{
    "
    " Restoring the cursor position does not the guarantee that the view will be
    " preserved.  I want it preserved.
    "}}}
    " Why restoring the view *before* echo'ing the message?{{{
    "
    " If the view changes, the screen will be redrawn.
    " And if the screen is redrawn, the message on the command-line may be erased.
    " That should not happen since we use `winrestview()`, but better be safe.
    "}}}
    call winrestview(a:view)
    " Without, the message is  erased if no list assignment is  found and if the
    " syntax is disabled.
    redraw
    if a:0 && a:1 != ''
        echohl ErrorMsg
        echo a:1
        echohl NONE
    endif
    return 0
endfu

fu s:confirm(msg, ...) abort "{{{2
    let [lnum1, col1, lnum2, col2] = a:000
    let fen_save = &l:fen
    let pat = '\%' .. lnum1 .. 'l\%' .. col1 .. 'c\_.*\%' .. lnum2 .. 'l\%' .. col2 .. 'c.'
    let id = matchadd('IncSearch', pat, 0)
    try
        setl nofen
        echohl Question
        redraw | echo a:msg .. ' (y/n)?'
        echohl NONE
        let answer = ''
        while index(['y', 'n', "\e"], answer) == -1
            let answer = getchar()->nr2char()
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

