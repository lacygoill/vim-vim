fu! vim#jump_to_tag() abort "{{{1
    let isk_save = &l:isk
    setl isk+=:
    try
        exe "norm! \<c-]>"
        norm! zvzz
    catch
        return lg#catch_error()
    finally
        let &l:isk = isk_save
    endtry
endfu

fu! vim#ref_if(line1,line2) abort "{{{1
    call search('\<\%(let\|return\)\>', 'cW', a:line2)
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
    \                                         '\v<'.kwd.'>\s+'.(kwd is# 'let' ? '.{-}\=\s*' : '').'\zs.*',
    \                                         '\v<'.kwd.'>',
    \                                         '\v<'.kwd.'>\s+'.(kwd is# 'let' ? '.{-}\=\s*' : '').'\zs.*')

    if tests ==# [''] || values ==# [''] || len(tests) > len(values)
        return
    endif

    let indent_kwd = matchstr(getline(a:line1), '^\s*')
    let indent_val = repeat(' ', strchars(matchstr(getline(a:line1+1),
    \                                              '\v^\s*'.kwd.(kwd is# 'let' ? '.{-}\=\s?' : '\s'))
    \                                     , 1)
    \                            -strlen(indent_kwd)
    \                            -3)
    let indent_test = repeat(' ', len(indent_val)-&sw)
    let assignment  = [ indent_kwd.kwd.' '.(kwd is# 'let' ? expr.' = ' : '') ]

    for i in range(1, len(tests))
        let assignment += i ==# len(tests)
        \                 ?    [ repeat(' ', &sw).values[i-1] ]
        \
        \                 :    [ tests[i-1] ]
        \                    + [ "\n".indent_kwd.'\ ?'.indent_val.values[i-1] ]
        \                    + [ "\n".indent_kwd.'\ :'.indent_test ]
        "                                          │
        "                                          └ don't forget the space!{{{
        " Without the space, you may have an error.
        " MWE:
        "
        "         echo map(['foo'], {i,v -> 1
        "         \?                         v
        "         \:                         v
        "         \ })
        "}}}
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
        " Why a closed parenthesis? MWE:
        "
        "         map(…, '…'.string(…))
        "                            ^
        let [ line1, line2 ] = [ line("'<"), line("'>") ]
        let [ col1, col2 ]   = [ col("'<"), col("'>") ]
        let [ char1, char2 ] = [ matchstr(getline(line1), '\%'.col1.'c.'),
        \                        matchstr(getline(line2), '\%'.col2.'c.') ]
        if  index(["'", '"'], char1) < 0 || index(["'", '"', ')'], char2) < 0
            return ''
        endif

        let l:Rep = {   -> '{ i,v -> '.s:ref_v_val_rep(submatch(1)).' }' }

        "                     ┌ first character in selection
        "                     │              ┌ last character in selection
        "                     │              │
        sil keepj keepp s/\%'<.\(\_.*\%<'>.\)./\=l:Rep()/
        "                 └───┤
        "                     └ the character just before the last one in the selection

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
    \                     'C-x':   { 'pat': '\C\<\zsC\ze-\a\>',           'rep': 'c'      },
    \                     'com':   { 'pat': '^\s*\zscom%[mand]!? ',       'rep': 'com! '  },
    \                     'cr':    { 'pat': '\C\<CR\>',                   'rep': '<cr>'   },
    \                     'fu':    { 'pat': '^\s*\zsfu%[nction]!? ',      'rep': 'fu! '   },
    \                     'endfu': { 'pat': '^\s*\zsendfu%[nction]\s*$',  'rep': 'endfu'  },
    \                     'exe':   { 'pat': 'exe%[cute] ',                'rep': 'exe '   },
    \                     'sil':   { 'pat': '\<@<!sil%[ent](!| )',        'rep': ' sil\1' },
    \                     'setl':  { 'pat': 'setl%[ocal] ',               'rep': 'setl '  },
    \                     'keepj': { 'pat': 'keepj%[umps] ',              'rep': 'keepj ' },
    \                     'keepp': { 'pat': 'keepp%[atterns] ',           'rep': 'keepp ' },
    \                     'nno':   { 'pat': '(n|v|x|o|i|c)no%[remap] ',   'rep': '\1no '  },
    \                     'norm':  { 'pat': 'normal!',                    'rep': 'norm!'  },
    \                     'plug':  { 'pat': '\C\<Plug\>',                 'rep': '<plug>' },
    \
    \                     'abort': { 'pat': '^%(.*\)\s*abort)@!\s*fu%[nction]!?.*\)\zs\ze(\s*"\{\{\{\d*)?',
    \                                'rep': ' abort' },
    \                   }

    sil! exe modifiers.'norm! '.a:lnum1.'G='.a:lnum2.'G'
    for sbs in values(substitutions)
        sil exe modifiers.range.'s/\v'.sbs.pat.'/'.sbs.rep.'/ge'.(a:confirm ? 'c' : '')
    endfor

    " format the arguments of a mapping, so that there's no space between them,
    " and they are sorted
    let pat_map = '%(no%[remap]|nn%[oremap]|vn%[oremap]|xn%[oremap]|snor%[emap]|ono%[remap]|no%[remap]!|ino%[remap]|ln%[oremap]|cno%[remap]|tno%[remap]|map|nm%[ap]|vm%[ap]|xm%[ap]|smap|om%[ap]|map!|im%[ap]|lm%[ap]|cm%[ap]|tma%[p])'
    let pat = '\v'.pat_map.'\zs\s+(\<(buffer|expr|nowait|silent|unique)\>\s*)+'
    let Rep = {-> '  '.join(sort(split(submatch(0), '\s\+\|>\zs\ze<')), '').'  '}
    sil exe '%s/'.pat.'/\=Rep()/ge'

    " make sure all buffer-local mappings use `<nowait>`
    sil exe '%s/\v'.pat_map.'\s+\<buffer\>%(\<expr\>)?\zs%(%(\<expr\>)?\<nowait\>)@!/<nowait>/ge'
    "                           └────────────────────┤   └─────────────────────────┤
    "                                                │                             └ but not followed by `<nowait>`
    "                                                │                               neither by `<expr><nowait>`
    "                                                │
    "                                                └ look for `<buffer>` may be followed by `<expr>`

    call winrestview(view)
endfu
