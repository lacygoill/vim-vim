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

fu vim#ref_dots(lnum1,lnum2) abort "{{{1
    let pat = [
        "\ outside a single-quoted string
        \ '\%(^\%(''[^'']*''\|[^'']\)*\)\@<=',
        "\ outside a double-quoted string
        \ '\%(^\%("[^"]*"\|[^"]\)*\)\@<=',
        "\ not on a commented line
        \ '\%(^\s*".*\)\@<!',
        "\ a dot not preceded by another dot, nor followed by another dot/equal sign
        \ '\%(\%(^\s*\\\)\@<!\s*\.\@<!\.[.=]\@!\s*',
        "\ `.=` assignment → `..=`
        \ '\|\.\@<!\.\ze=',
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
    exe range..'s/'..pat..'/../gce'
endfu

fu vim#ref_heredoc() abort "{{{1
    let cursor_save = getcurpos()
    let [pat1, pat2] = ['^\s*\%(let\|const\)\s\+\S*\s*=\s*\[', '\]\s*$']
    if searchpair(pat1, '', pat2, 'W') < 1
        return 'echoerr "RefHeredoc: no list assignment"'
    endif
    let [lnum2, line2] = [line('.'), getline('.')]
    norm! %
    let [lnum1, line1] = [line('.'), getline('.')]
    let list_name = matchstr(line1, substitute(pat1, '\C\\S\*', '\\zs&\\ze', ''))
    let items = s:get_items(lnum1, lnum2)
    let args = [line1, list_name, items, lnum1]
    let new_assignment = call('s:get_new_assignment', args)
    if lnum2 == line('$') | $pu='' | let remove_last_line = 1 | endif
    let range = lnum1..','..lnum2
    exe range..'d_'
    call append(line('.') - 1, new_assignment)
    if exists('remove_last_line') | $d_ | endif
    call setpos('.', cursor_save)
    return ''
endfu

fu s:get_items(lnum1, lnum2) abort
    let list_value = join(getline(a:lnum1, a:lnum2))
    let pat = '[,[]\s*\\\=\s*\([''"]\)\zs.\{-}\ze\1\s*\\\=[,\]]'
    let items = []
    let l:Item = {m -> m[1] is# "'"
    \ ? substitute(m[0], "''", "'", 'g')
    \ : substitute(m[0], '\\"', '"', 'g')
    \ }
    let l:Rep = {m -> add(items, l:Item(m))[0]}
    call substitute(list_value, pat, l:Rep, 'g')
    call map(items, {_,v -> v isnot# '' ? '    '..v : v})
    return items
endfu

fu s:get_new_assignment(...) abort
    let [line1, list_name, items, lnum1] = a:000
    let is_let = line1 =~# '^\s*let\s'
    let new_assignment =
    \ [printf('%s %s =<< trim END', is_let ? 'let' : 'const', list_name)]
    \ + items
    \ + ['END']
    let indent = repeat(' ', indent(lnum1))
    call map(new_assignment, {_,v -> indent..v})
    return new_assignment
endfu

fu vim#ref_if(lnum1,lnum2) abort "{{{1
    call search('^\s*\<\%(let\|const\|return\)\>', 'cW', a:lnum2)
    let kwd = matchstr(getline('.'), 'let\|const\|return')
    if kwd is# '' | return | endif
    let expr = matchstr(getline('.'),
        \ {
        \ 'let': '\m\Clet\s\+\zs.\{-}\ze\s*=',
        \ 'const': '\m\Cconst\s\+\zs.\{-}\ze\s*=',
        \ 'return': '\m\Creturn\s\+\zs.*',
        \ }[kwd])

    let tests = s:ref_if_get_tests_or_values(a:lnum1, a:lnum2,
        \ '\<if\>',
        \ '\<if\>\s\+\zs.*',
        \ '\<\%(else\|elseif\)\>',
        \ '\<\%(else\|elseif\)\>\s\+\zs.*')

    let values = s:ref_if_get_tests_or_values(a:lnum1, a:lnum2,
        \ '\<'..kwd..'\>',
        \ '\<'..kwd..'\>\s\+'..(kwd isnot# 'return' ? '.\{-}=\s*' : '')..'\zs.*',
        \ '\<'..kwd..'\>',
        \ '\<'..kwd..'\>\s\+'..(kwd isnot# 'return' ? '.\{-}=\s*' : '')..'\zs.*')

    if empty(tests) || tests ==# [''] || values ==# [''] || len(tests) > len(values)
        return
    endif

    let assignment = [kwd..' '..(kwd is# 'let' ? expr..' = ' : '')]
    let assignment[0] ..= tests[0]

    " The function should not operate on something like this:{{{
    "
    "     if condition1
    "         let var = 1
    "     elseif condition2
    "         let var = 2
    "     endif
    "
    " A conditional operator `?:` operate on ALL possible cases.
    " Same thing for a combination of multiple `?:`.
    " So, you can't express the previous `if` block with `?:`
    " Because the latter does NOT cover ALL cases.
    " It doesn't cover the cases where condition1 and condition2
    " are false.
    "}}}
    let n_values = len(values)
    let n_tests = len(tests)
    if n_tests == n_values
        return
    endif

    for i in range(1, n_tests-1)
        let assignment += ['    \ ?     '..values[i-1]]
                      \ + ['    \ : '..tests[i]]
    endfor
    let assignment += ['    \ ?     '..values[-2],
                     \ '    \ :     '..values[-1]]
    " Don't forget the space between `\` and `?`, as well as `\` and `:`!{{{
    " Without the space, you may have an error.
    " MWE:
    "
    "         echo map(['foo'], {_,v -> 1
    "         \?                         v
    "         \:                         v
    "         \ })
            "}}}

    " make sure our new block is indented like the original one
    let indent_block = matchstr(getline(a:lnum1), '^\s*')
    call map(assignment, {_,v -> indent_block..v})

    sil exe a:lnum1..','..a:lnum2..'d_'
    call append(line('.')-1, assignment)
endfu

fu s:ref_if_get_tests_or_values(lnum1, lnum2, pat1, pat2, pat3, pat4) abort
    call cursor(a:lnum1, 1)
    let expressions = [matchstr(getline(search(a:pat1, 'cW', a:lnum2)), a:pat2)]
    let guard = 0
    while search(a:pat3, 'W', a:lnum2) && guard <= 30
        let expressions += [matchstr(getline('.'), a:pat4)]
        let guard += 1
    endwhile
    return filter(expressions, {_,v -> v isnot# ''})
endfu

fu vim#ref_v_val() abort "{{{1
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

fu s:ref_v_val_rep(captured_text) abort
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

fu vim#refactor(lnum1,lnum2, confirm) abort "{{{1
    let range     = a:lnum1..','..a:lnum2
    let modifiers = 'keepj keepp '
    let view      = winsaveview()

    let substitutions = {
        \ 'au':    {'pat': '^\s*\zsau%[tocmd]',          'rep': 'au'    },
        \ 'C-x':   {'pat': '\C\<\zsC\ze-\a\>',           'rep': 'c'     },
        \ 'com':   {'pat': '^\s*\zscom%[mand]!? ',       'rep': 'com ' },
        \ 'cr':    {'pat': '\C\<CR\>',                   'rep': '<cr>'  },
        \ 'fu':    {'pat': '^\s*\zsfu%[nction]!? ',      'rep': 'fu '  },
        \ 'endfu': {'pat': '^\s*\zsendfu%[nction]\s*$',  'rep': 'endfu' },
        \ 'exe':   {'pat': 'exe%[cute] ',                'rep': 'exe '  },
        \ 'sil':   {'pat': '\<@<!sil%[ent](!| )',        'rep': ' sil\1'},
        \ 'setl':  {'pat': 'setl%[ocal] ',               'rep': 'setl ' },
        \ 'keepj': {'pat': 'keepj%[umps] ',              'rep': 'keepj '},
        \ 'keepp': {'pat': 'keepp%[atterns] ',           'rep': 'keepp '},
        \ 'nno':   {'pat': '(n|v|x|o|i|c)no%[remap] ',   'rep': '\1no ' },
        \ 'norm':  {'pat': 'normal!',                    'rep': 'norm!' },
        \ 'plug':  {'pat': '\C\<Plug\>',                 'rep': '<plug>'},
        \
        \ 'abort': { 'pat': '^%(.*\)\s*abort)@!\s*fu%[nction]!?.*\)'
        \                 ..'\zs\ze(\s*"\{\{\{\d*)?',
        \            'rep': ' abort' },
        \ }

    sil! exe modifiers..'norm! '..a:lnum1..'G='..a:lnum2..'G'
    for sbs in values(substitutions)
        sil exe modifiers..range..'s/\v'..sbs.pat..'/'..sbs.rep..'/ge'..(a:confirm ? 'c' : '')
    endfor

    " format the arguments of a mapping, so that there's no space between them,
    " and they are sorted
    let pat_map = '%(no%[remap]|nn%[oremap]|vn%[oremap]|xn%[oremap]|snor%[emap]|ono%[remap]|no%[remap]!|ino%[remap]|ln%[oremap]|cno%[remap]|tno%[remap]|map|nm%[ap]|vm%[ap]|xm%[ap]|smap|om%[ap]|map!|im%[ap]|lm%[ap]|cm%[ap]|tma%[p])'
    let pat = '\v'..pat_map..'\zs\s+(\<(buffer|expr|nowait|silent|unique)\>\s*)+'
    let Rep = {-> '  '..join(sort(split(submatch(0), '\s\+\|>\zs\ze<')), '')..'  '}
    sil exe '%s/'..pat..'/\=Rep()/ge'

    " make sure all buffer-local mappings use `<nowait>`
    sil exe '%s/\v'..pat_map..'\s+\<buffer\>%(\<expr\>)?\zs%(%(\<expr\>)?\<nowait\>)@!/<nowait>/ge'
    "                             ├────────────────────┘   ├─────────────────────────┘
    "                             │                        └ but not followed by `<nowait>`
    "                             │                          neither by `<expr><nowait>`
    "                             └ look for `<buffer>` may be followed by `<expr>`

    call winrestview(view)
endfu

