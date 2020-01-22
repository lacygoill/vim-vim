fu vim#syntax#override_vimOperGroup() abort
    " append the syntax group `vimLineComment` to the cluster `@vimOperGroup`
    let vimOperGroup = filter(split(execute('syn list @vimOperGroup'), '\n'), 'v:val =~# ''^vimOperGroup''')[0]
    let cmd = 'syn cluster '..substitute(vimOperGroup, 'cluster=', 'contains=', '')
    let cmd = substitute(cmd, '\s*$', '', '')
    let cmd ..= ',vimLineComment'
    exe cmd
endfu

