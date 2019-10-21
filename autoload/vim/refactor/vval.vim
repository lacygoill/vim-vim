" Interface {{{1
fu vim#refactor#vval#main(_) abort "{{{2
    let [cb_save, sel_save] = [&cb, &sel]
    let reg_save = ['"', getreg('"'), getregtype('"')]
    try
        set cb-=unnamed cb-=unnamedplus sel=inclusive
        " TODO: Make sure you find the argument of a `map()` or `filter()` expression.{{{
        "
        " Take inspiration from what we did for `:RefHeredoc`; in particular with:
        "
        "    - `s:contains_original_line()`
        "    - `s:contains_empty_or_commented_line()`
        "}}}
        call search('\m\C\<\%(map\|filter\)(', 'bceW')
        norm! %
        call search('["'']', 'bW')
        let char = matchstr(getline('.'), '\%'..col('.')..'c.')
        let pat = char is# '"' ? '\\\@1<!"' : ...
        call search(char, 'bW')
        " FIXME: `va'` fails on that:
        "
        "     echo map([1,2,3], 'v:val.."''"')
        "                                   ^
        "                                   cursor here
        exe 'norm! va'..char..'y'
        " TODO: Ask for user confirmation, like `:RefHeredoc`.
        let @" = ' {i,v -> '..s:get_expr(@")..'}'
        norm! gvp
    catch
        return lg#catch_error()
    finally
        let [&cb, &sel]  = [cb_save, sel_save]
        call call('setreg', reg_save)
    endtry
endfu
"}}}1
" Core {{{1
fu s:get_expr(captured_text) abort "{{{2
    let expr = a:captured_text
    let quote = expr[-1:-1]
    let is_single_quoted = quote is# "'"
    let expr = substitute(expr, '^\s*'..quote..'\|'..quote..'\s*$', '', 'g')
    if is_single_quoted
        let expr = substitute(expr, "''", "'", 'g')
    else
        let expr = eval('"'..expr..'"')
    endif
    let expr = substitute(expr, 'v:val', 'v', 'g')
    let expr = substitute(expr, 'v:key', 'k', 'g')
    return expr
endfu

