vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

const OPTFILE: list<string> = readfile($VIMRUNTIME .. '/doc/options.txt')

var command_names: string
var option_names: string
var term_option_names: string
var term_option_names_nonkw: string
var event_names: string
var builtin_funcnames: string

def vim#syntax#tweakCluster( #{{{1
    acluster: string,
    group: string,
    action = 'include'
)
    var cluster: string = acluster->substitute('^@', '', '')
    cluster = execute('syn list @' .. cluster)
        ->split('\n')
        ->filter((_, v: string): bool => v =~ '^' .. cluster)[0]
    var cmd: string = 'syn cluster '
        .. cluster
            ->substitute('cluster=', 'contains=', '')
            ->substitute('\s*$', '', '')
    if action == 'include'
        cmd ..= ',' .. group
    elseif action == 'exclude'
        cmd = cmd
            ->substitute(
                # pattern matching the group to remove be it:{{{
                #
                #  - in the middle of the cluster
                #  - at the start of the cluster
                #  - in the end of the cluster
                #
                #}}}
                printf(',%s\|=\zs%s,\|,%s$', group, group, group),
                '', 'g')
    endif
    exe cmd
enddef

def vim#syntax#getCommandNames(): string #{{{1
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
    for cmd in deprecated + need_fix
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

def vim#syntax#getOptionNames(): string #{{{1
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

def vim#syntax#getTerminalOptionNames(keyword_only = true): string #{{{1
    if keyword_only
        if term_option_names != ''
            return term_option_names
        endif
        term_option_names = getcompletion("'t_", 'help')
            ->map((_, v: string): string => v->trim("'"))
            ->filter((_, v: string): bool => v =~ '^t_\w\w$')
            ->join()
        return term_option_names

    else

        if term_option_names_nonkw != ''
            return term_option_names_nonkw
        endif
        var opts: list<string> = getcompletion("'t_", 'help')
            ->map((_, v: string): string => v->trim("'"))
            ->filter((_, v: string): bool => v =~ '\W')
            + ['t_*7']
        term_option_names_nonkw = '/' .. opts->join('\|') .. '/'
        return term_option_names_nonkw
    endif
enddef

def vim#syntax#getEventNames(): string #{{{1
    if event_names != ''
        return event_names
    else
        event_names = getcompletion('*', 'event')
            ->join(' ')
    endif
    return event_names
enddef

def vim#syntax#getBuiltinFunctionNames(): string #{{{1
    if builtin_funcnames != ''
        return builtin_funcnames
    else
        builtin_funcnames = getcompletion('*', 'function')
            ->filter((_, v: string): bool => v[0] =~ '[a-z]' && v !~ '#')
            ->map((_, v: string): string => trim(v, '()'))
            ->join(' ')
    endif
    return builtin_funcnames
enddef

