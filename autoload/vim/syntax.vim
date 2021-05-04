vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

var builtin_funcnames: string
var event_names: string

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

def vim#syntax#getEventNames(): string #{{{1
    if event_names != ''
        return event_names
    else
        event_names = getcompletion('*', 'event')
            ->join(' ')
    endif
    return event_names
enddef

