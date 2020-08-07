    sil keepj keepp s/[^│┼]/ /ge
    call getline('.')->substitute('[^│┼]', ' ', 'g')->setline('.')

    sil keepj keepp 'x+,'y-g/^=\+\s*$/d_ | -s/^/## /
    sil keepj keepp 'x+,'y-g/^=\+\s*$/d_ | eval (line('.') - 1)->getline()->substitute('^', '## ', '')->setline(line('.') - 1)

    1,2s/[─┴┬├┤┼└┘┐┌]//ge
    call getline(1, 2)->map({_, v -> substitute(v, '[─┴┬├┤┼└┘┐┌]', '', 'g')})->setline(1)
    call getline(1, 2)->map('substitute(v:val, ''[─┴┬├┤┼└┘┐┌]'', '''', ''g'')')->setline(1)

    sil exe lnum1 .. ',' .. lnum2 .. 's/[─┴┬├┤┼└┘┐┌]//ge'
