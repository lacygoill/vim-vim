    sil keepj keepp s/[^│┼]/ /ge
    call getline('.')->substitute('[^│┼]', ' ', 'g')->setline('.')

    sil keepj keepp 'x+,'y-g/^=\+\s*$/d_ | -s/^/## /
    sil keepj keepp 'x+,'y-g/^=\+\s*$/d_ | eval (line('.') - 1)->getline()->substitute('^', '## ', '')->setline(line('.') - 1)

    1,2s/[─┴┬├┤┼└┘┐┌]//ge
    call getline(1, 2)->map({_, v -> v->substitute('[─┴┬├┤┼└┘┐┌]', '', 'g')})->setline(1)
    call getline(1, 2)->map('v:val->substitute(''[─┴┬├┤┼└┘┐┌]'', '''', ''g'')')->setline(1)

    exe 'sil ' .. lnum1 .. ',' .. lnum2 .. 's/[─┴┬├┤┼└┘┐┌]//ge'
