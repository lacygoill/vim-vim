vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Interface {{{1
def vim#refactor#heredoc#main( #{{{2
    type: any = '',
    arg = '',
): string

    if typename(type) == 'string' && type == ''
        &opfunc = 'vim#refactor#heredoc#main'
        return 'g@l'
    endif
    var view: dict<number> = winsaveview()

    var bang: bool
    # opfunc
    if typename(type) == 'string' && type != ''
        bang = true
    # Ex cmd
    else
        bang = type
    endif

    var notrim: bool
    var marker: string
    if match(arg, '-help\>') >= 0
        PrintHelp()
        return ''
    elseif !SyntaxIsCorrect(arg)
        Error('invalid syntax, run `:RefHeredoc -help` for more info')
        return ''
    else
        [notrim, marker] = GetArgs(arg)
        if marker == ''
            Error('invalid marker')
            return ''
        endif
    endif

    var s1: number = SearchLet()
    var lnum1: number
    var col1: number
    [lnum1, col1] = getcurpos()[1 : 2]

    var s2: number = SearchOpeningBracket()
    var lnum2: number
    var col2: number
    [lnum2, col2] = getcurpos()[1 : 2]

    var s3: number = SearchClosingBracket()
    var lnum3: number
    var col3: number
    [lnum3, col3] = getcurpos()[1 : 2]

    if !vim#util#weCanRefactor(
        [s1, s2, s3],
        lnum1, col1,
        lnum3, col3,
        bang,
        view,
        'list assignment', 'heredoc',
    )
        return ''
    endif

    var indent: string = getline(lnum2)->matchstr('^\s*')
    BreakBar(lnum3, indent)

    var items: list<string> = GetItems(lnum1, lnum3)
    var new_assignment: list<string> = GetNewAssignment(items, notrim, marker, indent)
    vim#util#put(
        new_assignment,
        lnum2, col2,
        lnum3, col3,
    )

    winrestview(view)
    return ''
enddef

def vim#refactor#heredoc#complete(_, _, _): string #{{{2
    return ['-help', '-notrim']->join("\n")
enddef
#}}}1
# Core {{{1
def PrintHelp() #{{{2
    var help: list<string> =<< trim END
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
    echo help->join("\n")
enddef

def SyntaxIsCorrect(arg: string): bool #{{{2
    return arg =~ '^\%(' .. '\%(-notrim\)\=\|\S\+\|-notrim\s\+\S\+' .. '\)$'
enddef

def Error(msg: string) #{{{2
    echohl ErrorMsg
    echom msg
    echohl NONE
enddef

def GetArgs(cmdarg: string): list<any> #{{{2
    var notrim: bool = stridx(cmdarg, '-notrim') >= 0
    var marker: string = cmdarg
        ->substitute('\C-\%(help\|notrim\)', '', 'g')
        ->matchstr('\S\+\s*$')
    if marker == ''
        marker = 'END'
    elseif marker !~ '\L\S*'
        marker = ''
    endif
    return [notrim, marker]
enddef

def SearchLet(): number #{{{2
    return vim#util#search('\C\<\%(let\|var\|const\=\)\>', 'b', 'vimLet')
enddef

def SearchOpeningBracket(): number #{{{2
    return vim#util#search('=[ \t\n\\]*\[')
enddef

def SearchClosingBracket(): number #{{{2
    var s: number = vim#util#search('=[ \t\n\\]*\[', 'e')
    if s > 0
        norm! %
    endif
    return s
enddef

def BreakBar(lnum: number, indent: string) #{{{2
    # The list assignment may be followed by a bar and another command:{{{
    #
    #     var list = ['a', 'b', 'c'] | echo 'some other command'
    #
    # in which case, it needs to be on a separate line:
    #
    #     var list = ['a', 'b', 'c']
    #     echo 'some other command'
    #
    # otherwise, the refactoring would give:
    #
    #     var list =<< trim END
    #         a
    #         b
    #         c
    #     END | echo 'some other command'
    #
    # and what follows the bar would interfere when Vim looks for the `END` marker.
    #}}}
    exe 'keepj keepp :' .. lnum .. 's/\s*|\s*/\r' .. indent .. '/e'
enddef

def GetItems(lnum1: number, lnum3: number): list<string> #{{{2
    var lines: list<string> = getline(lnum1, lnum3)
        # remove possible comments inside the list (`:h line-continuation-comment`)
        ->filter((_, v: string): bool => v !~ '^\s*"\\ ')
    var list_value: string = join(lines)
    var pat: string = '[,[]\s*\\\=\s*\([''"]\)\zs.\{-}\ze\1\s*\\\=[,\]]'
    var items: list<string>
    var Item: func = (m: list<string>): string =>
        m[1] == "'"
        ?     m[0]->substitute("''", "'", 'g')
        :     eval('"' .. m[0] .. '"')
    var Rep: func = (m: list<string>) => add(items, Item(m))[0]
    list_value->substitute(pat, Rep, 'g')
    return items
        ->map((_, v: string): string =>
                  v != ''
                ?     repeat(' ', shiftwidth()) .. v
                :     v
        )
enddef

def GetNewAssignment( #{{{2
    items: list<string>,
    notrim: bool,
    marker: string,
    indent: string
): list<string>

    var assignment: list<string> =
        [printf('=<< %s%s', notrim ? '' : 'trim ', marker)]
        + items
        + [marker]
    assignment
        ->map((i: number, v: string): string =>
            i == 0 || v == ''
            ?     v
            :     indent .. v
        )
    if notrim
        assignment->map((_, v: string): string => v->trim(" \t"))
    endif
    return assignment
enddef

