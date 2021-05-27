vim9script

if exists('b:current_syntax')
    finish
endif

# TODO: Are there good things to borrow from this plugin:
# https://github.com/vim-jp/syntax-vim-ex

# Automatically generated keyword lists: {{{1
# vimTodo: contains common special-notices for comments {{{2
# Use the `vimCommentGroup` cluster to add your own.

syn keyword vimTodo contained FIXME TODO
syn cluster vimCommentGroup contains=vimTodo,@Spell

# regular vim commands {{{2

exe 'syn keyword vimCommand ' .. vim#syntax#getCommandNames() .. ' contained'
syn match vimCommand '\<z[-+^.=]\=\>' contained

# vimOptions are caught only when contained in a vimSet {{{2

exe 'syn keyword vimOption ' .. vim#syntax#getOptionNames() .. ' contained'

# termcap codes (which can also be set) {{{2

exe 'syn keyword vimOption ' .. vim#syntax#getTerminalOptionNames() .. ' contained'
exe 'syn match vimOption ' .. vim#syntax#getTerminalOptionNames(false) .. ' contained'

# AutoCmd Events {{{2

syn case ignore
exe 'syn keyword vimAutoEvent ' .. vim#syntax#getEventNames() .. ' contained'

# Highlight commonly used Groupnames {{{2

syn keyword vimGroup contained
    \ Comment Constant String Character Number Boolean Float Identifier Function
    \ Statement Conditional Repeat Label Operator Keyword Exception PreProc
    \ Include Define Macro PreCondit Type StorageClass Structure Typedef Special
    \ SpecialChar Tag Delimiter SpecialComment Debug Underlined Ignore Error Todo

# Default highlighting groups {{{2

syn keyword vimHLGroup contained
    \ ColorColumn Cursor CursorColumn CursorIM CursorLine CursorLineNr DiffAdd
    \ DiffChange DiffDelete DiffText Directory EndOfBuffer ErrorMsg FoldColumn
    \ Folded IncSearch LineNr LineNrAbove LineNrBelow MatchParen Menu ModeMsg
    \ MoreMsg NonText Normal Pmenu PmenuSbar PmenuSel PmenuThumb Question
    \ QuickFixLine Scrollbar Search SignColumn SpecialKey SpellBad SpellCap
    \ SpellLocal SpellRare StatusLine StatusLineNC StatusLineTerm TabLine
    \ TabLineFill TabLineSel Terminal Title Tooltip VertSplit Visual VisualNOS
    \ WarningMsg WildMenu

syn match vimHLGroup 'Conceal' contained
syn case match

# Function Names {{{2

exe 'syn keyword vimFuncName contained ' .. vim#syntax#getBuiltinFunctionNames()
#}}}1
# Special Vim Highlighting (not automatic) {{{1
# Numbers {{{2

syn match vimNumber '\<\d\+\%(\.\d\+\%([eE][+-]\=\d\+\)\=\)\='
    \ skipwhite nextgroup=vimGlobal,vimSubst,vimCommand,vimComment,vim9Comment

syn match vimNumber '-\d\+\%(\.\d\+\%([eE][+-]\=\d\+\)\=\)\='
    \ skipwhite nextgroup=vimGlobal,vimSubst,vimCommand,vimComment,vim9Comment

syn match vimNumber '\<0[xX]\x\+'
    \ skipwhite nextgroup=vimGlobal,vimSubst,vimCommand,vimComment,vim9Comment

syn match vimNumber '\%(^\|\A\)\zs#\x\{6}'
    \ skipwhite nextgroup=vimGlobal,vimSubst,vimCommand,vimComment,vim9Comment

syn match vimNumber '\<0[zZ][a-zA-Z0-9.]\+'
    \ skipwhite nextgroup=vimGlobal,vimSubst,vimCommand,vimComment,vim9Comment

syn match vimNumber '0[0-7]\+'
    \ skipwhite nextgroup=vimGlobal,vimSubst,vimCommand,vimComment,vim9Comment

syn match vimNumber '0b[01]\+'
    \ skipwhite nextgroup=vimGlobal,vimSubst,vimCommand,vimComment,vim9Comment

# All vimCommands are contained by vimIsCommand. {{{2

# NOTE(lgc): We have to  include our custom `vimDataType` group  inside the list
# of  groups passed  to the  `nextgroup` argument,  so that  the Vim9  types are
# correctly highlighted in a declaration/assignment at the script level.
syn match vimCmdSep '[:|]\+'
    \ skipwhite
    \ nextgroup=
    \vimDataType,vimAddress,vimAutoCmd,vimEcho,vimIsCommand
    \,vimExtCmd,vimFilter,vimLet,vimMap,vimMark,vimSet,vimSyntax,vimUserCmd

syn match vimIsCommand '\<\h\w*\>' contains=vimCommand
syn match vimVar '\<\h[a-zA-Z0-9#_]*\>' contained
syn match vimVar '\<[bwglstav]:\h[a-zA-Z0-9#_]*\>'
syn match vimVar '\s\zs&\a\+\>'

# NOTE(lgc): New rule to  correctly highlight internal variable  names for which
# the `v:` prefix can be omitted.
syn match vimVar '\<\%(null\|true\|false\)\>'

syn match vimFBVar '\<[bwglstav]:\h[a-zA-Z0-9#_]*\>' contained

# Filetypes {{{2

syn match vimFiletype '\<filet\%[ype]\%(\s\+\I\i*\)*'
    \ skipwhite contains=vimFTCmd,vimFTOption,vimFTError

syn match vimFTError '\I\i*' contained
syn keyword vimFTCmd contained filet[ype]
syn keyword vimFTOption contained detect indent off on plugin

# Augroup : vimAugroupError removed because long augroups caused sync'ing problems. {{{2
# Trade-off: Increasing synclines with slower editing vs augroup END error checking.

syn cluster vimAugroupList contains=
    \vimAugroup,vimIsCommand,vimUserCmd,vimExecute,vimNotFunc,vimFuncName
    \,vimFunction,vimFunctionError,vimLineComment,vimNotFunc,vimMap,vimSpecFile
    \,vimOper,vimNumber,vimOperParen,vimComment,vim9Comment,vimString,vimSubst
    \,vimMark,vimRegister,vimAddress,vimFilter,vimCmplxRepeat,vimComment
    \,vim9Comment,vimLet,vimSet,vimAutoCmd,vimRegion,vimSynLine,vimNotation
    \,vimCtrlChar,vimFuncVar,vimContinue,vimSetEqual,vimOption

syn region vimAugroup matchgroup=vimAugroupKey
    \ start='\<aug\%[roup]\>\ze\s\+\K\k*'
    \ end='\<aug\%[roup]\>\ze\s\+[eE][nN][dD]\>'
    \ contains=vimAutoCmd,@vimAugroupList

syn match vimAugroup 'aug\%[roup]!' contains=vimAugroupKey
syn keyword vimAugroupKey contained aug[roup]

# Operators: {{{2

syn cluster vimOperGroup
    \ contains=vimEnvvar,vimFunc,vimFuncVar,vimOper,vimOperParen,vimNumber
    \,vimString,vimRegister,vimContinue,vim9Comment

