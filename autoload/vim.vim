fu vim#helptopic() abort "{{{1
    let [line, col] = [getline('.'), col('.')]
    if line[col-1] =~# '\k'
        let pat_pre = '.*\ze\<\k*\%'..col..'c'
    else
        let pat_pre = '.*\%'..col..'c.'
    endif
    let pat_post = '\%'..col..'c\k*\>\zs.*'
    let pre = matchstr(line, pat_pre)
    let post = matchstr(line, pat_post)

    let syntax_item = get(reverse(map(synstack(line('.'), col('.')),
        \ {_,v -> synIDattr(v,'name')})), 0, '')
    let cword = expand('<cword>')

    if syntax_item is# 'vimFuncName'
        return cword..'()'
    elseif syntax_item is# 'vimOption'
        return "'"..cword.."'"
    " `-bar`, `-nargs`, `-range`...
    elseif syntax_item is# 'vimUserAttrbKey'
        return ':command-'..cword

    " if the word under the cursor is  preceded by nothing, except maybe a colon
    " right before, treat it as an Ex command
    elseif pre =~# '^\s*:\=$'
        return ':'..cword

    " `v:key`, `v:val`, `v:count`, ... (cursor after `:`)
    elseif pre =~# '\<v:$'
        return 'v:'..cword
    " `v:key`, `v:val`, `v:count`, ... (cursor on `v`)
    elseif cword is# 'v' && post =~# ':\w\+'
        return 'v'..matchstr(post, ':\w\+')

    else
        return cword
    endif
endfu

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
        return lg#catch_error()
    finally
        " Why not simply `let &l:isk = isk_save`?{{{
        "
        " We may have jumped to another buffer.
        "}}}
        call setbufvar(bufnr, '&isk', isk_save)
    endtry
endfu

fu vim#undo_ftplugin() abort "{{{1
    setl com< ofu<
    unlet! b:mc_chain

    unmap <buffer> [m
    unmap <buffer> ]m
    unmap <buffer> [M
    unmap <buffer> ]M

    nunmap <buffer> K
    nunmap <buffer> =rb
    nunmap <buffer> =rd
    nunmap <buffer> =rl
    nunmap <buffer> =rm
    nunmap <buffer> =rq

    xunmap <buffer> =rd
    xunmap <buffer> =rq
    xunmap <buffer> =rt

    delc RefBar
    delc RefDot
    delc RefHeredoc
    delc RefLambda
    delc RefMethod
    delc RefQuote
    delc RefTernary
    delc Refactor
endfu

