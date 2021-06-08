vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

import IsVim9 from 'lg.vim'

# TODO: add support for some not-too-complex ranges
# Update: Nope.  It's too slow.
# Try to replace `foo` with `bar` in our vimrc.  It's about 20 times slower with
# `setline()`+`substitute()`+`getline()`+`map()`, compared to `:s`.
const PAT: string =
    # the substitution could be in a sequence of commands separated by bars
    '\C^\%(.*|\)\='
    # modifiers
    .. '\s*\zs\%(\%(sil\%[ent]!\=\|keepj\%[umps]\|keepp\%[atterns]\)\s*\)\{,3}'
    # range
    .. '\(-\=\)'
    # command
    .. 's\(\i\@!.\)\(.\{-}\)\2\(.\{-}\)\2\([gcen]\{,4}\)$'

# Interface {{{1
def vim#refactor#substitute#main(type: any = ''): string #{{{2
    if typename(type) == 'string' && type == ''
        &operatorfunc = 'vim#refactor#substitute#main'
        return 'g@l'
    endif
    var view: dict<number> = winsaveview()

    var s1: number = SearchSubstitutionStart()
    var lnum1: number
    var col1: number
    [lnum1, col1] = getcurpos()[1 : 2]

    var s2: number = SearchSubstitutionEnd()
    var lnum2: number
    var col2: number
    [lnum2, col2] = getcurpos()[1 : 2]

    var bang: bool
    if typename(type) == 'bool'
        bang = type
    else
        bang = true
    endif

    if !vim#util#weCanRefactor(
        [s1, s2],
        lnum1, col1,
        lnum2, col2,
        bang,
        view,
        'substitution command', 'setline()+substitute()',
    )
        return ''
    endif

    var old: string = GetOldSubstitution(lnum1)
    var new: string = GetNewSubstitution(old)

    vim#util#put(
        new,
        lnum1, col1,
        lnum2, col2,
    )

    winrestview(view)
    return ''
enddef
#}}}1
# Core {{{1
def SearchSubstitutionStart(): number #{{{2
    # TODO: Should we pass the `c` flag?
    # Should we pass it when searching the end of the command too?
    # Did we forget to pass it in other refactoring functions?
    return vim#util#search(PAT, 'b')
enddef

def SearchSubstitutionEnd(): number #{{{2
    return vim#util#search(PAT, 'e')
enddef

def GetOldSubstitution(lnum: number): string #{{{2
    return getline(lnum)->matchstr(PAT)
enddef

def GetNewSubstitution(old: string): string #{{{2
    var range: string
    var pat: string
    var rep: string
    var flags: string
    [range, _, pat, rep, flags] = matchlist(old, PAT)[1 : 5]
    flags = flags->substitute('e', '', '')
    # TODO: support case where pattern or replacement contains a single quote
    # TODO: make sure `&`, `~` and `\` are always escaped in the replacement
    # TODO: use the  method  call  operator to  refactor  the new  substitution
    # command to make it more readable; make sure to update the tests
    var lnum: string = {'': "'.'", '-': "line('.') - 1"}[range]
    var format: string = (IsVim9() ? '' : 'call ')
        .. "getline(%s)->substitute('%s', '%s', '%s')->setline(%s)"
    var new: string = printf(format, lnum, pat, rep, flags, lnum)
    return new
enddef

