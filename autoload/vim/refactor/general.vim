" Init {{{1

let s:PAT_MAP = [
    \ 'no\%[remap]',
    \ 'nn\%[oremap]',
    \ 'vn\%[oremap]',
    \ 'xn\%[oremap]',
    \ 'snor\%[emap]',
    \ 'ono\%[remap]',
    \ 'no\%[remap]!',
    \ 'ino\%[remap]',
    \ 'ln\%[oremap]',
    \ 'cno\%[remap]',
    \ 'tno\%[remap]',
    \ 'map',
    \ 'nm\%[ap]',
    \ 'vm\%[ap]',
    \ 'xm\%[ap]',
    \ 'smap',
    \ 'om\%[ap]',
    \ 'map!',
    \ 'im\%[ap]',
    \ 'lm\%[ap]',
    \ 'cm\%[ap]',
    \ 'tma\%[p]',
    \ ]

let s:PAT_MAP = '\%('..join(s:PAT_MAP, '\|')..'\)' | lockvar s:PAT_MAP

fu vim#refactor#general#main(lnum1,lnum2, bang) abort "{{{1
    let range = a:lnum1..','..a:lnum2
    let modifiers = 'keepj keepp '
    let view = winsaveview()

    let substitutions = {
        \ 'au':    {'pat': '^\s*\zsaut\%[ocmd] ',          'rep': 'au '},
        \ 'lower': {'pat': '\C<\%(C-\a\|CR\|SID\|Plug\)>', 'rep': '\L\0'},
        \ 'com':   {'pat': '^\s*\zscomm\%[and]!\= ',       'rep': 'com '},
        \ 'echom': {'pat': 'echomsg\= ',                   'rep': 'echom '},
        \ 'exe':   {'pat': 'exec\%[ute] ',                 'rep': 'exe '},
        \ 'fu':    {'pat': '^\s*\zsfun\%[ction]!\= ',      'rep': 'fu '},
        \ 'endfu': {'pat': '^\s*\zsendfun\%[ction]\s*$',   'rep': 'endfu'},
        \ 'sil':   {'pat': '<\@1<!sile\%[nt]\(!\| \)',     'rep': 'sil\1'},
        \ 'setl':  {'pat': 'setlo\%[cal] ',                'rep': 'setl '},
        \ 'keepj': {'pat': 'keepju\%[mps] ',               'rep': 'keepj '},
        \ 'keepp': {'pat': 'keeppa\%[tterns] ',            'rep': 'keepp '},
        \ 'nno':   {'pat': '\([nvxoic]\)nor\%[emap] ',     'rep': '\1no '},
        \ 'noa':   {'pat': 'noau\%[tocmd] ',               'rep': 'noa '},
        \ 'norm':  {'pat': 'normal\=! ',                   'rep': 'norm! '},
        \
        \ 'abort': { 'pat': '^\%(.*)\s*abort\)\@!\s*fu\%[nction]!\=.*)'
        \                 ..'\zs\ze\%(\s*"{{'..'{\d*\)\=',
        \            'rep': ' abort' },
        \ }

    sil! exe modifiers..'norm! '..a:lnum1..'G='..a:lnum2..'G'
    for sbs in values(substitutions)
        sil exe modifiers..range..'s/'..sbs.pat..'/'..sbs.rep..'/ge'..(a:bang ? '' : 'c')
    endfor

    " format the arguments of a mapping, so that there's no space between them,
    " and they are sorted
    let pat = s:PAT_MAP..'\zs\s\+\%(<\%(buffer\|expr\|nowait\|silent\|unique\)>\s*\)\+'
    let Rep = {-> ' '..join(sort(split(submatch(0), '\s\+\|>\zs\ze<')), '')..' '}
    sil exe '%s/'..pat..'/\=Rep()/ge'

    " make sure all buffer-local mappings use `<nowait>`
    sil exe '%s/'..s:PAT_MAP..'\s\+<buffer>\%(<expr>\)\=\zs\%(\%(<expr>\)\=<nowait>\)\@!/<nowait>/ge'
    "                              ├───────────────────┘   ├───────────────────────────┘
    "                              │                       └ but not followed by `<nowait>`
    "                              │                        neither by `<expr><nowait>`
    "                              └ look for `<buffer>` may be followed by `<expr>`

    call winrestview(view)
endfu

