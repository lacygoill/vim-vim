vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

const ARROW_PAT = '\S\zs\ze\%\({\s*\%(\%\(\S\+\s*,\)\=\s*\S\+\)\=\s*\)\@<!->\a'

import IsVim9 from 'lg.vim'

# Interface {{{1
def vim#refactor#method#splitjoin#main(type = ''): string #{{{2
    if type == ''
        &opfunc = 'vim#refactor#method#splitjoin#main'
        return 'g@l'
    endif
    var range = GetRange()
    if !IsValid(range)
        return ''
    endif
    if ShouldSplit(range)
        Split(range)
    else
        Join()
    endif
    norm! `[
    return ''
enddef
#}}}1
# Core {{{1
def Split(range: list<number>) #{{{2
    var lnum1 = range[0]
    var lnum2 = range[1]
    var indent = getline('.')->matchstr('^\s*')
    var rep = "\x01" .. indent .. repeat(' ', &l:sw) .. (IsVim9() ? '' : '\\ ')
    var new = getline(lnum1, lnum2)
        ->map((_, v) => substitute(v, ARROW_PAT, rep, 'g')->split("\x01"))
        ->flatten()
        ->join("\n")
    vim#util#put(
        new,
        lnum1, 1,
        lnum2, 1,
        true
        )
enddef

def Join() #{{{2
    var isvim9 = IsVim9()
    var pat = '^\s*' .. (isvim9 ? '' : '\\\s*') .. '->\a'
    search('^\%(\s*' .. (isvim9 ? '' : '\\\s*') .. '->\a\)\@!', 'bcW')
    var lastlnum = search(pat .. '.*\n\%(' .. pat .. '\)\@!', 'cnW')
    if isvim9
        var range = ':.+,' .. lastlnum
        exe range .. 's/^\s*//'
    else
        var range = ':.+,' .. lastlnum
        exe range .. 's/^\s*\\\s*//'
    endif
    :'[-,']j!
enddef
#}}}1
# Utilities {{{1
def GetRange(): list<number> #{{{2
    var patfirst: string
    var patlast: string
    if IsVim9()
        patfirst = '^\%(\s*->\a\)\@!.*\n\s*->\a'
        patlast = '^\s*->\a.*\n\%(\s*->\a\)\@!'
    else
        patfirst = '^\%(\s*\\\s*->\a\)\@!.*\n\s*\\\s*->\a'
        patlast = '^\s*\\\s*->\a.*\n\%(\s*\\\s*->\a\)\@!'
    endif
    var firstlnum = search(patfirst, 'bcnW')
    var lastlnum = search(patlast, 'cnW')
    if firstlnum == 0 || lastlnum == 0
        var curlnum = line('.')
        if search(ARROW_PAT, 'nW', curlnum) > 0
            return [curlnum, curlnum]
        else
            return []
        endif
    endif
    return [firstlnum, lastlnum]
enddef

def IsValid(lnums: list<number>): bool #{{{2
    if empty(lnums)
        return false
    endif
    # a valid range must not contain an empty line
    var lnum1 = lnums[0]
    var lnum2 = lnums[1]
    var curpos = getcurpos()
    cursor(lnum1, 1)
    var has_emptyline = search('^\s*$', 'nW', lnum2)
    setpos('.', curpos)
    return !has_emptyline
enddef

def ShouldSplit(range: list<number>): bool #{{{2
    # we should split iff we can find 2 `->` method calls on the same line inside the range
    var lnum1 = range[0]
    var lnum2 = range[1]
    var curpos = getcurpos()
    cursor(lnum1, 1)
    var result = search(ARROW_PAT .. '.*' .. ARROW_PAT, 'nW', lnum2)
    setpos('.', curpos)
    return result > 0
enddef

