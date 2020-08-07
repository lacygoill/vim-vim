fu vim#syntax#include_group_in_cluster(cluster, group) abort
    let cluster = execute('syn list @' .. a:cluster)
        \ ->split('\n')
        \ ->filter('v:val =~# "^" .. a:cluster')[0]
    let cmd = 'syn cluster ' .. substitute(cluster, 'cluster=', 'contains=', '')
    let cmd = substitute(cmd, '\s*$', '', '')
    let cmd ..= ',' .. a:group
    exe cmd
endfu
