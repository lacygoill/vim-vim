import Catch from 'lg.vim'

fu vim#jump_to_tag() abort "{{{1
    let [isk_save, bufnr] = [&l:isk, bufnr('%')]
    " Some tags may contain a colon (ex: `s:some_function()`).
    "                                      ^
    " When  `C-]` grabs  the identifier  under  the cursor,  it only  considers
    " characters inside 'isk'.
    setl isk+=:
    try
        exe "norm! \<c-]>"
        norm! zvzz
    catch
        return s:Catch()
    finally
        " Why not simply `let &l:isk = isk_save`?{{{
        "
        " We may have jumped to another buffer.
        "}}}
        call setbufvar(bufnr, '&isk', isk_save)
    endtry
endfu

fu vim#undo_ftplugin() abort "{{{1
    set flp<
    unlet! b:mc_chain

    unmap <buffer> [m
    unmap <buffer> ]m
    unmap <buffer> [M
    unmap <buffer> ]M

    nunmap <buffer> <c-]>

    nunmap <buffer> =rb
    nunmap <buffer> =rd
    nunmap <buffer> =rh
    nunmap <buffer> =rl
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
endfu

