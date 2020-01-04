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
fu vim#refactor#bar#main(bang, ...) abort "{{{2
    let line = getline('.')
    if line =~# '^\s*"' | return | endif
    let pos = getcurpos()
    if a:0 | let arg = a:1 | else | let arg = '' | endif
    try
        if arg isnot# ''
            call s:{arg[1:]}()
        else
            if line =~# s:PAT_BAR
                call s:break()
            else
                call s:join()
            endif
        endif
    catch
        return lg#catch_error()
    finally
        call setpos('.', pos)
    endtry
endfu

fu vim#refactor#bar#complete(_a, _l, _p) abort "{{{2
    return join(['-break', '-join'], "\n")
endfu
"}}}1
" Core {{{1
fu s:break() abort "{{{2
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

fu s:join() abort "{{{2
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

