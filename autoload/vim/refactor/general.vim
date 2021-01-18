vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

# Init {{{1

var pat_map_tokens: list<string> =<< trim END
    no\%[remap]
    nn\%[oremap]
    vn\%[oremap]
    xn\%[oremap]
    snor\%[emap]
    ono\%[remap]
    no\%[remap]!
    ino\%[remap]
    ln\%[oremap]
    cno\%[remap]
    tno\%[remap]
    map
    nm\%[ap]
    vm\%[ap]
    xm\%[ap]
    smap
    om\%[ap]
    map!
    im\%[ap]
    lm\%[ap]
    cm\%[ap]
    tma\%[p]
END

const PAT_MAP: string = '\%(' .. join(pat_map_tokens, '\|') .. '\)'

def vim#refactor#general#main(lnum1: number, lnum2: number, bang: bool) #{{{1
    var range: string = ':' .. lnum1 .. ',' .. lnum2
    var modifiers: string = 'keepj keepp '
    var view: dict<number> = winsaveview()

    var substitutions: dict<dict<string>> = {
        au:    {pat: '^\s*\zsaut\%[ocmd]\ze!\=\%( \|$\)', rep: 'au'},
        lower: {pat: '\C<\%(C-\a\|CR\|SID\|Plug\)>', rep: '\L\0'},
        com:   {pat: '^\s*\zscomm\%[and]!\= ', rep: 'com '},
        echom: {pat: 'echomsg\= ', rep: 'echom '},
        exe:   {pat: 'exec\%[ute] ', rep: 'exe '},
        fu:    {pat: '^\s*\zsfun\%[ction]!\= ', rep: 'fu '},
        endfu: {pat: '^\s*\zsendf\%[unction]\s*$', rep: 'endfu'},
        sil:   {pat: '<\@1<!sile\%[nt]\(!\| \)', rep: 'sil\1'},
        setl:  {pat: 'setlo\%[cal] ', rep: 'setl '},
        keepj: {pat: 'keepju\%[mps] ', rep: 'keepj '},
        keepp: {pat: 'keeppa\%[tterns] ', rep: 'keepp '},
        nno:   {pat: '\([nvxoict]\)nor\%[emap] ', rep: '\1no '},
        noa:   {pat: 'noau\%[tocmd] ', rep: 'noa '},
        norm:  {pat: 'normal\=! ', rep: 'norm! '},
        abort: {pat: '^\%(.*)\s*abort\)\@!\s*fu\%[nction]!\=.*)'
                  .. '\zs\ze\%(\s*"{{' .. '{\d*\)\=',
                rep: ' abort'},
        }

    sil! exe modifiers .. 'norm! ' .. lnum1 .. 'G=' .. lnum2 .. 'G'
    for sbs in values(substitutions)
        var cmd: string = modifiers .. range .. 's/' .. sbs.pat .. '/' .. sbs.rep .. '/ge'
        if bang
            sil exe cmd
        else
            exe cmd .. 'c'
        endif
    endfor

    # format the arguments of a mapping, so that there's no space between them,
    # and they are sorted
    var pat: string = PAT_MAP .. '\zs\s\+\%(<\%(buffer\|expr\|nowait\|silent\|unique\)>\s*\)\+'
    var Rep: func = (): string =>
        ' ' .. submatch(0)->split('\s\+\|>\zs\ze<')->sort()->join('') .. ' '
    sil exe ':%s/' .. pat .. '/\=Rep()/ge'

    # make sure all buffer-local mappings use `<nowait>`
    sil exe ':%s/' .. PAT_MAP .. '\s\+<buffer>\%(<expr>\)\=\zs\%(\%(<expr>\)\=<nowait>\)\@!/<nowait>/ge'
    #                                 ├───────────────────┘   ├───────────────────────────┘
    #                                 │                       └ but not followed by `<nowait>`
    #                                 │                        neither by `<expr><nowait>`
    #                                 └ look for `<buffer>` may be followed by `<expr>`

    winrestview(view)
enddef