syn match vimOper '\%#=1\%(==\|!=\|>=\|<=\|=\~\|!\~\|>\|<\|=\)[?#]\{0,2}'
    \ skipwhite nextgroup=vimString,vimSpecFile

syn match vimOper '\%(\<is\|\<isnot\)[?#]\{0,2}\>'
    \ skipwhite nextgroup=vimString,vimSpecFile

syn match vimOper '||\|&&\|[-+.!]'
    \ skipwhite nextgroup=vimString,vimSpecFile

syn region vimOperParen matchgroup=vimParenSep start='(' end=')'
    \ contains=vimoperStar,@vimOperGroup

syn region vimOperParen matchgroup=vimSep start='#\={' end='}'
    \ contains=@vimOperGroup nextgroup=vimVar,vimFuncVar

syn match vimOperError ')'

# Functions : Tag is provided for those who wish to highlight tagged functions {{{2

syn cluster vimFuncList
    \ contains=vimCommand,vimFunctionError,vimFuncKey,Tag,vimFuncSID

syn cluster vimFuncBodyList contains=
    \vimAbb,vimAddress,vimAugroupKey,vimAutoCmd,vimCmplxRepeat,vimComment
    \,vim9Comment,vimContinue,vimCtrlChar,vimEcho,vimEchoHL,vimEnvvar,vimExecute
    \,vimIsCommand,vimFBVar,vimFunc,vimFunction,vimFuncVar,vimGlobal
    \,vimHighlight,vimIsCommand,vimLet,vimLetHereDoc,vimLineComment,vimMap
    \,vimMark,vimNorm,vimNotation,vimNotFunc,vimNumber,vimOper,vimOperParen
    \,vimRegion,vimRegister,vimSearch,vimSet,vimSpecFile,vimString,vimSubst
    \,vimSynLine,vimUnmap,vimUserCommand

exe 'syn match vimFunction'
    .. ' /'
    .. '\<\%(fu\%[nction]\|def\)!\='
    .. '\s\+\%(<[sS][iI][dD]>\|[sSgGbBwWtTlL]:\)\='
    .. '\%(\i\|[#.]\|{.\{-1,}}\)*'
    .. '\ze\s*('
    .. '/'
    .. ' contains=@vimFuncList nextgroup=vimFuncBody'

syn region vimFuncBody
    \ start='\ze\s*('
    \ matchgroup=vimCommand
    \ end='\<\%(endf\>\|endfu\%[nction]\>\|enddef\>\)'
    \ contained
    \ contains=@vimFuncBodyList

syn match vimFuncVar 'a:\%(\K\k*\|\d\+\)' contained
syn match vimFuncSID '\c<sid>\|\<s:' contained
syn keyword vimFuncKey contained fu[nction]
syn keyword vimFuncKey contained def
syn match vimFuncBlank '\s\+' contained

syn keyword vimPattern contained start skip end

# Special Filenames, Modifiers, Extension Removal: {{{2

syn match vimSpecFile '<c\%(word\|WORD\)>' nextgroup=vimSpecFileMod,vimSubst

syn match vimSpecFile '<\%([acs]file\|amatch\|abuf\)>'
    \ nextgroup=vimSpecFileMod,vimSubst

syn match vimSpecFile '\s%[ \t:]'ms=s+1,me=e-1 nextgroup=vimSpecFileMod,vimSubst
syn match vimSpecFile '\s%$'ms=s+1 nextgroup=vimSpecFileMod,vimSubst
syn match vimSpecFile '\s%<'ms=s+1,me=e-1 nextgroup=vimSpecFileMod,vimSubst
syn match vimSpecFile '#\d\+\|[#%]<\>' nextgroup=vimSpecFileMod,vimSubst
syn match vimSpecFileMod '\%(:[phtre]\)\+' contained

# User-Specified Commands: {{{2

syn cluster vimUserCmdList contains=
    \vimAddress,vimSyntax,vimHighlight,vimAutoCmd,vimCmplxRepeat,vimComment
    \,vim9Comment,vimCtrlChar,vimEscapeBrace,vimFunc,vimFuncName,vimFunction
    \,vimFunctionError,vimIsCommand,vimMark,vimNotation,vimNumber,vimOper
    \,vimRegion,vimRegister,vimLet,vimSet,vimSetEqual,vimSetString,vimSpecFile
    \,vimString,vimSubst,vimSubstRep,vimSubstRange,vimSynLine

syn keyword vimUserCommand contained com[mand]

syn match vimUserCmd '\<com\%[mand]!\=\>.*$' contains=
    \vimUserAttrb,vimUserAttrbError,vimUserCommand,@vimUserCmdList,vimComFilter

syn match vimUserAttrbError '-\a\+\ze\s' contained

syn match vimUserAttrb '-nargs=[01*?+]'
    \ contained
    \ contains=vimUserAttrbKey,vimOper

syn match vimUserAttrb '-complete='
    \ contained
    \ contains=vimUserAttrbKey,vimOper
    \ nextgroup=vimUserAttrbCmplt,vimUserCmdError

syn match vimUserAttrb
    \ '-range\%(=%\|=\d\+\)\='
    \ contained
    \ contains=vimNumber,vimOper,vimUserAttrbKey

syn match vimUserAttrb
    \ '-count\%(=\d\+\)\='
    \ contained
    \ contains=vimNumber,vimOper,vimUserAttrbKey

syn match vimUserAttrb '-bang\>' contained contains=vimOper,vimUserAttrbKey
syn match vimUserAttrb '-bar\>' contained contains=vimOper,vimUserAttrbKey
syn match vimUserAttrb '-buffer\>' contained contains=vimOper,vimUserAttrbKey
syn match vimUserAttrb '-register\>' contained contains=vimOper,vimUserAttrbKey
syn match vimUserCmdError '\S\+\>' contained
syn case ignore

syn keyword vimUserAttrbKey contained
    \ bar ban[g] cou[nt] ra[nge] com[plete] n[args] re[gister]

syn keyword vimUserAttrbCmplt contained
    \ augroup
    \ buffer behave color command compiler cscope dir environment event

syn keyword vimUserAttrbCmplt contained
    \ expression file file_in_path function help locale mapping packadd shellcmd
    \ sign syntax syntime tag tag_listfiles user
    \ filetype
    \ highlight
    \ history
    \ menu
    \ option
    \ var

syn keyword vimUserAttrbCmplt contained custom customlist
    \ nextgroup=vimUserAttrbCmpltFunc,vimUserCmdError

syn match vimUserAttrbCmpltFunc contained
    \ ',\%([sS]:\|<[sS][iI][dD]>\)\=\%(\h\w*\%(#\h\w*\)\+\|\h\w*\)'hs=s+1
    \ nextgroup=vimUserCmdError

syn case match
syn match vimUserAttrbCmplt contained 'custom,\u\w*'

# Lower Priority Comments: after some vim commands... {{{2

syn match vimComment excludenl '\s\@1<="[^\-:.%#=*].*$'
    \ contains=@vimCommentGroup,vimCommentString

syn match vimComment '\%(\<endif\)\@5<=\s\+".*$'
    \ contains=@vimCommentGroup,vimCommentString

