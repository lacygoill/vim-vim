vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

# the negative lookbehind tries  to prevent a match when the arrow  is used in a
# legacy lambda
const ARROW_PAT: string = '\S\zs\ze\%({\s*\%(\%(\S\+\s*,\)\=\s*\S\+\)\=\s*\)\@<!->\a'

import IsVim9 from 'lg.vim'

# Interface {{{1
def vim#refactor#method#splitjoin#main(type = ''): string #{{{2
    if type == ''
        &opfunc = 'vim#refactor#method#splitjoin#main'
        return 'g@l'
    endif
    var range: list<number> = GetRange()
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
    var lnum1: number = range[0]
    var lnum2: number = range[1]
    var indent: string = getline('.')->matchstr('^\s*')
    var rep: string = "\x01" .. indent .. repeat(' ', &l:sw) .. (IsVim9() ? '' : '\\ ')
    var new: string = getline(lnum1, lnum2)
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
    var isvim9: bool = IsVim9()
    var pat: string = '^\s*' .. (isvim9 ? '' : '\\\s*') .. '->\a'
    search('^\%(\s*' .. (isvim9 ? '' : '\\\s*') .. '->\a\)\@!', 'bcW')
    var lastlnum: number = search(pat .. '.*\n\%(' .. pat .. '\)\@!', 'cnW')
    if isvim9
        var range: string = ':.+,' .. lastlnum
        exe range .. 's/^\s*//'
    else
        var range: string = ':.+,' .. lastlnum
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
    var firstlnum: number = search(patfirst, 'bcnW')
    var lastlnum: number = search(patlast, 'cnW')
    if firstlnum == 0 || lastlnum == 0
        if getline('.')->match(ARROW_PAT) >= 0
            var curlnum: number = line('.')
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
    var lnum1: number = lnums[0]
    var lnum2: number = lnums[1]
    var curpos: list<number> = getcurpos()
    cursor(lnum1, 1)
    var has_emptyline: bool = search('^\s*$', 'nW', lnum2) != 0
    setpos('.', curpos)
    return !has_emptyline
enddef

def ShouldSplit(range: list<number>): bool #{{{2
    # we should split iff we can find 2 `->` method calls on the same line inside the range
    var lnum1: number = range[0]
    var lnum2: number = range[1]
    var curpos: list<number> = getcurpos()
    cursor(lnum1, 1)
    var result: number = search(ARROW_PAT, 'nW', lnum2)
    setpos('.', curpos)
    return result > 0
enddef

