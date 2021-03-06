vim9script noclear

import Catch from 'lg.vim'

def vim#jumpToSyntaxDefinition() #{{{1
    @/ = '^\s*'
        .. '\%(exe\%[cute]\s\+[''"]\)\='
        .. 'syn\%[tax]\s\+\%(keyword\|match\|region\|cluster\)\s\+'
        .. '\zs' .. expand('<cword>') .. '\>'
    search(@/, 's')
    normal! zv
enddef

def vim#jumpToTag() #{{{1
    var iskeyword_save: string = &l:iskeyword
    var bufnr: number = bufnr('%')
    # Some tags may contain a colon (e.g.: `s:some_function()`).
    #                                       ^
    # When  `C-]` grabs  the  identifier  under the  cursor,  it only  considers
    # characters inside 'iskeyword'.
    setlocal iskeyword+=:
    try
        execute "normal! \<C-]>"
        normal! zvzz
    catch
        Catch()
        return
    finally
        # Why not simply `&l:iskeyword = iskeyword_save`?{{{
        #
        # We may have jumped to another buffer.
        #}}}
        setbufvar(bufnr, '&iskeyword', iskeyword_save)
    endtry
enddef

def vim#getHelpurl() #{{{1
    var winid: number = win_getid()
    # use our custom `K` which is smarter than the builtin one
    normal K
    if expand('%:p') !~ '^' .. $VIMRUNTIME .. '/doc/.*.txt$'
        return
    endif
    var fname: string = expand('%:p')
        ->fnamemodify(':t')
    var tag: string = getline('.')
        ->matchstr('\%.c\*\zs[^*]*')
    if &filetype == 'help'
        close
    endif
    win_gotoid(winid)
    var value: string = printf("[:help %s](https://vimhelp.org/%s.html#%s)\n",
        tag,
        fname,
        tag->substitute(':', '%3A', 'g'),
    )
    setreg('h', value, 'a')
    getreg('h', true, true)
        ->popup_notification({
            time: 2'000,
            pos: 'topright',
            line: 1,
            col: &columns,
            borderchars: ['─', '│', '─', '│', '┌', '┐', '┘', '└'],
        })
enddef

def vim#undoFtplugin() #{{{1
    set commentstring< formatlistpat<
    unlet! b:mc_chain

    unmap <buffer> [m
    unmap <buffer> ]m
    unmap <buffer> [M
    unmap <buffer> ]M

    nunmap <buffer> <C-]>
    nunmap <buffer> -h

    nunmap <buffer> =rb
    nunmap <buffer> =rd
    nunmap <buffer> =rh
    nunmap <buffer> =rl
    nunmap <buffer> =rL
    nunmap <buffer> =rm
    nunmap <buffer> =r-
    nunmap <buffer> =rq
    nunmap <buffer> =rs

    xunmap <buffer> =rd
    xunmap <buffer> =rq
    xunmap <buffer> =rt

    delcommand RefBar
    delcommand RefDot
    delcommand RefHeredoc
    delcommand RefLambda
    delcommand RefMethod
    delcommand RefQuote
    delcommand RefSubstitute
    delcommand RefTernary
enddef

