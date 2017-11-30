fu! vim#fold_text() abort "{{{1
    let indent = repeat(' ', (v:foldlevel-1)*3)
    let title  = substitute(getline(v:foldstart), '\v^\s*"\s*|\s*"?\{\{\{\d?', '', 'g')
    let title  = substitute(title, '\v^\s*fu%[nction]! %(.*%(#|s:))?(.{-})\(.*\).*', '\1', '')

    if get(b:, 'my_title_full', 0)
        let foldsize  = (v:foldend - v:foldstart)
        let linecount = '['.foldsize.']'.repeat(' ', 4 - strchars(foldsize))
        return indent.' '.linecount.' '.title
    else
        return indent.' '.title
    endif
endfu

fu! vim#ref_if(line1,line2) abort "{{{1
    call search('let\|return', 'cW', a:line2)
    let kwd = matchstr(getline('.'), 'let\|return')
    let expr = matchstr(getline('.'), '\v%(let|return)\s+\zs\S+')
    if empty(expr)
        return
    endif

    let tests = s:ref_if_get_tests_or_values(a:line1, a:line2,
    \                                        '\v<if>',
    \                                        '\v<if>\s+\zs.*',
    \                                        '\v<%(else|elseif)>',
    \                                        '\v<%(else|elseif)>\s+\zs.*')

    let values = s:ref_if_get_tests_or_values(a:line1, a:line2,
    \                                         '\v<'.kwd.'>',
    \                                         '\v<'.kwd.'>\s+'.(kwd ==# 'let' ? '.{-}\=\s*' : '').'\zs.*',
    \                                         '\v<'.kwd.'>',
    \                                         '\v<'.kwd.'>\s+'.(kwd ==# 'let' ? '.{-}\=\s*' : '').'\zs.*')

    if tests == [''] || values == [''] || len(tests) > len(values)
        return
    endif

    let indent_kwd = matchstr(getline(a:line1), '^\s*')
    let indent_val = repeat(' ', strchars(matchstr(getline(a:line1+1),
    \                                              '\v^\s*'.kwd.(kwd ==# 'let' ? '.{-}\=\s?' : '\s'))
    \                                     , 1)
    \                            -strlen(indent_kwd)
    \                            -2)
    let indent_test = repeat(' ', len(indent_val)-&sw)
    let assignment  = [ indent_kwd.kwd.' '.(kwd ==# 'let' ? expr.' = ' : '') ]

    for i in range(1, len(tests))
        let assignment += i == len(tests)
        \                 ?    [ repeat(' ', &sw).values[i-1] ]
        \
        \                 :    [ tests[i-1] ]
        \                    + [ "\n".indent_kwd.'\?'.indent_val.values[i-1] ]
        \                    + [ "\n".indent_kwd.'\:'.indent_test ]
    endfor

    let assignment = join(assignment, '')
    sil exe a:line1.','.a:line2.'d_'
    sil -put =assignment
endfu

fu! s:ref_if_get_tests_or_values(line1, line2, pat1, pat2, pat3, pat4) abort "{{{1
    exe a:line1
    let expressions = [ matchstr(getline(search(a:pat1, 'cW', a:line2)), a:pat2) ]
    let guard = 0
    while search(a:pat3, 'W', a:line2) && guard <= 30
        let expressions += [ matchstr(getline('.'), a:pat4) ]
        let guard += 1
    endwhile
    return expressions
endfu

fu! vim#ref_v_val() abort "{{{1
    try
        " Make sure the visual selection contains an expression we can refactor.
        " It must begin with a quote, and end with a quote or a closed parenthesis.
        "
        " Why a `p`? Watch:
        "
        "         map(…, printf(…))
        "                ^
        "
        " Why a closed parenthesis? Watch:
        "
        "         map(…, '…'.string(…))
        "                            ^
        let [ line1, line2 ] = [ line("'<"), line("'>") ]
        let [ col1, col2 ]   = [ col("'<"), col("'>") ]
        let [ char1, char2 ] = [ matchstr(getline(line1), '\%'.col1.'c.'),
        \                        matchstr(getline(line2), '\%'.col2.'c.') ]
        if  index(["'", '"', 'p'], char1) < 0 || index(["'", '"', ')'], char2) < 0
            return ''
        endif

        let cur_line = line('.')
        let l:Rep = {   -> '{ k,v -> '.s:ref_v_val_rep(submatch(1)).' }' }

        "                     ┌ first character in selection
        "                     │              ┌ last character in selection
        "                     │              │
        sil keepj keepp s/\%'<.\(\_.*\%<'>.\)./\=l:Rep()/
        "                 └───┤
        "                     └ the character just before the last one in the selection

        " We may have deleted the `p` in a possible `printf()`.
        " Restore it.
        sil exe 'keepj keepp '.cur_line.'s/\ze\<rintf\>/p/e'

        " Why use the anchor `\%<'>` instead of simply `\%'>` ?{{{
        "
        " We could write this:
        "
        "         .\%'>.
        "
        " … but it's not reliable with a linewise selection.
        "
        " Watch:
        "     V
        "     : C-u echo getpos("'>")[3]
        "
        "             2147483647
        "
        " It  probably doesn't  matter here,  because this  function should  only be
        " invoked on a characterwise selection, but I prefer to stay consistent.
        "}}}
    catch
        return 'echoerr '.string(v:exception)
    endtry
    return ''
endfu

fu! s:ref_v_val_rep(captured_text) abort "{{{1
    " replace:
    "         v:val      →  v
    "         v:key      →  k
    "         ''         →  '
    "         \\         →  \
    "         '.string(  →  ∅

    let pat2rep = {
    \               'v:val'              : 'v' ,
    \               'v:key'              : 'k' ,
    \               "''"                 : "'" ,
    \               '\\\\'               : '\\',
    \               '''\s*\.\s*string('  : '',
    \             }

    let transformed_text = a:captured_text
    for [ pat, rep ] in items(pat2rep)
        let transformed_text = substitute(transformed_text, pat, rep, 'g')
    endfor

    " The  last 2  transformations  must  be done  after,  because of  undesired
    " interactions.
    "
    " replace:
    "         " (not escaped)  →  '
    "         \"               →  "
    return substitute(substitute(transformed_text, '\\\@<!"', "'", 'g'), '\\"', '"', 'g')
endfu

fu! vim#refactor(lnum1,lnum2, confirm) abort "{{{1
    let range     = a:lnum1.','.a:lnum2
    let modifiers = 'keepj keepp '
    let view      = winsaveview()

    let substitutions = {
    \                     'au':    { 'pat': '^\s*\zsau%[tocmd]',          'rep': 'au'     },
    \                     'com':   { 'pat': '^\s*\zscom%[mand]!? ',       'rep': 'com! '  },
    \                     'fu':    { 'pat': '^\s*\zsfu%[nction]!? ',      'rep': 'fu! '   },
    \                     'endfu': { 'pat': '^\s*\zsendfu%[nction]\s*$',  'rep': 'endfu'  },
    \                     'exe':   { 'pat': 'exe%[cute] ',                'rep': 'exe '   },
    \                     'sil':   { 'pat': '\<@<!sil%[ent](!| )',        'rep': ' sil\1' },
    \                     'setl':  { 'pat': 'setl%[ocal] ',               'rep': 'setl '  },
    \                     'keepj': { 'pat': 'keepj%[umps] ',              'rep': 'keepj ' },
    \                     'keepp': { 'pat': 'keepp%[atterns] ',           'rep': 'keepp ' },
    \                     'nno':   { 'pat': '(n|v|x|o|i|c)no%[remap] ',   'rep': '\1no '  },
    \                     'norm':  { 'pat': 'normal!',                    'rep': 'norm!'  },
    \
    \                     'abort': { 'pat': '^%(.*\)\s*abort)@!\s*fu%[nction]!?.*\)\zs\ze(\s*"\{\{\{\d*)?',
    \                                'rep': ' abort' },
    \                   }

    sil! exe modifiers.'norm! '.a:lnum1.'G='.a:lnum2.'G'
    for sbs in values(substitutions)
        sil! exe modifiers.range.'s/\v'.sbs.pat.'/'.sbs.rep.'/g'.(a:confirm ? 'c' : '')
    endfor

    norm! gg=G

    call winrestview(view)
endfu
