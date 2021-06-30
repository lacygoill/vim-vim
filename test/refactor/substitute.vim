    silent keepjumps keeppatterns substitute/[^│┼]/ /ge
    call getline('.')->substitute('[^│┼]', ' ', 'g')->setline('.')

    silent keepjumps keeppatterns :'x+1,'y-1 global/^=\+\s*$/delete _ | :.-1 substitute/^/## /
    silent keepjumps keeppatterns :'x+1,'y-1 global/^=\+\s*$/delete _ | eval (line('.') - 1)->getline()->substitute('^', '## ', '')->setline(line('.') - 1)

    1,2s/[─┴┬├┤┼└┘┐┌]//ge
    call getline(1, 2)->map({_, v -> v->substitute('[─┴┬├┤┼└┘┐┌]', '', 'g')})->setline(1)
    call getline(1, 2)->map('v:val->substitute(''[─┴┬├┤┼└┘┐┌]'', '''', ''g'')')->setline(1)

    execute 'silent ' .. lnum1 .. ',' .. lnum2 .. 'substitute/[─┴┬├┤┼└┘┐┌]//ge'
