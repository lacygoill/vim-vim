if exists('g:autoloaded_vim#refactor#bar')
    finish
endif
let g:autoloaded_vim#refactor#bar = 1

" Init {{{1

let s:PAT_BAR = [
    "\ outside a single-quoted string
    \ '\%(^\%(''[^'']*''\|[^'']\)*\)\@<=',
    "\ outside a double-quoted string
    \ '\%(^\%("[^"]*"\|[^"]\)*\)\@<=',
    "\ not on a commented line
    \ '\%(^\s*".*\)\@<!',
    "\ a bar (!= `||`)
    \ '\s*|\@1<!||\@!\s*',
    \ ]
let s:PAT_BAR = join(s:PAT_BAR, '') | lockvar! s:PAT_BAR
const s:MAX_JOINED_LINES = 5

" Interface {{{1
fu vim#refactor#bar#main(...) abort "{{{2
    if !a:0
        let &opfunc = 'vim#refactor#bar#main'
        return 'g@l'
    endif

    let line = getline('.')
    if line =~# '^\s*"' | return | endif
    let pos = getcurpos()


    " opfunc
    if a:0 == 1 && type(a:1) == v:t_string
        let [bang, arg] = [v:true, '']
    " Ex cmd, 1 argument
    elseif a:0 == 1 && type(a:1) == v:t_number
        let [bang, arg] = [a:1, '']
    " Ex cmd, 2 arguments
    else
        let [bang, arg] = [a:1, a:2]
    endif

    try
        if arg isnot# ''
            call s:{arg[1:]}(bang)
        else
            if line =~# s:PAT_BAR
                call s:break(bang)
            else
                call s:join(bang)
            endif
        endif
    catch
        return lg#catch()
    finally
        call setpos('.', pos)
    endtry
endfu

fu vim#refactor#bar#complete(_a, _l, _p) abort "{{{2
    return join(['-break', '-join'], "\n")
endfu
"}}}1
" Core {{{1
fu s:break(bang) abort "{{{2
    let lnum = line('.')
    if !s:we_can_refactor(lnum, lnum, a:bang, 'break') | return | endif
    let line = getline('.')
    let word = matchstr(line, '^\s*\zs\w\+')
    let word = s:normalize(word)
    if index(['if', 'elseif', 'try'], word) != -1
        " Perform this transformation:{{{
        "
        "     if 1 | echo 'true' | endif
        "
        "     →
        "
        "     if 1
        "         echo 'true'
        "     endif
        "}}}
        exe 'keepj keepp s/'..s:PAT_BAR..'/\r/ge'
    elseif word =~# '^\Cau\%[tocmd]$'
        " Perform this transformation:{{{
        "
        "     au User test if 1 | echo 'do sth' | endif
        "
        "     →
        "
        "     au User test if 1
        "     \ | echo 'do sth'
        "     \ | endif
        "}}}
        sil exe 'keepj keepp s/'..s:PAT_BAR..'/\="\r\\ | "/ge'
    else
        return
    endif
    let range = (line("'[")+1)..','..line("']")
    exe range..'norm! =='
endfu

fu s:join(bang) abort "{{{2
    let line = getline('.')
    let word = matchstr(line, '^\s*\zs\w\+')
    let word = s:normalize(word)
    if index(['au', 'if', 'try'], word) == -1 || line =~# '\C\send\%(if\|try\)\s*$'
        return
    endif
    let mods = 'keepj keepp'
    let lnum1 = line('.')
    " Perform this transformation:{{{
    "
    "     if 1
    "         echo 'true'
    "     endif
    "
    "     →
    "
    "     if 1 | echo 'true' | endif
    "}}}
    if word is# 'if' || word is# 'try'
        let lnum2 = search('^\s*\Cend\%(if\|try\)\s*$', 'nW')
        " if too many lines are going to be joined, it's probably an error; bail out
        if lnum2 - lnum1 + 1 > s:MAX_JOINED_LINES | return | endif
        if !s:we_can_refactor(lnum1, lnum2, a:bang, 'join') | return | endif
        let range = lnum1..','..lnum2
        exe mods..' '..range..'-s/$/ |/'
    " Perform this transformation:{{{
    "
    "     au User test if 1
    "     \ | do sth
    "     \ | endif
    "
    "     →
    "
    "     au User test if 1 | do sth | endif
        "}}}
    elseif word is# 'au'
        let lnum2 = search('^\s*\\\s*|\s*\Cend\%(if\|try\)\s*$', 'nW')
        if lnum2 - lnum1 + 1 > s:MAX_JOINED_LINES | return | endif
        if !s:we_can_refactor(lnum1, lnum2, a:bang, 'join') | return | endif
        let range = lnum1..','..lnum2
        exe mods..' '..range..'-s/$/ |/'
        exe mods..' '..range..'s/^\s*\\\s*|\s*//'
    endif
    exe mods..' '..range..'j'
endfu
"}}}1
" Utilities {{{1
fu s:normalize(word) abort "{{{2
    let word = a:word
    if word =~# '^\Cau\%[tocmd]$' | let word = 'au' | endif
    return word
endfu

fu s:we_can_refactor(lnum1, lnum2, bang, change) abort "{{{2
    " first non-whitespace on first line
    let pat1 = '^\%'..a:lnum1..'l\s*\zs\S'
    " last non-whitespace on last line
    let pat2 = '\%'..a:lnum2..'l\S\s*$'
    let view = winsaveview()
    let s1 = search(pat1, 'bc') | let [lnum1, col1] = getcurpos()[1:2]
    let s2 = search(pat2, 'c') | let [lnum2, col2] = getcurpos()[1:2]
    if !vim#util#we_can_refactor(
       \ [s1, s2],
       \ lnum1, col1,
       \ lnum2, col2,
       \ a:bang,
       \ view,
       \ a:change is# 'break' ? 'bar-separated commands' : 'multiline block',
       \ a:change is# 'break' ? 'multiline block' : 'bar-separated commands',
       \ ) | return 0 | endif
    return 1
endfu

