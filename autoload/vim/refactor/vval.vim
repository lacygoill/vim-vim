" Interface {{{1
fu vim#refactor#vval#main() abort "{{{2
    try
        " Make sure the visual selection contains an expression we can refactor.
        " It must begin with a quote, and end with a quote or a closed parenthesis.
        "
        " Why a closed parenthesis? MWE:
        "
        "         map(…, '…'.string(…))
        "                            ^
        let [lnum1, lnum2] = [line("'<"), line("'>")]
        let [col1, col2]   = [col("'<"), col("'>")]
        let [char1, char2] = [matchstr(getline(lnum1), '\%'..col1..'c.'),
                            \ matchstr(getline(lnum2), '\%'..col2..'c.')]
        if  index(["'", '"'], char1) < 0 || index(["'", '"', ')'], char2) < 0
            return ''
        endif

        let l:Rep = {-> '{i,v -> '..s:ref_v_val_rep(submatch(1))..'}'}

        "                     ┌ first character in selection
        "                     │              ┌ last character in selection
        "                     │              │
        sil keepj keepp s/\%'<.\(\_.*\%<'>.\)./\=l:Rep()/
        "                 ├───┘
        "                 └ the character just before the last one in the selection

        " Why use the anchor `\%<'>` instead of simply `\%'>` ?{{{
        "
        " We could write this:
        "
        "         .\%'>.
        "
        " … but it's not reliable with a linewise selection.
        "
        " MWE:
        "     V
        "     : C-u echo getpos("'>")[3]
        "
        "             2147483647
        "
        " It  probably doesn't  matter here,  because this  function should  only be
        " invoked on a characterwise selection, but I prefer to stay consistent.
        "}}}
    catch
        return lg#catch_error()
    endtry
endfu
"}}}1
" Core {{{1
fu s:ref_v_val_rep(captured_text) abort "{{{2
    " replace:
    "         v:val      →  v
    "         v:key      →  k
    "         ''         →  '
    "         \\         →  \
    "         '.string(  →  ∅

    let pat2rep = {
        \ 'v:val':             'v' ,
        \ 'v:key':             'k' ,
        \ "''":                "'" ,
        \ '\\\\':              '\\',
        \ '''\s*\.\s*string(': '',
        \ }

    let transformed_text = a:captured_text
    for [pat, rep] in items(pat2rep)
        let transformed_text = substitute(transformed_text, pat, rep, 'g')
    endfor

    " The  last 2  transformations  must  be done  after,  because of  undesired
    " interactions.
    "
    " replace:
    "         " (not escaped)  →  '
    "         \"               →  "
    return substitute(substitute(transformed_text, '\\\@1<!"', "'", 'g'), '\\"', '"', 'g')
endfu

