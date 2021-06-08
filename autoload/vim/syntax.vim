vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Config {{{1

const OPTFILE: list<string> = readfile($VIMRUNTIME .. '/doc/options.txt')

# Init {{{1

var command_names: string
var option_names: string
var term_option_names: string
var term_option_names_nonkw: string
var event_names: string
var builtin_funcnames: string

# list of functions whose names can be confused with Ex commands
# (e.g. `:eval` vs `eval()`)
var ambiguous_funcnames: list<string>
def Ambiguous()
    var cmds: list<string> = getcompletion('', 'command')
        ->filter((_, v: string): bool => v =~ '^[a-z]')
    var funcs: list<string> = getcompletion('', 'function')
        ->map((_, v: string): string => v->substitute('()\=', '', '$'))
    for func in funcs
        if cmds->index(func) != -1
            ambiguous_funcnames->add(func)
        endif
    endfor
enddef
Ambiguous()

# Functions {{{1
def vim#syntax#getBuiltinFunctionNames(only_ambiguous = false): string #{{{2
    if only_ambiguous
        return ambiguous_funcnames->join('\|')
    endif

    if builtin_funcnames != ''
        return builtin_funcnames
    else
        var builtin_funclist: list<string> = getcompletion('', 'function')
            # keep only builtin functions
            ->filter((_, v: string): bool => v[0] =~ '[a-z]' && v !~ '#')
            # remove noisy trailing parens
            ->map((_, v: string): string => v->substitute('()\=$', '', ''))
            # if a function name can also be parsed as an Ex command, remove it
            ->filter((_, v: string): bool => ambiguous_funcnames->index(v) == - 1)

        builtin_funcnames = builtin_funclist->join(' ')
    endif
    return builtin_funcnames
enddef

def vim#syntax#getCommandNames(): string #{{{2
    if command_names != ''
        return command_names
    endif
    var cmds: list<string>
    for cmd in getcompletion('', 'command')
              ->filter((_, v: string): bool => v =~ '^[a-z]')
        var len: number
        for l in strcharlen(cmd)->range()->reverse()
            if l == 0
                continue
            endif
            if cmd->slice(0, l)->fullcommand() != cmd
                len = l
                break
            endif
        endfor
        if len == cmd->strcharlen() - 1
            cmds += [cmd]
        else
            cmds += [cmd[: len] .. '[' .. cmd[len + 1 :] .. ']']
        endif
    endfor

    var deprecated: list<string> =<< trim END
        a[ppend]
        c[hange]
        i[nsert]
        k
        o[pen]
        t
    END
    var need_fix: list<string> =<< trim END
        final
        finall[y]
    END
    # `:s` is a special case.{{{
    #
    # We need it to be matched with a `:syn match` rule;
    # not with a `:syn keyword` one.
    # Otherwise, we wouldn't be able to  correctly highlight the `s:` scope in a
    # function's header; that's because a  `:syn keyword` rule has priority over
    # all `:syn match` rules, regardless of the orderin which they're installed.
    #
    # ---
    #
    # Don't worry, `:s` will be still highlighted thanks to a `:syn match` rule.
    #}}}
    # Same thing for `:g`.
    var problematic: list<string> =<< trim END
        g[lobal]
        s[ubstitute]
    END
    for cmd in deprecated + need_fix + problematic
        var i: number = cmds->index(cmd)
        if i == -1
            continue
        endif
        cmds->remove(i)
    endfor

    var missing: list<string> =<< trim END
        addd
        fina[lly]
        in
    END
    cmds += missing

    command_names = cmds->join()
    return command_names
enddef

def vim#syntax#getEventNames(): string #{{{2
    if event_names != ''
        return event_names
    else
        event_names = getcompletion('', 'event')
            ->join(' ')
    endif
    return event_names
enddef

def vim#syntax#getOptionNames(): string #{{{2
    if option_names != ''
        return option_names
    endif

    var helptags: list<string>
    eval OPTFILE
        ->join()
        ->substitute('\*''[a-z]\{2,\}''\*',
            (m: list<string>): string => !!helptags->add(m[0]) ? '' : '', 'g')

    var deprecated: list<string> =<< trim END
        *'biosk'*
        *'bioskey'*
        *'consk'*
        *'conskey'*
        *'fe'*
        *'nobiosk'*
        *'nobioskey'*
        *'noconsk'*
        *'noconskey'*
    END

    for opt in deprecated
        var i: number = helptags->index(opt)
        if i == -1
            continue
        endif
        helptags->remove(i)
    endfor

    option_names = helptags
        ->map((_, v: string): string => v->trim('*')->trim("'"))
        ->join()
    return option_names
enddef

def vim#syntax#installTerminalOptionsRules() #{{{2
    if has('vim_starting')
        # We need to  delay the installation of the rules  for terminal options,
        # because not all of them can be given by `getcompletion()` while Vim is
        # starting.
        au VimEnter * InstallTerminalOptionsRules()
    else
        InstallTerminalOptionsRules()
    endif
enddef

def InstallTerminalOptionsRules()
    var args: string = ' contained'
        .. ' nextgroup=vim9MayBeOptionScoped,vim9SetEqual'

    exe 'syn keyword vim9IsOption '
        .. GetTerminalOptionNames()
        .. args

    exe 'syn match vim9IsOption '
        .. GetTerminalOptionNames(false)
        .. args
enddef

def GetTerminalOptionNames(keyword_only = true): string
    # terminal options with only keyword characters
    if keyword_only
        if term_option_names != ''
            return term_option_names
        endif
        term_option_names = getcompletion('t_', 'option')
            ->filter((_, v: string): bool => v =~ '^t_\w\w$')
            ->join()
        return term_option_names

    # terminal options with one or several NON-keyword characters
    else

        if term_option_names_nonkw != ''
            return term_option_names_nonkw
        endif
        var opts: list<string> = getcompletion('t_', 'option')
            ->filter((_, v: string): bool => v =~ '\W')
        term_option_names_nonkw = '/\V' .. opts->join('\|') .. '/'
        return term_option_names_nonkw
    endif
enddef