syn match vimComment '\%(\<else\)\@4<=\s\+".*$'
    \ contains=@vimCommentGroup,vimCommentString

syn region vimCommentString contained oneline start='\S\s\+"'ms=e end='"'

# Vim9 comments - TODO: might be highlighted while they don't work
syn match vim9Comment excludenl '\s\@1<=#[^{].*$'
    \ contains=@vimCommentGroup,vimCommentString

syn match vim9Comment '\%(\<endif\)\@5<=\s\+#[^{].*$'
    \ contains=@vimCommentGroup,vimCommentString

syn match vim9Comment '\%(\<else\)\@4<=\s\+#[^{].*$'
    \ contains=@vimCommentGroup,vimCommentString

# Vim9 comment inside expression
syn match vim9Comment '\s\zs#[^{].*$'ms=s+1
    \ contains=@vimCommentGroup,vimCommentString

syn match vim9Comment '^\s*#[^{].*$' contains=@vimCommentGroup,vimCommentString
syn match vim9Comment '^\s*#$' contains=@vimCommentGroup,vimCommentString

# Environment Variables: {{{2

syn match vimEnvvar '\$\I\i*'
syn match vimEnvvar '\${\I\i*}'

# In-String Specials: {{{2

# Try to catch strings, if nothing else matches (therefore it must precede the others!)
# vimEscapeBrace handles ["]  []"] (ie. "s don't terminate string inside [])
syn region vimEscapeBrace oneline contained transparent
    \ start='[^\\]\%(\\\\\)*\[\zs\^\=\]\=' skip='\\\\\|\\\]' end=']'me=e-1

syn match vimPatSepErr contained '\\)'
syn match vimPatSep contained '\\|'

