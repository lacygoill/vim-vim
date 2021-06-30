vim9script noclear

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

const PAT_MAP: string = '\%(' .. pat_map_tokens->join('\|') .. '\)'

def vim#refactor#general#main( #{{{1
    lnum1: number,
    lnum2: number,
    bang: bool
)
    var range: string = ':' .. lnum1 .. ',' .. lnum2
    var modifiers: string = 'keepjumps keeppatterns '
    var view: dict<number> = winsaveview()

    var substitutions: dict<dict<string>> = {
        autocmd:      {pat: '^\s*\zsau\%[tocm]\ze!\=\%( \|$\)', rep: 'autocmd'},
        lower:        {pat: '\C<\%(C-\a\|CR\|SID\|Plug\)>', rep: '\L\0'},
        command:      {pat: '^\s*\zscom\%[man]!\= ', rep: 'command '},
        echomsg:      {pat: 'echom\%[sg] ', rep: 'echomsg '},
        execute:      {pat: 'exe\%[cut] ', rep: 'execute '},
        function:     {pat: '^\s*\zsfu\%[nction]!\= ', rep: 'function '},
        endfunction:  {pat: '^\s*\zsendf\%[unction]\s*$', rep: 'endfunction'},
        silent:       {pat: '<\@1<!sil\%[en]\(!\| \)', rep: 'silent\1'},
        setlocal:     {pat: 'setl\%[ocal] ', rep: 'setlocal '},
        keepjumps:    {pat: 'keepj\%[umps] ', rep: 'keepjumps '},
        keeppatterns: {pat: 'keepp\%[atterns] ', rep: 'keeppatterns '},
        nno:          {pat: '\([nvxoict]\)no\%[remap] ', rep: '\1noremap '},
        noautocmd:    {pat: 'noa\%[utocmd] ', rep: 'noautocmd '},
        normal:       {pat: 'norm\%[al]\(!\| \)', rep: 'normal\1'},
        abort:        {pat: '^\%(.*)\s*abort\)\@!\s*fu\%[nction]!\=.*)'
                         .. '\zs\ze\%(\s*"{{' .. '{\d*\)\=',
                       rep: ' abort'},
    }

    execute 'silent! ' .. modifiers .. 'normal! ' .. lnum1 .. 'G=' .. lnum2 .. 'G'
    for sbs in values(substitutions)
        var cmd: string = modifiers .. range .. 'substitute/' .. sbs.pat .. '/' .. sbs.rep .. '/ge'
        if bang
            execute 'silent ' .. cmd
        else
            execute cmd .. 'c'
        endif
    endfor

    # format the arguments of a mapping, so that there's no space between them,
    # and they are sorted
    var pat: string = PAT_MAP .. '\zs\s\+\%(<\%(buffer\|expr\|nowait\|silent\|unique\)>\s*\)\+'
    Rep = (): string =>
        ' '
        .. submatch(0)
            ->split('\s\+\|>\zs\ze<')
            ->sort()
            ->join('')
        .. ' '
    execute 'silent ' .. range .. 'substitute/' .. pat .. '/\=Rep()/ge'

    # make sure all buffer-local mappings use `<nowait>`
    execute 'silent ' .. range .. 's'
        .. '/' .. PAT_MAP .. '\s\+'
            # look for `<buffer>` (might be followed by `<expr>`)
            .. '<buffer>\%(<expr>\)\='
            .. '\zs'
            # but not followed by `<nowait>` neither by `<expr><nowait>`
            .. '\%(\%(<expr>\)\=<nowait>\)\@!'
        .. '/<nowait>/ge'

    winrestview(view)
enddef

var Rep: func
