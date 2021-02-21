vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Interface {{{1
def vim#refactor#ternary#main(lnum1: number, lnum2: number) #{{{2
    search('^\s*\<\%(let\|var\|const\|return\)\>', 'cW', lnum2)
    var kwd: string = getline('.')->matchstr('let\|var\|const\|return')
    if kwd == ''
        return
    endif
    var expr: string = getline('.')->matchstr({
        let: '\m\Clet\s\+\zs.\{-}\ze\s*=',
        var: '\m\Cvar\s\+\zs.\{-}\ze\s*=',
        const: '\m\Cconst\s\+\zs.\{-}\ze\s*=',
        return: '\m\Creturn\s\+\zs.*',
        }[kwd])

    var tests: list<string> = GetTestsOrValues(lnum1, lnum2,
        '\<if\>',
        '\<if\>\s\+\zs.*',
        '\<\%(else\|elseif\)\>',
        '\<\%(else\|elseif\)\>\s\+\zs.*')

    var values: list<string> = GetTestsOrValues(lnum1, lnum2,
        '\<' .. kwd .. '\>',
        '\<' .. kwd .. '\>\s\+' .. (kwd != 'return' ? '.\{-}=\s*' : '') .. '\zs.*',
        '\<' .. kwd .. '\>',
        '\<' .. kwd .. '\>\s\+' .. (kwd != 'return' ? '.\{-}=\s*' : '') .. '\zs.*')

    if empty(tests) || tests == [''] || values == [''] || len(tests) > len(values)
        return
    endif

    var assignment: list<string> = [
        kwd .. ' ' .. (kwd == 'let' || kwd == 'var' ? expr .. ' = ' : '')
        ]
    # TODO(Vim9): Simplify once we can write this:{{{
    #
    #     assignment[0] ..= tests[0]
    #}}}
    assignment[0] = assignment[0] .. tests[0]

    # The function should not operate on something like this:{{{
    #
    #     if condition1
    #         var name = 1
    #     elseif condition2
    #         var name = 2
    #     endif
    #
    # A conditional operator `?:` operate on ALL possible cases.
    # Same thing for a combination of multiple `?:`.
    # So, you can't express the previous `if` block with `?:`
    # Because the latter does NOT cover ALL cases.
    # It doesn't cover the cases where condition1 and condition2
    # are false.
    #}}}
    var n_values: number = len(values)
    var n_tests: number = len(tests)
    if n_tests == n_values
        return
    endif

    for i in range(1, n_tests - 1)
        assignment += ['    \ ?     ' .. values[i - 1]]
                    + ['    \ : ' .. tests[i]]
    endfor
    assignment += ['    \ ?     ' .. values[-2],
                   '    \ :     ' .. values[-1]]
    # Don't forget the space between `\` and `?`, as well as `\` and `:`!{{{
    # Without the space, you may have an error.
    # MWE:
    #
    #         echo map(['foo'], {_, v -> 1
    #             \? v
    #             \: v
    #             \ })
            #}}}

    # make sure our new block is indented like the original one
    var indent_block: string = getline(lnum1)->matchstr('^\s*')
    map(assignment, (_, v: string): string => indent_block .. v)

    var reg_save: dict<any> = getreginfo('"')
    @" = join(assignment, "\n")
    try
        exe 'norm! ' .. lnum1 .. 'G' .. 'V' .. lnum2 .. 'Gp'
    finally
        setreg('"', reg_save)
    endtry
enddef
#}}}1
# Core {{{1
def GetTestsOrValues( #{{{2
    lnum1: number,
    lnum2: number,
    pat1: string,
    pat2: string,
    pat3: string,
    pat4: string
    ): list<string>

    cursor(lnum1, 1)
    var expressions: list<string> = [
        search(pat1, 'cW', lnum2)->getline()->matchstr(pat2)
        ]
    var guard: number = 0
    while search(pat3, 'W', lnum2) > 0 && guard <= 30
        expressions += [getline('.')->matchstr(pat4)]
        guard += 1
    endwhile
    return filter(expressions, (_, v: string): bool => v != '')
enddef