syn region vimPatSepZone oneline contained matchgroup=vimPatSepZ
    \ start='\\%\=\ze('
    \ skip='\\\\'
    \ end=/\\)\|[^\\]['"]/
    \ contains=@vimStringGroup

syn region vimPatRegion contained transparent matchgroup=vimPatSepR
    \ start='\\[z%]\=(' end='\\)' contains=@vimSubstList oneline

syn match vimNotPatSep contained '\\\\'

syn cluster vimStringGroup contains=
    \vimEscapeBrace,vimPatSep,vimNotPatSep,vimPatSepErr,vimPatSepZone,@Spell

syn region vimString oneline keepend
    \ start=/[^a-zA-Z>!\\@]\@1<="/
    \ skip=/\\\\\|\\"/
    \ matchgroup=vimStringEnd
    \ end=/"/
    \ contains=@vimStringGroup

syn region vimString oneline keepend start=/[^a-zA-Z>!\\@]\@1<='/ end=/'/

syn region vimString oneline
    \ start=/=\@1<=!/
    \ skip=/\\\\\|\\!/
    \ end=/!/
    \ contains=@vimStringGroup

syn region vimString oneline
    \ start='=\@1<=+'
    \ skip='\\\\\|\\+'
    \ end='+'
    \ contains=@vimStringGroup

syn match vimString contained '"[^"]*\\$' skipnl nextgroup=vimStringCont
syn match vimStringCont contained '\%(\\\\\|.\)\{-}[^\\]"'

# Substitutions: {{{2

syn cluster vimSubstList contains=
    \vimPatSep,vimPatRegion,vimPatSepErr,vimSubstTwoBS,vimSubstRange,vimNotation

syn cluster vimSubstRepList contains=vimSubstSubstr,vimSubstTwoBS,vimNotation
syn cluster vimSubstList add=vimCollection

exe 'syn match vimSubst'
    .. ' /'
    ..     '\%(:\+\s*\|^\s*\||\s*\)'
    ..     '\<\%(\<s\%[ubstitute]\>\|\<sm\%[agic]\>\|\<sno\%[magic]\>\)'
    ..     '[:#[:alpha:]]\@!'
    .. '/'
    .. ' nextgroup=vimSubstPat'

syn match vimSubst /\%(^\|[^\\\"']\)\<s\%[ubstitute]\>[:#[:alpha:]\"']\@!/
    \ nextgroup=vimSubstPat contained

syn match vimSubst '/\zs\<s\%[ubstitute]\>\ze/' nextgroup=vimSubstPat
syn match vimSubst '\%(:\+\s*\|^\s*\)s\ze#.\{-}#.\{-}#' nextgroup=vimSubstPat
syn match vimSubst1 contained '\<s\%[ubstitute]\>' nextgroup=vimSubstPat
syn match vimSubst2 contained 's\%[ubstitute]\>' nextgroup=vimSubstPat

syn region vimSubstPat contained matchgroup=vimSubstDelim
    \ start='\z([^a-zA-Z( \t[\]&]\)'rs=s+1 skip='\\\\\|\\\z1'
    \ end='\z1're=e-1,me=e-1
    \ contains=@vimSubstList nextgroup=vimSubstRep4 oneline

syn region vimSubstRep4 contained matchgroup=vimSubstDelim
    \ start='\z(.\)' skip='\\\\\|\\\z1'
    \ end='\z1' matchgroup=vimNotation end='<[cC][rR]>'
    \ contains=@vimSubstRepList nextgroup=vimSubstFlagErr oneline

syn region vimCollection contained transparent
    \ start='\\\@<!\[' skip='\\\['
    \ end='\]'
    \ contains=vimCollClass

syn match vimCollClassErr contained '\[:.\{-\}:\]'

exe 'syn match vimCollClass contained transparent'
    .. ' /\%#=1\[:'
    .. '\%('
    ..         'alnum\|alpha\|blank\|cntrl\|digit\|graph\|lower\|print\|punct'
    .. '\|' .. 'space\|upper\|xdigit\|return\|tab\|escape\|backspace'
    .. '\)'
    .. ':\]/'

syn match vimSubstSubstr contained '\\z\=\d'
syn match vimSubstTwoBS contained '\\\\'
syn match vimSubstFlagErr contained '[^< \t\r|]\+' contains=vimSubstFlags
syn match vimSubstFlags contained '[&cegiIlnpr#]\+'

# 'String': {{{2

syn match vimString /[^(,]'[^']\{-}\zs'/

# Marks, Registers, Addresses, Filters: {{{2

syn match vimMark /'[a-zA-Z0-9]\ze[-+,!]/
    \ nextgroup=vimFilter,vimMarkNumber,vimSubst

syn match vimMark /'[<>]\ze[-+,!]/ nextgroup=vimFilter,vimMarkNumber,vimSubst
syn match vimMark /,\zs'[<>]\ze/ nextgroup=vimFilter,vimMarkNumber,vimSubst

syn match vimMark /[!,:]\zs'[a-zA-Z0-9]/
    \ nextgroup=vimFilter,vimMarkNumber,vimSubst

syn match vimMark /\<norm\%[al]\s\zs'[a-zA-Z0-9]/
    \ nextgroup=vimFilter,vimMarkNumber,vimSubst

syn match vimMarkNumber '[-+]\d\+'
    \ contained contains=vimOper nextgroup=vimSubst2

syn match vimPlainMark contained /'[a-zA-Z0-9]/

syn match vimRange /[`'][a-zA-Z0-9],[`'][a-zA-Z0-9]/
    \ contains=vimMark skipwhite nextgroup=vimFilter

syn match vimRegister '[^,;[{: \t]\zs"[a-zA-Z0-9.%#:_\-/]\ze[^a-zA-Z_":0-9]'
syn match vimRegister '\<norm\s\+\zs"[a-zA-Z0-9]'
syn match vimRegister '\<normal\s\+\zs"[a-zA-Z0-9]'
syn match vimRegister '@"'
syn match vimPlainRegister contained '"[a-zA-Z0-9\-:.%#*+=]'

syn match vimAddress ',\zs[.$]' skipwhite nextgroup=vimSubst1
syn match vimAddress '%\ze\a' skipwhite nextgroup=vimString,vimSubst1

syn match vimFilter /^!!\=[^"]\{-}\%(|\|\ze\"\|$\)/ contains=vimOper,vimSpecFile

syn match vimFilter contained /!!\=[^"]\{-}\%(|\|\ze\"\|$\)/
    \ contains=vimOper,vimSpecFile

syn match vimComFilter contained /|!!\=[^"]\{-}\%(|\|\ze\"\|$\)/
    \ contains=vimOper,vimSpecFile

# Complex Repeats: (:h complex-repeat) {{{2

syn match vimCmplxRepeat '[^a-zA-Z_/\\()]\@1<=q[0-9a-zA-Z"]\>'
syn match vimCmplxRepeat '@[0-9a-z".=@:]\ze\%($\|[^a-zA-Z]\>\)'

# Set command and associated set-options (vimOptions) with comment {{{2

syn region vimSet matchgroup=vimCommand
    \ start='\<\%(setl\%[ocal]\|setg\%[lobal]\|se\%[t]\)\>' skip='\%(\\\\\)*\\.'
    \ end='$' end='|' matchgroup=vimNotation end='<[cC][rR]>'
    \ keepend oneline
    \ contains=vimSetEqual,vimOption,vimErrSetting,vimComment,vim9Comment
    \,vimSetString,vimSetMod

syn region vimSetEqual
    \ start='[=:]\|[-+^]='
    \ skip='\\\\\|\\\s'
    \ end='[| \t]\|$'me=e-1
    \ contained
    \ contains=vimCtrlChar,vimSetSep,vimNotation,vimEnvvar
    \ oneline

syn region vimSetString
    \ start=/="/hs=s+1
    \ skip=/\\\\\|\\"/
    \ end=/"/
    \ contained
    \ contains=vimCtrlChar

syn match vimSetSep contained '[,:]'
syn match vimSetMod contained '&vim\=\|[!&?<]\|all&'

# Let: {{{2

syn keyword vimLet let unl[et]
    \ skipwhite nextgroup=vimVar,vimFuncVar,vimLetHereDoc

# Abbreviations: {{{2

syn keyword vimAbb ab[breviate] ca[bbrev] inorea[bbrev] cnorea[bbrev]
    \ norea[bbrev] ia[bbrev]
    \ skipwhite nextgroup=vimMapMod,vimMapLhs

# Autocmd: {{{2

syn match vimAutoEventList contained '\%(!\s\+\)\=\%(\a\+,\)*\a\+'
    \ contains=vimAutoEvent nextgroup=vimAutoCmdSpace

syn match vimAutoCmdSpace contained '\s\+' nextgroup=vimAutoCmdSfxList
syn match vimAutoCmdSfxList contained '\S*' skipwhite nextgroup=vimAutoCmdMod

syn keyword vimAutoCmd au[tocmd] do[autocmd] doautoa[ll]
    \ skipwhite nextgroup=vimAutoEventList

syn match vimAutoCmdMod '\%(++\)\=\%(once\|nested\)'

# Echo And Execute: -- prefer strings! {{{2

syn region vimEcho oneline excludenl matchgroup=vimCommand
    \ start='\<ec\%[ho]\>' skip='\%(\\\\\)*\\|'
    \ end='$\||'
    \ contains=vimFunc,vimFuncVar,vimString,vimVar

syn region vimExecute oneline excludenl matchgroup=vimCommand
    \ start='\<exe\%[cute]\>' skip='\%(\\\\\)*\\|'
    \ end='$\||\|<[cC][rR]>'
    \ contains=vimFuncVar,vimIsCommand,vimOper,vimNotation,vimOperParen,vimString,vimVar

syn match vimEchoHL 'echohl\='
    \ skipwhite nextgroup=vimGroup,vimHLGroup,vimEchoHLNone

syn case ignore
syn keyword vimEchoHLNone none
syn case match

# Maps: {{{2

syn match vimMap '\<map\>!\=\ze\s*[^(]' skipwhite nextgroup=vimMapMod,vimMapLhs

syn keyword vimMap cm[ap] cno[remap] im[ap] ino[remap] lm[ap] ln[oremap] nm[ap]
    \ nn[oremap] no[remap] om[ap] ono[remap] smap snor[emap] tno[remap] tm[ap]
    \ vm[ap] vn[oremap] xm[ap] xn[oremap]
    \ skipwhite
    \ nextgroup=vimMapBang,vimMapMod,vimMapLhs

syn keyword vimMap
    \ mapc[lear] smapc[lear] cmapc[lear] imapc[lear] lmapc[lear]
    \ nmapc[lear] omapc[lear] tmapc[lear] vmapc[lear] xmapc[lear]

syn keyword vimUnmap
    \ cu[nmap] iu[nmap] lu[nmap] nun[map] ou[nmap] sunm[ap]
    \ tunma[p] unm[ap] unm[ap] vu[nmap] xu[nmap]
    \ skipwhite nextgroup=vimMapBang,vimMapMod,vimMapLhs

syn match vimMapLhs contained '\S\+' contains=vimNotation,vimCtrlChar
    \ skipwhite nextgroup=vimMapRhs

syn match vimMapBang contained '!' skipwhite nextgroup=vimMapMod,vimMapLhs

exe 'syn match vimMapMod contained '
    .. '/'
    .. '\%#=1\c'
    .. '<' .. '\%('
    ..         'buffer\|expr\|\%(local\)\=leader'
    .. '\|' .. 'nowait\|plug\|script\|sid\|unique\|silent'
    .. '\)\+' .. '>'
    .. '/'
    .. ' contains=vimMapModKey,vimMapModErr'
    .. ' nextgroup=vimMapMod,vimMapLhs'
    .. ' skipwhite'

syn match vimMapRhs contained '.*' contains=vimNotation,vimCtrlChar
    \ skipnl nextgroup=vimMapRhsExtend

syn match vimMapRhsExtend contained '^\s*\\.*$' contains=vimContinue
syn case ignore

syn keyword vimMapModKey contained
    \ buffer expr leader localleader nowait plug script sid silent unique

syn case match

# Menus: {{{2

syn cluster vimMenuList
    \ contains=vimMenuBang,vimMenuPriority,vimMenuName,vimMenuMod

syn keyword vimCommand am[enu] an[oremenu] aun[menu] cme[nu] cnoreme[nu]
    \ cunme[nu] ime[nu] inoreme[nu] iunme[nu] me[nu] nme[nu] nnoreme[nu]
    \ noreme[nu] nunme[nu] ome[nu] onoreme[nu] ounme[nu] unme[nu] vme[nu]
    \ vnoreme[nu] vunme[nu]
    \ skipwhite nextgroup=@vimMenuList

syn match vimMenuName '[^ \t\\<]\+'
    \ contained nextgroup=vimMenuNameMore,vimMenuMap

syn match vimMenuPriority '\d\+\%(\.\d\+\)*'
    \ contained skipwhite nextgroup=vimMenuName

syn match vimMenuNameMore '\c\\\s\|<tab>\|\\\.' contained
    \ nextgroup=vimMenuName,vimMenuNameMore contains=vimNotation

syn match vimMenuMod contained '\c<\%(script\|silent\)\+>' skipwhite
    \ contains=vimMapModKey,vimMapModErr nextgroup=@vimMenuList

syn match vimMenuMap '\s' contained skipwhite nextgroup=vimMenuRhs

syn match vimMenuRhs '.*$'
    \ contained contains=vimString,vimComment,vim9Comment,vimIsCommand

syn match vimMenuBang '!' contained skipwhite nextgroup=@vimMenuList

# Angle-Bracket Notation: {{{2

syn case ignore
exe 'syn match vimNotation'
    .. ' /'
    .. '\%#=1\%(\\\|<lt>\)\='
    .. '<' .. '\%([scamd]-\)\{0,4}x\='
    .. '\%('
    .. 'f\d\{1,2}\|[^ \t:]\|cmd\|cr\|lf\|linefeed\|return\|k\=del\%[ete]'
    .. '\|' .. 'bs\|backspace\|tab\|esc\|right\|left\|help\|undo\|insert\|ins'
    .. '\|' .. 'mouse\|k\=home\|k\=end\|kplus\|kminus\|kdivide\|kmultiply'
    .. '\|' .. 'kenter\|kpoint\|space\|k\=\%(page\)\=\%(\|down\|up\|k\d\>\)'
    .. '\)' .. '>'
    .. '/'
    .. ' contains=vimBracket'

exe 'syn match vimNotation '
    .. '/'
    .. '\%#=1\%(\\\|<lt>\)\='
    .. '<'
    .. '\%([scam2-4]-\)\{0,4}'
    .. '\%(right\|left\|middle\)'
    .. '\%(mouse\)\='
    .. '\%(drag\|release\)\='
    .. '>'
    .. '/'
    .. ' contains=vimBracket'

syn match vimNotation
    \ '\%#=1\%(\\\|<lt>\)\=<\%(bslash\|plug\|sid\|space\|bar\|nop\|nul\|lt\)>'
    \ contains=vimBracket

syn match vimNotation '\%(\\\|<lt>\)\=<C-R>[0-9a-z"%#:.\-=]'he=e-1
    \ contains=vimBracket

exe 'syn match vimNotation '
    .. '/'
    .. '\%#=1\%(\\\|<lt>\)\='
    .. '<'
    .. '\%(q-\)\='
    .. '\%(line[12]\|count\|bang\|reg\|args\|mods\|f-args\|f-mods\|lt\)'
    .. '>'
    .. '/'
    .. ' contains=vimBracket'

syn match vimNotation
    \ '\%#=1\%(\\\|<lt>\)\=<\%([cas]file\|abuf\|amatch\|cword\|cWORD\|client\)>'
    \ contains=vimBracket

syn match vimBracket contained '[\\<>]'
syn case match

# User Function Highlighting: {{{2
# (following Gautam Iyer's suggestion)

exe 'syn match vimFunc '
    .. '/'
    .. '\%('
    .. '\%([sSgGbBwWtTlL]:\|<[sS][iI][dD]>\)' .. '\='
    .. '\%(\w\+\.\)*' .. '\I[a-zA-Z0-9_.]*'
    .. '\)'
    .. '\ze\s*('
    .. '/'
    .. ' contains=vimFuncName,vimUserFunc,vimExecute'

exe 'syn match vimUserFunc contained '
    .. '/'
    .. '\%('
    .. '\%([sSgGbBwWtTlL]:\|<[sS][iI][dD]>\)' .. '\='
    .. '\%(\w\+\.\)*'
    .. '\I[a-zA-Z0-9_.]*'
    .. '\)'
    .. '\|' .. '\<\u[a-zA-Z0-9.]*\>'
    .. '\|' .. '\<if\>'
    .. '/'
    .. ' contains=vimNotation'

# User Command Highlighting: {{{2

syn match vimUsrCmd '^\s*\zs\u\w*.*$'

# Errors And Warnings: {{{2

syn match vimFunctionError '\s\zs[a-z0-9]\i\{-}\ze\s*('
    \ contained contains=vimFuncKey,vimFuncBlank

exe 'syn match vimFunctionError '
    .. '/'
    .. '\s\zs\%(<[sS][iI][dD]>\|[sSgGbBwWtTlL]:\)'
    .. '\d\i\{-}\ze\s*('
    .. '/'
    .. ' contained contains=vimFuncKey,vimFuncBlank'
syn match vimElseIfErr '\<else\s\+if\>'
syn match vimBufnrWarn /\<bufnr\s*(\s*["']\.['"]\s*)/

syn match vimNotFunc '\<if\>\|\<el\%[seif]\>\|\<return\>\|\<while\>'
    \ skipwhite nextgroup=vimOper,vimOperParen,vimVar,vimFunc,vimNotation

# Norm: {{{2

syn match vimNorm '\<norm\%[al]!\=' skipwhite nextgroup=vimNormCmds
syn match vimNormCmds contained '.*$'

# Syntax: {{{2

syn match vimGroupList '@\=[^ \t,]*'
    \ contained contains=vimGroupSpecial,vimPatSep

syn match vimGroupList contained '@\=[^ \t,]*,'
    \ nextgroup=vimGroupList contains=vimGroupSpecial,vimPatSep

syn keyword vimGroupSpecial contained ALL ALLBUT CONTAINED TOP
syn match vimSynError '\i\+' contained
syn match vimSynError '\i\+=' contained nextgroup=vimGroupList

syn match vimSynContains '\<contain\%(s\|edin\)='
    \ contained nextgroup=vimGroupList

syn match vimSynKeyContainedin '\<containedin=' contained nextgroup=vimGroupList
syn match vimSynNextgroup 'nextgroup=' contained nextgroup=vimGroupList

syn match vimSyntax '\<sy\%[ntax]\>' contains=vimCommand skipwhite
    \ nextgroup=vimSynType,vimComment,vim9Comment

syn match vimAuSyntax contained '\s+sy\%[ntax]' contains=vimCommand skipwhite
    \ nextgroup=vimSynType,vimComment,vim9Comment

syn cluster vimFuncBodyList add=vimSyntax

# Syntax: case {{{2

syn keyword vimSynType contained case skipwhite
    \ nextgroup=vimSynCase,vimSynCaseError

syn match vimSynCaseError contained '\i\+'
syn keyword vimSynCase contained ignore match

# Syntax: clear {{{2

syn keyword vimSynType contained clear skipwhite nextgroup=vimGroupList

# Syntax: cluster {{{2

syn keyword vimSynType contained cluster skipwhite nextgroup=vimClusterName

syn region vimClusterName contained
    \ matchgroup=vimGroupName start='\h\w*' skip='\\\\\|\\|'
    \ matchgroup=vimSep end='$\||'
    \ contains=vimGroupAdd,vimGroupRem,vimSynContains,vimSynError

syn match vimGroupAdd contained 'add=' nextgroup=vimGroupList
syn match vimGroupRem contained 'remove=' nextgroup=vimGroupList
syn cluster vimFuncBodyList add=vimSynType,vimGroupAdd,vimGroupRem

# Syntax: iskeyword {{{2

syn keyword vimSynType contained iskeyword skipwhite nextgroup=vimIskList
syn match vimIskList contained '\S\+' contains=vimIskSep
syn match vimIskSep contained ','

# Syntax: include {{{2

syn keyword vimSynType contained include skipwhite nextgroup=vimGroupList
syn cluster vimFuncBodyList add=vimSynType

# Syntax: keyword {{{2

syn cluster vimSynKeyGroup
    \ contains=vimSynNextgroup,vimSynKeyOpt,vimSynKeyContainedin

syn keyword vimSynType contained keyword skipwhite nextgroup=vimSynKeyRegion

syn region vimSynKeyRegion contained oneline keepend
    \ matchgroup=vimGroupName start='\h\w*' skip='\\\\\|\\|'
    \ matchgroup=vimSep end='|\|$'
    \ contains=@vimSynKeyGroup

syn match vimSynKeyOpt contained
    \ '\%#=1\<\%(conceal\|contained\|transparent\|skipempty\|skipwhite\|skipnl\)\>'

syn cluster vimFuncBodyList add=vimSynType

# Syntax: match {{{2

syn cluster vimSynMtchGroup contains=
    \vimMtchComment,vimSynContains,vimSynError,vimSynMtchOpt,vimSynNextgroup
    \,vimSynRegPat,vimNotation,vim9Comment

syn keyword vimSynType contained match skipwhite nextgroup=vimSynMatchRegion

syn region vimSynMatchRegion contained keepend
    \ matchgroup=vimGroupName start='\h\w*'
    \ matchgroup=vimSep end='|\|$'
    \ contains=@vimSynMtchGroup

exe 'syn match vimSynMtchOpt contained '
    .. '/'
    .. '\%#=1'
    .. '\<\%('
    ..         'conceal\|transparent\|contained\|excludenl\|keepend\|skipempty'
    .. '\|' .. 'skipwhite\|display\|extend\|skipnl\|fold'
    .. '\)\>'
    .. '/'

syn match vimSynMtchOpt contained '\<cchar=' nextgroup=vimSynMtchCchar
syn match vimSynMtchCchar contained '\S'
syn cluster vimFuncBodyList add=vimSynMtchGroup

# Syntax: off and on {{{2

syn keyword vimSynType contained enable list manual off on reset

# Syntax: region {{{2

syn cluster vimSynRegPatGroup contains=
    \vimPatSep,vimNotPatSep,vimSynPatRange,vimSynNotPatRange,vimSubstSubstr
    \,vimPatRegion,vimPatSepErr,vimNotation

syn cluster vimSynRegGroup contains=
    \vimSynContains,vimSynNextgroup,vimSynRegOpt,vimSynReg,vimSynMtchGrp

syn keyword vimSynType contained region skipwhite nextgroup=vimSynRegion

syn region vimSynRegion contained keepend
    \ matchgroup=vimGroupName start='\h\w*' skip='\\\\\|\\|'
    \ end='|\|$' contains=@vimSynRegGroup

exe 'syn match vimSynRegOpt contained '
    .. '/'
    .. '\%#=1'
    .. '\<\%('
    ..         'conceal\%(ends\)\=\|transparent\|contained\|excludenl'
    .. '\|' .. 'skipempty\|skipwhite\|display\|keepend\|oneline\|extend\|skipnl'
    .. '\|' .. 'fold'
    .. '\)\>'
    .. '/'

syn match vimSynReg '\%(start\|skip\|end\)='he=e-1
    \ contained nextgroup=vimSynRegPat

syn match vimSynMtchGrp 'matchgroup=' contained nextgroup=vimGroup,vimHLGroup

syn region vimSynRegPat contained extend
    \ start=|\z([-`~!@#$%^&*_=+;:'",./?]\)| skip=/\\\\\|\\\z1/
    \ end='\z1'
    \ contains=@vimSynRegPatGroup skipwhite nextgroup=vimSynPatMod,vimSynReg

syn match vimSynPatMod
    \ '\%#=1\%(hs\|ms\|me\|hs\|he\|rs\|re\)=[se]\%([-+]\d\+\)\=' contained

syn match vimSynPatMod contained
    \ '\%#=1\%(hs\|ms\|me\|hs\|he\|rs\|re\)=[se]\%([-+]\d\+\)\=,'
    \ nextgroup=vimSynPatMod

syn region vimSynPatRange contained start='\[' skip='\\\\\|\\]' end=']'
syn match vimSynNotPatRange contained '\\\\\|\\\['
syn match vimMtchComment contained '"[^"]\+$'
syn cluster vimFuncBodyList add=vimSynType

# Syntax: sync {{{2

syn keyword vimSynType contained sync skipwhite
    \ nextgroup=vimSyncC,vimSyncLines,vimSyncMatch,vimSyncError,vimSyncLinebreak
    \,vimSyncLinecont,vimSyncRegion

syn match vimSyncError contained '\i\+'
syn keyword vimSyncC contained ccomment clear fromstart
syn keyword vimSyncMatch contained match skipwhite nextgroup=vimSyncGroupName
syn keyword vimSyncRegion contained region skipwhite nextgroup=vimSynReg

syn match vimSyncLinebreak '\<linebreaks='
    \ contained nextgroup=vimNumber skipwhite

syn keyword vimSyncLinecont contained linecont skipwhite nextgroup=vimSynRegPat
syn match vimSyncLines contained '\%(min\|max\)\=lines=' nextgroup=vimNumber
syn match vimSyncGroupName contained '\h\w*' skipwhite nextgroup=vimSyncKey

syn match vimSyncKey '\<groupthere\|grouphere\>'
    \ contained nextgroup=vimSyncGroup skipwhite

syn match vimSyncGroup '\h\w*'
    \ contained nextgroup=vimSynRegPat,vimSyncNone skipwhite

syn keyword vimSyncNone contained NONE

# Additional IsCommand: here by reasons of precedence {{{2

syn match vimIsCommand '<Bar>\s*\a\+'
    \ contains=vimCommand,vimNotation transparent

# Highlighting: {{{2

syn cluster vimHighlightCluster
    \ contains=vimHiLink,vimHiClear,vimHiKeyList,vimComment,vim9Comment

syn match vimHiCtermError contained '\D\i*'

syn match vimHighlight '\<hi\%[ghlight]\>'
    \ nextgroup=vimHiBang,@vimHighlightCluster skipwhite

syn match vimHiBang contained '!' skipwhite nextgroup=@vimHighlightCluster

syn match vimHiGroup contained '\i\+'

syn case ignore
syn keyword vimHiAttrib contained
    \ none bold inverse italic nocombine reverse standout strikethrough
    \ underline undercurl

syn keyword vimFgBgAttrib contained none bg background fg foreground
syn case match
syn match vimHiAttribList contained '\i\+' contains=vimHiAttrib

syn match vimHiAttribList '\i\+,'he=e-1
    \ contained contains=vimHiAttrib nextgroup=vimHiAttribList

syn case ignore
syn keyword vimHiCtermColor contained
    \ black blue brown cyan darkblue darkcyan darkgray darkgreen darkgrey
    \ darkmagenta darkred darkyellow gray green grey lightblue lightcyan
    \ lightgray lightgreen lightgrey lightmagenta lightred magenta red white
    \ yellow

syn match vimHiCtermColor contained '\<color\d\{1,3}\>'

syn case match
syn match vimHiFontname contained '[a-zA-Z\-*]\+'
syn match vimHiGuiFontname contained /'[a-zA-Z\-* ]\+'/
syn match vimHiGuiRgb contained '#\x\{6}'

# Highlighting: hi group key=arg ... {{{2

syn cluster vimHiCluster
    \ contains=vimGroup,vimHiGroup,vimHiTerm,vimHiCTerm,vimHiStartStop
    \,vimHiCtermFgBg,vimHiCtermul,vimHiGui,vimHiGuiFont,vimHiGuiFgBg
    \,vimHiKeyError,vimNotation

syn region vimHiKeyList contained oneline
    \ start='\i\+' skip='\\\\\|\\|'
    \ end='$\||' contains=@vimHiCluster

syn match vimHiKeyError contained '\i\+='he=e-1
syn match vimHiTerm contained '\cterm='he=e-1 nextgroup=vimHiAttribList

syn match vimHiStartStop '\c\%(start\|stop\)='he=e-1
    \ contained nextgroup=vimHiTermcap,vimOption

syn match vimHiCTerm contained '\ccterm='he=e-1 nextgroup=vimHiAttribList

syn match vimHiCtermFgBg contained '\ccterm[fb]g='he=e-1
    \ nextgroup=vimHiNmbr,vimHiCtermColor,vimFgBgAttrib,vimHiCtermError

syn match vimHiCtermul contained '\cctermul='he=e-1
    \ nextgroup=vimHiNmbr,vimHiCtermColor,vimFgBgAttrib,vimHiCtermError

syn match vimHiGui contained '\cgui='he=e-1 nextgroup=vimHiAttribList
syn match vimHiGuiFont contained '\cfont='he=e-1 nextgroup=vimHiFontname

syn match vimHiGuiFgBg contained '\cgui\%([fb]g\|sp\)='he=e-1
    \ nextgroup=vimHiGroup,vimHiGuiFontname,vimHiGuiRgb,vimFgBgAttrib

syn match vimHiTermcap contained '\S\+' contains=vimNotation
syn match vimHiNmbr contained '\d\+'

# Highlight: clear {{{2

syn keyword vimHiClear contained clear nextgroup=vimHiGroup

# Highlight: link {{{2
# see tst24 (hi def vs hi) (Jul 06, 2018)

exe 'syn region vimHiLink'
    .. ' matchgroup=vimCommand'
    .. ' start=/'
    .. '\%(\<hi\%[ghlight]\s\+\)\@<='
    .. '\%(\%(def\%[ault]\s\+\)\=link\>\|\<def\>\)'
    .. '/'
    .. ' end=/$/'
    .. ' contained contains=@vimHiCluster oneline'

syn cluster vimFuncBodyList add=vimHiLink

# Control Characters: {{{2

syn match vimCtrlChar '[\x01-\x08\x0b\x0f-\x1f]'

# Beginners - Patterns that involve ^ {{{2

syn match vimLineComment '^[ \t:]*".*$'
    \ contains=@vimCommentGroup,vimCommentString,vimCommentTitle

syn match vim9LineComment '^[ \t:]\+#.*$'
    \ contains=@vimCommentGroup,vimCommentString,vimCommentTitle

# NOTE(lgc): We've tweaked the original rule.{{{
#
# A title in a Vim9 comment was not highlighted.
# https://github.com/vim/vim/issues/6599
#
# ---
#
# Also, we could not include a user name inside parens:
#
#     NOTE(user): some comment
#         ^----^
#}}}
# `hs=s+1` is necessary to not highlight the comment leader.{{{
#
#     hs=s+1
#     │  │
#     │  └ start of the matched pattern
#     └ offset for where the highlighting starts
#
# See `:h :syn-pattern-offset`:
#}}}
syn match vimCommentTitle '["#]\s*\u\%(\w\|[()]\)*\%(\s\+\u\w*\)*:'hs=s+1
    \ contained contains=vimCommentTitleLeader,vimTodo,@vimCommentGroup

syn match vimContinue '^\s*\\'

syn region vimString start=/^\s*\\\z(['"]\)/ skip=/\\\\\|\\\z1/ end=/\z1/
    \ oneline keepend contains=@vimStringGroup,vimContinue

syn match vimCommentTitleLeader '"\s\+'ms=s+1 contained

# Searches And Globals: {{{2

syn match vimSearch '^\s*[/?].*' contains=vimSearchDelim
syn match vimSearchDelim '^\s*\zs[/?]\|[/?]$' contained

syn region vimGlobal matchgroup=Statement
    \ start='\<g\%[lobal]!\=/'
    \ skip='\\.'
    \ end='/'
    \ nextgroup=vimSubst
    \ skipwhite

syn region vimGlobal matchgroup=Statement
    \ start='\<v\%[global]!\=/'
    \ skip='\\.'
    \ end='/'
    \ nextgroup=vimSubst
    \ skipwhite

# Embedded Scripts:  {{{2

unlet! b:current_syntax
syn include @vimPythonScript syntax/python.vim

syn region vimPythonRegion matchgroup=vimScriptDelim
    \ start=/py\%[thon][3x]\=\s*<<\s*\z(\S*\)\ze\%(\s*#.*\)\=$/
    \ end=/^\z1\ze\%(\s*".*\)\=$/
    \ contains=@vimPythonScript

syn region vimPythonRegion matchgroup=vimScriptDelim
    \ start=/py\%[thon][3x]\=\s*<<\s*$/
    \ end=/\.$/
    \ contains=@vimPythonScript

syn region vimPythonRegion matchgroup=vimScriptDelim
    \ start=/Py\%[thon]2or3\s*<<\s*\z(\S*\)\ze\%(\s*#.*\)\=$/
    \ end=/^\z1\ze\%(\s*".*\)\=$/
    \ contains=@vimPythonScript

syn region vimPythonRegion matchgroup=vimScriptDelim
    \ start=/Py\%[thon]2or3\=\s*<<\s*$/
    \ end=/\.$/
    \ contains=@vimPythonScript

syn cluster vimFuncBodyList add=vimPythonRegion

unlet! b:current_syntax
syn include @vimLuaScript syntax/lua.vim

syn region vimLuaRegion matchgroup=vimScriptDelim
    \ start=/lua\s*<<\s*\z(.*\)$/
    \ end=/^\z1$/
    \ contains=@vimLuaScript

syn region vimLuaRegion matchgroup=vimScriptDelim
    \ start=/lua\s*<<\s*$/
    \ end=/\.$/
    \ contains=@vimLuaScript

syn cluster vimFuncBodyList add=vimLuaRegion

# Synchronize (speed) {{{2

syn sync maxlines=60
# TODO(lgc): We need `silent!` to suppress a possible E403 error.{{{
#
# To reproduce, write this text in `/tmp/md.md`:
# https://raw.githubusercontent.com/k-takata/minpac/master/README.md
#
# Then, open the `/tmp/md.md` file:
#
#     Error detected while processing BufRead Autocommands for "*.md"
#         ..FileType Autocommands for "*"
#         ..Syntax Autocommands for "*"
#         ..function <SNR>24_SynSet[25]
#         ..script ~/.vim/pack/mine/opt/markdown/syntax/markdown.vim[835]
#         ..function markdown#highlightLanguages[57]
#         ..script ~/.vim/pack/mine/opt/vim/syntax/vim.vim:
#     line  553:
#     E403: syntax sync: line continuations pattern specified twice
#
# Is  there something  wrong in  how we  syntax highlight  fenced codeblocks  in
# markdown files?  Is there a better fix?
#}}}
sil! syn sync linecont '^\s\+\\'
syn sync match vimAugroupSyncA groupthere NONE '\<aug\%[roup]\>\s\+[eE][nN][dD]'
#}}}1

# Highlight Groups {{{1

hi link vimCollClassErr vimError
hi link vimErrSetting vimError
hi link vimFTError vimError
hi link vimFunctionError vimError
hi link vimFunc vimError
hi link vimHiAttribList vimError
hi link vimHiCtermError vimError
hi link vimHiKeyError vimError
hi link vimMapModErr vimError
hi link vimSubstFlagErr vimError
hi link vimSynCaseError vimError
hi link vimBufnrWarn vimWarn

hi link vimAbb vimCommand
hi link vimAddress vimMark
hi link vimAugroupError vimError
hi link vimAugroupKey vimCommand
hi link vimAutoCmd vimCommand
hi link vimAutoEvent Type
hi link vimAutoCmdMod Special
hi link vimBracket Delimiter
hi link vimCmplxRepeat SpecialChar
hi link vimCommand Statement
hi link vimComment Comment
hi link vim9Comment Comment
hi link vimCommentString vimString
hi link vimCommentTitle PreProc
hi link vimCondHL vimCommand
hi link vimContinue Special
hi link vimCtrlChar SpecialChar
hi link vimEchoHLNone vimGroup
hi link vimEchoHL vimCommand
hi link vimElseIfErr Error
hi link vimEnvvar PreProc
hi link vimError Error
hi link vimFBVar vimVar
hi link vimFgBgAttrib vimHiAttrib
hi link vimHiCtermul vimHiTerm
hi link vimFTCmd vimCommand
hi link vimFTOption vimSynType
hi link vimFuncKey vimCommand
hi link vimFuncName Function
hi link vimFuncSID Special
hi link vimFuncVar Identifier
hi link vimGroupAdd vimSynOption
hi link vimGroupName vimGroup
hi link vimGroupRem vimSynOption
hi link vimGroupSpecial Special
hi link vimGroup Type
hi link vimHiAttrib PreProc
hi link vimHiClear vimHighlight
hi link vimHiCtermFgBg vimHiTerm
hi link vimHiCTerm vimHiTerm
hi link vimHighlight vimCommand
hi link vimHiGroup vimGroupName
hi link vimHiGuiFgBg vimHiTerm
hi link vimHiGuiFont vimHiTerm
hi link vimHiGuiRgb vimNumber
hi link vimHiGui vimHiTerm
hi link vimHiNmbr Number
hi link vimHiStartStop vimHiTerm
hi link vimHiTerm Type
hi link vimHLGroup vimGroup
hi link vimIskSep Delimiter
hi link vimLet vimCommand
hi link vimLetHereDoc vimString
hi link vimLetHereDocStart Special
hi link vimLetHereDocStop Special
hi link vimLineComment vimComment
hi link vim9LineComment vimComment
hi link vimMapBang vimCommand
hi link vimMapModKey vimFuncSID
hi link vimMapMod vimBracket
hi link vimMap vimCommand
hi link vimMark Number
hi link vimMarkNumber vimNumber
hi link vimMenuMod vimMapMod
hi link vimMenuNameMore vimMenuName
hi link vimMenuName PreProc
hi link vimMtchComment vimComment
hi link vimNorm vimCommand
hi link vimNotation Special
hi link vimNotFunc vimCommand
hi link vimNotPatSep vimString
hi link vimNumber Number
hi link vimOperError Error
hi link vimOper Operator
hi link vimOption PreProc
hi link vimParenSep Delimiter
hi link vimPatSepErr vimError
hi link vimPatSepR vimPatSep
hi link vimPatSep SpecialChar
hi link vimPatSepZone vimString
hi link vimPatSepZ vimPatSep
hi link vimPattern Type
hi link vimPlainMark vimMark
hi link vimPlainRegister vimRegister
hi link vimRegister SpecialChar
hi link vimScriptDelim Comment
hi link vimSearchDelim Statement
hi link vimSearch vimString
hi link vimSep Delimiter
hi link vimSetMod vimOption
hi link vimSetSep Statement
hi link vimSetString vimString
hi link vimSpecFile Identifier
hi link vimSpecFileMod vimSpecFile
hi link vimSpecial Type
hi link vimStringCont vimString
hi link vimString String
hi link vimStringEnd vimString
hi link vimSubst1 vimSubst
hi link vimSubstDelim Delimiter
hi link vimSubstFlags Special
hi link vimSubstSubstr SpecialChar
hi link vimSubstTwoBS vimString
hi link vimSubst vimCommand
hi link vimSynCaseError Error
hi link vimSynCase Type
hi link vimSyncC Type
hi link vimSyncError Error
hi link vimSyncGroupName vimGroupName
hi link vimSyncGroup vimGroupName
hi link vimSyncKey Type
hi link vimSyncNone Type
hi link vimSynContains vimSynOption
hi link vimSynError Error
hi link vimSynKeyContainedin vimSynContains
hi link vimSynKeyOpt vimSynOption
hi link vimSynMtchGrp vimSynOption
hi link vimSynMtchOpt vimSynOption
hi link vimSynNextgroup vimSynOption
hi link vimSynNotPatRange vimSynRegPat
hi link vimSynOption Special
hi link vimSynPatRange vimString
hi link vimSynRegOpt vimSynOption
hi link vimSynRegPat vimString
hi link vimSynReg Type
hi link vimSyntax vimCommand
hi link vimSynType vimSpecial
hi link vimTodo Todo
hi link vimUnmap vimMap
hi link vimUserAttrbCmpltFunc Special
hi link vimUserAttrbCmplt vimSpecial
hi link vimUserAttrbKey vimOption
hi link vimUserAttrb vimSpecial
hi link vimUserAttrbError Error
hi link vimUserCmdError Error
hi link vimUserCommand vimCommand
hi link vimUserFunc Normal
hi link vimVar Identifier
hi link vimWarn WarningMsg
#}}}1

b:current_syntax = 'vim'

