vim9script noclear

def vim#refactor#dot#main(
    bang: bool,
    lnum1: number,
    lnum2: number
)
    var pat: string =
        # outside a single-quoted string
        '\%(^\%(''[^'']*''\|[^'']\)*\)\@<='
        # outside a double-quoted string
        .. '\%(^\%("[^"]*"\|[^"]\)*\)\@<='
        # not on a commented line
        .. '\%(^\s*["#].*\)\@<!'
        # a dot not preceded by another dot, nor followed by another dot/equal sign{{{
        #
        # We also handle two dots:
        #
        #     ... \.\=\. ...
        #         ^--^
        #
        # That's because in Vim9 script, the  binary operators such as `..` must
        # be surrounded  by whitespace.  We  want our  function to add  space if
        # necessary.
        #}}}
        .. '\%(\s*\%(^\s*\\\)\@<!\.\@1<!\.\=\.[.=]\@!\s*\)'
    # Warning: The pattern could find false positives.{{{
    #
    # MWE:
    #
    #     echo '
    #     \ a . b
    #     \ '
    #
    # Which is why we pass the `c` flag to `:s`.
    #}}}
    # Warning: The pattern could miss some dots.{{{
    #
    # Because of the part of the pattern which ignores dots inside strings:
    #
    #     echo 'a
    #     \ ' . 'b . c'
    #
    #     return "'" . cword . "'"
    #
    # But I think this kind of snippets are rare.
    # And I  prefer failing to double  some dots, rather than  wrongly doubling some
    # dots which I shouldn't  in a regex string for example  (could happen even with
    # the `c` flag of `:s` when there are many matches and you're tired).
    #}}}

    var range: string = ':' .. lnum1 .. ',' .. lnum2
    execute range .. 'substitute/' .. pat .. '/ .. /ge' .. (bang ? '' : 'c')
    # `.=` assignment → `..=`
    execute range .. 'substitute/\s\zs\.=\ze\s/..=/ge' .. (bang ? '' : 'c')
enddef

