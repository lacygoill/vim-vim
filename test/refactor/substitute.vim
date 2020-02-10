    sil keepj keepp s/[^│┼]/ /ge
    call setline('.', substitute(getline('.'), '[^│┼]', ' ', 'g'))

    sil keepj keepp 'x+,'y-g/^=\+\s*$/d_ | -s/^/## /
    sil keepj keepp 'x+,'y-g/^=\+\s*$/d_ | call setline(line('.')-1, substitute(getline(line('.')-1), '^', '## ', ''))
