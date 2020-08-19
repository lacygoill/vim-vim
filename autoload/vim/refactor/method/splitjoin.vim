if exists('g:autoloaded_vim#refactor#method#splitjoin')
    finish
endif
let g:autoloaded_vim#refactor#method#splitjoin = 1

const s:ARROW_PAT = '\S\zs\ze\%\({\s*\%(\%\(\S\+\s*,\)\=\s*\S\+\)\=\s*\)\@<!->\a'

" Interface {{{1
fu vim#refactor#method#splitjoin#main(...) abort "{{{2
    if !a:0
        let &opfunc = 'vim#refactor#method#splitjoin#main'
        return 'g@l'
    endif
    let range = s:get_range()
    if !s:is_valid(range)
        return
    endif
    if s:should_split(range)
        call s:split(range)
    else
        call s:join()
    endif
    norm! `[
endfu
"}}}1
" Core {{{1
fu s:split(range) abort "{{{2
    let [lnum1, lnum2] = a:range
    let indent = getline('.')->matchstr('^\s*')
    let rep = "\x01" .. indent .. repeat(' ', &l:sw) .. (s:isvim9() ? '' : '\\ ')
    let new = getline(lnum1, lnum2)
        \ ->map({_, v -> substitute(v, s:ARROW_PAT, rep, 'g')->split("\x01")})
        \ ->flatten()
        \ ->join("\n")
    call vim#util#put(
        \ new,
        \ lnum1, 1,
        \ lnum2, 1,
        \ v:true
        \ )
endfu

fu s:join() abort "{{{2
    let isvim9 = s:isvim9()
    let pat = '^\s*' .. (isvim9 ? '' : '\\\s*') .. '->\a'
    call search('^\%(\s*' .. (isvim9 ? '' : '\\\s*') .. '->\a\)\@!', 'bcW')
    let lastlnum = search(pat .. '.*\n\%(' .. pat .. '\)\@!', 'cnW')
    if isvim9
        let range = '.+,' .. lastlnum
        exe range .. 's/^\s*//'
    else
        let range = '.+,' .. lastlnum
        exe range .. 's/^\s*\\\s*//'
    endif
    '[-,']j!
endfu
"}}}1
" Utilities {{{1
fu s:get_range() abort "{{{2
    if s:isvim9()
        let patfirst = '^\%(\s*->\a\)\@!.*\n\s*->\a'
        let patlast = '^\s*->\a.*\n\%(\s*->\a\)\@!'
    else
        let patfirst = '^\%(\s*\\\s*->\a\)\@!.*\n\s*\\\s*->\a'
        let patlast = '^\s*\\\s*->\a.*\n\%(\s*\\\s*->\a\)\@!'
    endif
    let firstlnum = search(patfirst, 'bcnW')
    let lastlnum = search(patlast, 'cnW')
    if firstlnum == 0 || lastlnum == 0
        if search(s:ARROW_PAT, 'nW', line('.'))
            return [line('.'), line('.')]
        else
            return []
        endif
    endif
    return [firstlnum, lastlnum]
endfu

fu s:is_valid(lnums) abort "{{{2
    if empty(a:lnums)
        return 0
    endif
    " a valid range must not contain an empty line
    let [lnum1, lnum2] = a:lnums
    let curpos = getcurpos()
    call cursor(lnum1, 1)
    let has_emptyline = search('^\s*$', 'nW', lnum2)
    call setpos('.', curpos)
    return !has_emptyline
endfu

fu s:should_split(range) abort "{{{2
    " we should split iff we can find 2 `->` method calls on the same line inside the range
    let [lnum1, lnum2] = a:range
    let curpos = getcurpos()
    call cursor(lnum1, 1)
    let result = search(s:ARROW_PAT .. '.*' .. s:ARROW_PAT, 'nW', lnum2)
    call setpos('.', curpos)
    return result
endfu

fu s:isvim9() abort "{{{2
    return getline(1) is# 'vim9script'
        \ || searchpair('^\C\s*\<def\>', '', '^\C\s*\<enddef\>$', 'nW')
endfu

