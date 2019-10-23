fu vim#refactor#dot#main(bang, lnum1,lnum2) abort
    let pat = [
        "\ outside a single-quoted string
        \ '\%(^\%(''[^'']*''\|[^'']\)*\)\@<=',
        "\ outside a double-quoted string
        \ '\%(^\%("[^"]*"\|[^"]\)*\)\@<=',
        "\ not on a commented line
        \ '\%(^\s*".*\)\@<!',
        "\ a dot not preceded by another dot, nor followed by another dot/equal sign
        \ '\%(\%(^\s*\\\)\@<!\s*\.\@1<!\.[.=]\@!\s*',
        "\ `.=` assignment → `..=`
        \ '\|\.\@1<!\.\ze=',
        "\ or two dots surrounded by spaces
        \ '\|\s\+\.\.\s\+\)',
        \ ]
    let pat = join(pat, '')
    " Warning: The pattern could find false positives.{{{
    "
    " MWE:
    "
    "     echo '
    "     \ a . b
    "     \ '
    "
    " Which is why we pass the `c` flag to `:s`.
    "}}}
    " Warning: The pattern could miss some dots.{{{
    "
    " Because of the part of the pattern which ignores dots inside strings:
    "
    "     echo 'a
    "     \ ' . 'b . c'
    "
    "     return "'" . cword . "'"
    "
    " But I think this kind of snippets are rare.
    " And I  prefer failing to double  some dots, rather than  wrongly doubling some
    " dots which I shouldn't  in a regex string for example  (could happen even with
    " the `c` flag of `:s` when there are many matches and you're tired).
    "}}}

    let range = a:lnum1..','..a:lnum2
    exe range..'s/'..pat..'/../ge'..(a:bang ? '' : 'c')
endfu

