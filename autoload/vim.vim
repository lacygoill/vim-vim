vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

import Catch from 'lg.vim'

def vim#jumpToTag() #{{{1
    var isk_save: string = &l:isk
    var bufnr: number = bufnr('%')
    # Some tags may contain a colon (ex: `s:some_function()`).
    #                                      ^
    # When  `C-]` grabs  the identifier  under  the cursor,  it only  considers
    # characters inside 'isk'.
    setl isk+=:
    try
        exe "norm! \<c-]>"
        norm! zvzz
    catch
        Catch()
        return
    finally
        # Why not simply `&l:isk = isk_save`?{{{
        #
        # We may have jumped to another buffer.
        #}}}
        setbufvar(bufnr, '&isk', isk_save)
    endtry
enddef

def vim#getHelpurl() #{{{1
    var winid: number = win_getid()
    # use our custom `K` which is smarter than the builtin one
    norm K
    if expand('%:p') !~ '^' .. $VIMRUNTIME .. '/doc/.*.txt$'
        return
    endif
    var fname: string = expand('%:p')->fnamemodify(':t')
    var tag: string = getline('.')->matchstr('\%' .. col('.') .. 'c\*\zs[^*]*')
    if &ft == 'help'
        close
    endif
    win_gotoid(winid)
    var value: string = printf("[:h %s](https://vimhelp.org/%s.html#%s)\n",
        tag,
        fname,
        tag,
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
    set cms< flp<
    unlet! b:mc_chain

    unmap <buffer> [m
    unmap <buffer> ]m
    unmap <buffer> [M
    unmap <buffer> ]M

    nunmap <buffer> <c-]>
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

    delc RefBar
    delc RefDot
    delc RefHeredoc
    delc RefLambda
    delc RefMethod
    delc RefQuote
    delc RefSubstitute
    delc RefTernary
    delc RefVim9
    delc Refactor
enddef

