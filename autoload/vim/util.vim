vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

# Interface {{{1
def vim#util#search(pat: string, flags = '', syntomatch = ''): number #{{{2
    var syntax_was_enabled: bool = exists('g:syntax_on')
    try
        if !syntax_was_enabled
            Warn('enabling syntax to search pattern; might take some time...')
            syn enable
        endif
        return search(pat, flags .. 'cW',
            0, 0, function(Skip, [syntomatch]))
    finally
        if !syntax_was_enabled
            syn off
        endif
    endtry
    return 0
enddef

def Skip(syntomatch: string): bool
    var syngroup: string = synstack('.', col('.'))
        ->mapnew((_, v) => synIDattr(v, 'name'))
        ->get(-1, '')
    if syngroup == 'vimString'
        return true
    endif
    return syntomatch != '' && syngroup !~ '\C^\%(' .. syntomatch .. '\)$'
enddef

def vim#util#weCanRefactor( #{{{2
    search_results: list<number>,
    lnum1: number, col1: number,
    lnum2: number, col2: number,
    bang: bool,
    view: dict<number>,
    this: string, into_that: string
    ): bool

    var lnum0: number = view.lnum
    var col0: number = view.col
    var FinishRef: func(?string): bool = function(Finish, [view])

    # Why `call()`?{{{
    #
    # To avoid repeating the same arguments in several function calls.
    #}}}
    var args: list<number> = [lnum1, col1, lnum2, col2]
    if index(search_results, 0) >= 0
    || !call(ContainsPos, [lnum0, col0] + args)
    || ContainsEmptyOrCommentedLine(lnum1, lnum2)
        return FinishRef(this .. ' not found')
    elseif !bang && call(Confirm, ['refactor into ' .. into_that] + args) != 'y'
        return FinishRef()
    else
        return true
    endif
enddef

def vim#util#put( #{{{2
    text: any, # TODO(Vim9): string|list<string>
    lnum1: number,
    col1: number,
    lnum2: number,
    col2: number,
    linewise = false
    )
    var cb_save: string = &cb
    var sel_save: string = &sel
    var reg_save: dict<any> = getreginfo('"')
    try
        set cb= sel=inclusive
        if typename(text) =~ '^list'
            @" = join(text, "\n")
        else
            @" = text
        endif
        setpos('.', [0, lnum1, col1, 0])
        exe 'norm!' .. (linewise ? 'V' : 'v')
        setpos('.', [0, lnum2, col2, 0])
        norm! p
    finally
        &cb = cb_save
        &sel = sel_save
        setreg('"', reg_save)
    endtry
enddef
#}}}1
# Utilities {{{1
def Warn(msg: string) #{{{2
    # Sometimes, enabling syntax highlighting takes a few seconds.
    echohl WarningMsg
    echom msg
    echohl NONE
enddef

def ContainsPos( #{{{2
    lnum0: number, col0: number,
    lnum1: number, col1: number,
    lnum2: number, col2: number,
    ): bool
    # return 1 iff the position `[lnum0, col0]` is somewhere inside the
    # characterwise text starting at `[lnum1, col1]` and ending at `[lnum2, col2]`
    if lnum0 == lnum1 && lnum0 == lnum2
        return col0 >= (col1 - 1) && col0 <= (col2 - 1)
    else
        return (lnum0 > lnum1 && lnum0 < lnum2)
            \ || (lnum0 == lnum1 && col0 >= (col1 - 1))
            \ || (lnum0 == lnum2 && col0 <= (col2 - 1))
    endif
enddef

def ContainsEmptyOrCommentedLine(lnum1: number, lnum2: number): bool #{{{2
    var lines: list<string> = getline(lnum1, lnum2)
    return match(lines, '^\s*"\%(\\ \)\@!\|^\s*$') >= 0
enddef

def Finish(view: dict<number>, msg = ''): bool #{{{2
    # Why `winrestview()` instead of `cursor()`?{{{
    #
    # Restoring the cursor position does not the guarantee that the view will be
    # preserved.  I want it preserved.
    #}}}
    # Why restoring the view *before* echo'ing the message?{{{
    #
    # If the view changes, the screen will be redrawn.
    # And if the screen is redrawn, the message on the command-line may be erased.
    # That should not happen since we use `winrestview()`, but better be safe.
    #}}}
    winrestview(view)
    # Without, the message is  erased if no list assignment is  found and if the
    # syntax is disabled.
    redraw
    if msg != ''
        echohl ErrorMsg
        echom msg
        echohl NONE
    endif
    return false
enddef

def Confirm( #{{{2
    msg: string,
    lnum1: number,
    col1: number,
    lnum2: number,
    col2: number,
    ): string
    var fen_save: bool = &l:fen
    var pat: string = '\%' .. lnum1 .. 'l\%' .. col1 .. 'c\_.*\%' .. lnum2 .. 'l\%' .. col2 .. 'c.'
    var id: number = matchadd('IncSearch', pat, 0)
    var answer: string
    try
        setl nofen
        echohl Question
        redraw | echo msg .. ' (y/n)?'
        echohl NONE
        while index(['y', 'n', "\e"], answer) == -1
            answer = getchar()->nr2char()
        endwhile
        redraw!
    catch /Vim:Interrupt/
        echohl ErrorMsg | redraw | echo 'Interrupt' | echohl NONE
    finally
        &l:fen = fen_save
        matchdelete(id)
    endtry
    return answer
enddef

