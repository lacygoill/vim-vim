    sil keepj keepp s/[^│┼]/ /ge
    call setline('.', substitute(getline('.'), '[^│┼]', ' ', 'g'))

    sil keepj keepp 'x+,'y-g/^=\+\s*$/d_ | -s/^/## /
    sil keepj keepp 'x+,'y-g/^=\+\s*$/d_ | call setline(line('.')-1, substitute(getline(line('.')-1), '^', '## ', ''))

    1,2s/[─┴┬├┤┼└┘┐┌]//ge
    call setline(1, map(getline(1, 2), {_,v -> substitute(v, '[─┴┬├┤┼└┘┐┌]', '', 'g')}))
    call setline(1, map(getline(1, 2), 'substitute(v:val, ''[─┴┬├┤┼└┘┐┌]'', '''', ''g'')'))

    sil exe lnum1..','..lnum2..'s/[─┴┬├┤┼└┘┐┌]//ge'
