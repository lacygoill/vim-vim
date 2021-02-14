vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Interface {{{1
def vim#refactor#lambda#main(type: any = ''): string #{{{2
    if typename(type) == 'string' && type == ''
        &opfunc = 'vim#refactor#lambda#main'
        return 'g@l'
    endif

    # TODO: A lambda is not always better than an eval string.
    # Make the function support the reverse refactoring (`{_, v -> v}` → `'v:val'`).
    var view: dict<number> = winsaveview()

    # TODO: Sanity check: make sure the found quotes are *after* `map(`/`filter(`.
    var s2: number = SearchClosingQuote()
    var lnum2: number
    var col2: number
    [lnum2, col2] = getcurpos()[1 : 2]
    norm! v

    var s1: number = SearchOpeningQuote()
    var lnum1: number
    var col1: number
    [lnum1, col1] = getcurpos()[1 : 2]
    norm! y

    var bang: bool = typename(type) == 'bool' ? type : true
    if !vim#util#weCanRefactor(
        [s1, s2],
        lnum1, col1,
        lnum2, col2,
        bang,
        view,
        'map/filter {expr2}', 'lambda',
        )
        return ''
    endif

    var new_expr: string
    if @" =~ '\Cv:key'
        new_expr = '{i, v -> ' .. GetExpr(@") .. '}'
    else
        new_expr = '{_, v -> ' .. GetExpr(@") .. '}'
    endif

    vim#util#put(
        new_expr,
        lnum1, col1,
        lnum2, col2,
        )
    return ''
enddef

def vim#refactor#lambda#new(type = ''): string #{{{2
    if type == ''
        &opfunc = 'vim#refactor#lambda#new'
        return 'g@l'
    endif
    searchpair('{.*->', '', '}', 'bcW')
    var start: list<number> = getpos('.')
    searchpair('{', '', '}', 'W')
    # delete "}"
    getline('.')
        ->substitute('.*\zs\%' .. col('.') .. 'c.', '', '')
        ->setline('.')
    setpos('.', start)
    # replace "{" with "("
    getline('.')
        ->substitute('.*\zs\%' .. col('.') .. 'c.', '(', '')
        ->setline('.')
    # replace "->" with "=>"
    getline('.')
        ->substitute('.*\%' .. start[2] .. 'c.\{-}\zs\s*->', ') =>', '')
        ->setline('.')
    return ''
enddef
#}}}1
# Core {{{1
def SearchClosingQuote(): number #{{{2
    # FIXME:  The logic is wrong when we dealing with a nested `map()`/`filter()`.{{{
    #
    # Example:
    #
    #     filter(mapnew(fzf#vim#_buflisted_sorted(), 'bufname(v:val)'), 'len(v:val)')
    #                                                                        ^
    #                                                                        cursor position
    #
    # Press `=rl`:  the refactoring fails.
    # This is not a big issue though.  We should first refactor this line to get
    # rid of the nesting, using the `->` method token:
    #
    #     mapnew(fzf#vim#_buflisted_sorted(), 'bufname(v:val)')->filter('len(v:val)')
    #
    # Then, the current logic is correct, and `=rl` works as expected.
    #}}}
    if vim#util#search('\m\C\<\%(map\|filter\)(', 'be') == 0
        return 0
    endif
    var pos: list<number> = getcurpos()
    norm! %
    if getcurpos() == pos
        return 0
    endif
    return search('["'']', 'bW')
enddef

def SearchOpeningQuote(): number #{{{2
    var char: string = getline('.')->strpart(col('.') - 1)[0]
    var pat: string = char == '"' ? '\\\@1<!"' : "'\\@1<!''\\@!"
    return search(pat, 'bW')
enddef

def GetExpr(captured_text: string): string #{{{2
    var expr: string = captured_text
    var quote: string = expr[-1]
    var is_single_quoted: bool = quote == "'"
    expr = substitute(expr, '^\s*' .. quote .. '\|' .. quote .. '\s*$', '', 'g')
    if is_single_quoted
        expr = substitute(expr, "''", "'", 'g')
    else
        expr = eval('"' .. expr .. '"')
    endif
    return expr
        ->substitute('v:val', 'v', 'g')
        ->substitute('v:key', 'i', 'g')
enddef

