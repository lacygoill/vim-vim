vim9script

if exists('b:current_syntax')
  # bail out in a legacy script
  || "\n" .. getline(1, 10)->join("\n") !~ '\n\s*vim9\%[script]\>'
    finish
endif

# Known limitation: The plugin does not highlight legacy functions.{{{
#
# Only the `fu` and `endfu` keywords, as well as legacy comments inside.
# We  could  support  more; we  would  need  to  allow  all the  groups  in  the
# `@vimFuncBodyList` cluster to start from the `vimLegacyFuncBody` region:
#
#     syn region vimLegacyFuncBody
#         \ start='\ze\s*('
#         \ matchgroup=vimCommand
#         \ end='\<endf\%[unction]'
#         \ contained
#         \ contains=@vimFuncBodyList
#           ^-----------------------^
#
# But we don't do it, because there would be many subtle issues to handle, which
# would make the overall plugin too complex (e.g. literal dictionaries).
# It's not worth the  trouble: we want a plugin which  is easy to read/maintain,
# and performant.
#
# Besides, writing  a legacy function  in a Vim9 script  is a corner  case which
# we'll rarely encounter.  Also, I prefer no highlighting rather than a slightly
# broken one; and the absence of highlighting gives an easy visual clue to avoid
# any confusion between legacy and Vim9 functions.
#
# Finally, dropping the legacy syntax should give us the opportunity to optimize
# the code here and there.
#}}}

# TODO(lgc): Try  to nest  all function  names, option  names, event  names, ...
# inside  a match.   Use  the match  to  assert some  lookarounds  and fix  some
# spurious highlightings.  For  example, try to assert that an  option name must
# always  be preceded  by `&`  or `:set`,  and a  function name  must always  be
# followed by a paren.

# TODO(lgc): We should check the validity of data types.
# TODO(lgc): We should highlight obvious  errors (e.g. missing whitespace around
# binary operators; look for "error" at  `:h vim9`).  Usage of `:let` instead of
# `:var` to declare a variable.

# TODO(lgc): Should we highlight these commands like rules similar to `vimVar`?{{{
#
#    - :lockvar
#    - :unlet
#    - :unlockvar
#}}}
# TODO(lgc): Extend the syntax rule(s) for `:echo` to these commands:{{{
#
#    - :caddexpr
#    - :cexpr
#    - :cgetexpr
#    - :echoconsole
#    - :echoerr
#    - :echomsg
#    - :echon
#    - :elseif
#    - :eval
#    - :execute
#    - :for
#    - :if
#    - :laddexpr
#    - :lexpr
#    - :lgetexpr
#    - :return
#    - :throw
#    - :while
#
# Rationale: It makes sense; they all expect an expression as argument.
# This should help  reducing the number of occurrences where  a variable name is
# not highlighted correctly.
#
# ---
#
# Unrelated: Find the commands which expect a pattern as argument.
# Highlight it as a string.
#
# Also, find the commands which expect another command as argument.
# Handle them specially and consistently.
#}}}
# TODO(lgc): When referring to a variable (outside of a declaration), it might not be highlighted correctly.{{{
#
# Worse, it might be highlighted as an Ex command name if you chose a name which
# shadows a builtin Ex command.
#
#            ✔
#         v------v
#     var undolist: list<number>
#
#     echo undolist
#          ^------^
#             ✔
#
#     undolist = [1, 2, 3]
#     ^------^
#        ✘
#
#     var name = undolist
#                ^------^
#                   ✘
#}}}

# All vimCommands are contained by vimIsCommand. {{{1

# We  have  to  include  our  custom `vimDataType`  group  inside  the  list  of
# groups passed  to the `nextgroup`  argument, so  that the types  are correctly
# highlighted in a declaration/assignment at the script level.
syn match vimCmdSep '[:|]\+'
    \ skipwhite
    \ nextgroup=
    \vimAddress,vimAutoCmd,vimDataType,vimEcho,vimExtCmd,vimFilter,vimIsCommand
    \,vimDeclare,vimMap,vimMark,vimSet,vimSyntax,vimUserCommand

# The default plugin includes `vimSynType` inside `@vimFuncBodyList`.  Don't do the same.{{{
#
#     syn cluster vimFuncBodyList add=vimSynType
#
# Otherwise a  list type (like  `list<any>`) would not be  correctly highlighted
# when used as the return type of a `:def` function.
# That's because the `vimFuncBody` region contains the `@vimFuncBodyList` cluster.
#
# Besides, it's just wrong.  There is no reason nor need for this.
# Indeed, the `vimSyntax` group definition specifies that `vimSynType` should be
# tried  for a  match right  after any  `:syntax` command,  via the  `nextgroup`
# argument:
#
#     syn match vimSyntax '\<sy\%[ntax]\>'
#         \ ...
#         \ nextgroup=vimSynType,...
#            ^-----------------^
#         \ ...
#
# ---
#
# BTW, in case you wonder what `vimSynType`  is, it's the list of valid keywords
# which can appear after `:syntax` (e.g. `match`, `cluster`, `include`, ...).
#}}}

# We want a positive lookahead to prevent spurious highlightings.{{{
#
# Example:
#
#     syn region xFoo
#         \ ...
#         \ start='pattern'
#           ^---^
#           we don't want that to be highlighted as a command
#         \ ...
#}}}
# Order: `vimIsCommand` must be sourced *before* `vimAugroup`.
syn match vimIsCommand '\<\h\w*\>\%($\|[! \t]\@=\)' contains=vimCommand

# vimTodo: contains common special-notices for comments {{{1
# Use the `vimCommentGroup` cluster to add your own.

syn keyword vimTodo FIXME TODO contained
syn cluster vimCommentGroup contains=@Spell,vimCommentString,vimCommentTitle,vimDictLiteralLegacyError,vimTodo

# regular vim commands {{{1

exe 'syn keyword vimCommand ' .. vim#syntax#getCommandNames() .. ' contained'
syn match vimCommand '\<z[-+^.=]\=\>' contained

# vimOptions are caught only when contained in a vimSet {{{1

exe 'syn keyword vimOption ' .. vim#syntax#getOptionNames() .. ' contained'

# Note that an option value can be written right at the start of the line.{{{
#
#     &guioptions = 'M'
#     ^---------^
#}}}
syn match vimOption '\%(^\|[ \t([]\)\@1<=&[a-zA-Z0-9_:]\+\>' containedin=vimFuncBody,vimOperParen

# termcap codes (which can also be set) {{{1

exe 'syn keyword vimOption ' .. vim#syntax#getTerminalOptionNames() .. ' contained'
exe 'syn match vimOption ' .. vim#syntax#getTerminalOptionNames(false) .. ' contained'

# Augroup: vimAugroupError removed because long augroups caused sync'ing problems. {{{1
# Trade-off: Increasing synclines with slower editing vs augroup END error checking.

syn cluster vimAugroupList contains=
    \vimAddress,vimAugroup,vimAutoCmd,vimCallFuncName,vimCmplxRepeat,vimComment
    \,vimContinue,vimCtrlChar,vimDict,vimEnvVar,vimExecute,vimFilter
    \,vimBuiltinFuncName,vimFuncVar,vimUserFunctionHeader,vimFunctionError
    \,vimIsCommand,vimLegacyFunction,vimDeclare,vimMap,vimMark,vimNotFunc
    \,vimNotation,vimNumber,vimOper,vimOperParen,vimOption,vimRegion,vimRegister
    \,vimSet,vimSpecFile,vimString,vimSubst,vimSynLine,vimUserCommand

# Actually, the case of `END` does not matter.{{{
#
# Also, the name of an augroup can contain any keyword character.
# But in both cases, I prefer to enforce widely adopted conventions.
#}}}
# `keepend` is necessary to prevent `vimIsCommand` from consuming `END`.{{{
#
# This would force Vim to wrongly extend  the augroup/region to find a new match
# for the region's end.
#}}}
# The  `end`  pattern needs  `^\s*`  to  prevent a  wrong  match  on a  possible
# commented augroup inside the current augroup.
syn region vimAugroup
    \ start='\<aug\%[roup]\s\+\%(END\)\@!\h\%(\w\|-\)\+'
    \ matchgroup=vimAugroupEnd
    \ end='^\s*aug\%[roup]\s\+\zsEND\>'
    \ containedin=vimFuncBody
    \ contains=@vimAugroupList
    \ keepend

# Autocmd {{{1

syn match vimAutoEventList '\%(!\s\+\)\=\%(\a\+,\)*\a\+'
    \ contained
    \ contains=vimAutoEvent
    \ nextgroup=vimAutoCmdSpace

syn match vimAutoCmdSpace '\s\+' contained nextgroup=vimAutoCmdSfxList
syn match vimAutoCmdSfxList '\S*' contained nextgroup=vimAutoCmdMod skipwhite

syn keyword vimAutoCmd au[tocmd] do[autocmd] doautoa[ll]
    \ nextgroup=vimAutoEventList,vimAutocmdMod
    \ skipwhite

syn match vimAutoCmdMod '++\%(nested\|once\)'
syn match vimAutoCmdMod '<nomodeline>' nextgroup=vimAutoEventList skipwhite

# AutoCmd Events {{{1

syn case ignore
exe 'syn keyword vimAutoEvent ' .. vim#syntax#getEventNames() .. ' contained'
syn case match

# Highlight commonly used Groupnames {{{1

syn case ignore
syn keyword vimGroup contained
    \ Comment Constant String Character Number Boolean Float Identifier Function
    \ Statement Conditional Repeat Label Operator Keyword Exception PreProc
    \ Include Define Macro PreCondit Type StorageClass Structure Typedef Special
    \ SpecialChar Tag Delimiter SpecialComment Debug Underlined Ignore Error Todo
syn case match

# Default highlighting groups {{{1

syn case ignore
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

# Function Names {{{1

# Install a `:syn keyword` rule to highlight *most* function names.{{{
#
# Except  the ones  which  are too  ambiguous,  and match  an  Ex command  (e.g.
# `eval()`, `execute()`, `function()`, ...).
#
# Rationale: We don't want to wrongly highlight `:eval` as a function.
# To remove any ambiguity, we need to assert the presence of an open paren after
# the function name.  That's only possible with a separate `:syn match` rule.
#
# NOTE: We  don't  want to  assert  the  paren  for  *all* function  names;  the
# necessary regex would be too costly.
#}}}
exe 'syn keyword vimBuiltinFuncName '
    .. vim#syntax#getBuiltinFunctionNames()
    .. ' contained'

exe 'syn match vimBuiltinFuncName '
    .. '/\<\%('
    ..     vim#syntax#getBuiltinFunctionNames(true)
    .. '\)'
    .. '(\@='
    .. '/'
    .. ' contained'

# Numbers {{{1

syn match vimNumber '\<\d\+\%(\.\d\+\%([eE][+-]\=\d\+\)\=\)\='
    \ nextgroup=vimCommand,vimComment,vimGlobal,vimSubst
    \ skipwhite

syn match vimNumber '-\d\+\%(\.\d\+\%([eE][+-]\=\d\+\)\=\)\='
    \ nextgroup=vimCommand,vimComment,vimGlobal,vimSubst
    \ skipwhite

syn match vimNumber '\<0[xX]\x\+'
    \ nextgroup=vimCommand,vimComment,vimGlobal,vimSubst
    \ skipwhite

syn match vimNumber '\%(^\|\A\)\zs#\x\{6}'
    \ nextgroup=vimCommand,vimComment,vimGlobal,vimSubst
    \ skipwhite

syn match vimNumber '\<0[zZ][a-zA-Z0-9.]\+'
    \ nextgroup=vimCommand,vimComment,vimGlobal,vimSubst
    \ skipwhite

syn match vimNumber '0o\=[0-7]\+'
    \ nextgroup=vimCommand,vimComment,vimGlobal,vimSubst
    \ skipwhite

syn match vimNumber '0b[01]\+'
    \ nextgroup=vimCommand,vimComment,vimGlobal,vimSubst
    \ skipwhite

# It is possible to use single quotes inside numbers to make them easier to read:{{{
#
#     echo 1'000'000
#
# Highlight them as part of a number.
#}}}
syn match vimNumber /\d\@1<='\d\@=/
    \ nextgroup=vimCommand,vimComment,vimGlobal,vimSubst
    \ skipwhite

# Var/Const/Final {{{1

syn keyword vimDeclare cons[t] final unl[et] var
    \ nextgroup=vimFuncVar,vimHereDoc,vimVar
    \ skipwhite

# NOTE: In the default syntax plugin, `vimLetHereDoc` contains `vimComment` and `vim9Comment`.{{{
#
# That's wrong.
#
# It causes  any text  following a double  quote at  the start of  a line  to be
# highlighted as a Vim comment.  But that's  not a comment; that's a part of the
# heredoc; i.e. a string.
#
# Besides, we apply various styles inside comments, such as bold or italics.
# It would be unexpected and distracting to see those styles in a heredoc.
#}}}
syn region vimHereDoc
    \ matchgroup=vimHereDocStart
    \ start='=<<\s\+\%(trim\>\)\=\s*\z(\L\S*\)'
    \ matchgroup=vimHereDocStop
    \ end='^\s*\z1\s*$'

# Variables {{{1

syn match vimVar '\<\h[a-zA-Z0-9#_]*\>' contained
syn match vimConstant /\<[A-Z_][A-Z0-9#_]*\>/ containedin=vimVar
# don't highlight `_` as a constant
syn match vimVarIgnored /\<_\>/ containedin=vimVar
syn match vimVar '\<[bwgstv]:\h[a-zA-Z0-9_#]*\>'

# We need to allow `true/false/null` to start
#   inside `vimFuncBody`:{{{
#
# so that they're highlighted in a function's body:
#
#     def Func()
#         var name = true
#                    ^--^
#     enddef
#}}}
#   inside `vimOperParen`:{{{
#
# so that they're  highlighted in a function's header, when  used as the default
# value of an optional argument:
#
#     def Func(name = true)
#              ^--^
#     enddef
#}}}
syn keyword vimBool false true containedin=vimFuncBody,vimOperParen,vimDict
syn keyword vimNull null containedin=vimFuncBody,vimOperParen,vimDict

syn match vimFBVar '\<[bwgstv]:\h[a-zA-Z0-9#_]*\>' contained

syn match vimEnvVar '\$\I\i*'
syn match vimEnvVar '\${\I\i*}'

# Filetypes {{{1

syn match vimFiletype '\<filet\%[ype]\%(\s\+\I\i*\)*'
    \ contains=vimFTCmd,vimFTError,vimFTOption
    \ skipwhite

syn match vimFTError '\I\i*' contained
syn keyword vimFTCmd filet[ype] contained
syn keyword vimFTOption detect indent off on plugin contained

# Operators {{{1

# `vimLineComment` needs to be in `@vimOperGroup`.{{{
#
# So that the comment leader is highlighted  on an empty commented line inside a
# dictionary inside a function.
#}}}
syn cluster vimOperGroup contains=
    \vimComment,vimContinue,vimDict,vimEnvVar,vimCallFuncName,vimFBVar
    \,vimFuncVar,vimLineComment,vimNumber,vimOper,vimOperParen,vimRegister
    \,vimString,vimVar

syn match vimOper '\s\@1<=\%(==\|!=\|>=\|<=\|=\~\|!\~\|>\|<\|=\)[?#]\{0,2}\s\@='
    \ nextgroup=vimSpecFile,vimString
    \ skipwhite

syn match vimOper '\s\@1<=\%(is\|isnot\)\s\@='
    \ nextgroup=vimSpecFile,vimString
    \ skipwhite

# We want to assert the presence of surrounding whitespace.{{{
#
# To avoid spurious highglights in legacy Vim script.
#
# Example:
#
#     /pattern/delete
#     ^       ^
#     these should not be highlighted as arithmetic operators
#
# This  does  mean that  sometimes,  an  arithmetic  operator is  not  correctly
# highlighted:
#
#     eval 1+2
#           ^
#
# But we don't care because:
#
#    - the issue is limited to legacy which we almost never read/write anymore
#
#    - `1+2` is ugly:
#      it would be more readable as `1 + 2`, where `+` is correctly highlighted
#
# ---
#
# Also, in Vim9,  arithmetic operators *must* be surrounded  with whitespace; so
# it makes sense to enforce them in the syntax highlighting too.
#
# ---
#
# Also, this fixes  an issue where the tilde character  would not be highlighted
# in an `!~` operator.
#}}}
syn match vimOper '\s\@1<=\%(||\|&&\|[-+*/%!]=\=\|\.\.=\=\|??\=\)\s\@='
    \ nextgroup=vimSpecFile,vimString
    \ skipwhite

# methods and increment/decrement operators
syn match vimOper '->\|++\|--'
    \ nextgroup=vimSpecFile,vimString
    \ skipwhite

# logical not{{{
#
# The positive  lookbehind is necessary to  not highlight `!` when  used after a
# command name:
#
#     packadd!
#            ^
#
# ---
#
# The  negative lookahead  is necessary  to not  break the  highlighting of  `~`
# inside the operator `!~`.
#
# ---
#
# The `!*` quantifier  is necessary to support  a double not (`!!`),  which is a
# syntax we sometimes use to turn any type of expression into a boolean.
#}}}
syn match vimOper '\s\@1<=![~=]\@!!*'
    \ nextgroup=vimSpecFile,vimString
    \ skipwhite

# support `:` when used inside conditional `?:` operator
# But we need to ignore `:` inside a slice, which is tricky.{{{
#
# For the moment, we use an imperfect regex.
# We just  make sure that `:`  is preceded by a  `?`, while no `[`  can be found
# in-between, to support this kind of code:
#
#     eval 1 ? 2 : 3
#                ^
#
# While ignoring this:
#
#     eval list[1 : 2]
#                 ^
#
# *Or* we make sure that only whitespace precede the colon, to support:
#
#     eval 1
#         ? 2
#         : 3
#         ^
#}}}
syn match vimOper '\%(?[^[]*\s\|^\s\+\)\@<=:\s\@='
    \ nextgroup=vimSpecFile,vimString
    \ skipwhite

syn region vimOperParen
    \ matchgroup=vimParenSep
    \ start='('
    \ end=')'
    \ contains=@vimOperGroup

syn match vimOperError ')'

# Dictionaries {{{1

# Order: This rule must be sourced before `vimBlock`.
syn region vimDict
    \ matchgroup=vimSep
    \ start='{'
    \ end='}'
    \ containedin=vimFuncBody
    \ contains=@vimOperGroup
    \ nextgroup=vimFuncVar,vimVar

# in literal dictionary, highlight keys as strings
syn match vimDictLiteralKey /\%(^\|[ \t{]\)\@1<=[^ {]\+\ze:\@=/
    \ contained
    \ containedin=vimDict
    \ contains=vimDictLiteralKeyValid
    \ keepend

# check the validity of the key
syn match vimDictLiteralKeyValid /\%(\w\|-\)\+/
    \ contained
    \ containedin=vimDictLiteralKey

# support expressions as keys (`[expr]`).
syn match vimDictExprKey /\[.*]:\@=/
    \ contained
    \ containedin=vimDict
    \ contains=@vimOperGroup
    \ keepend

# dict.key
#     syn match vimDictDotKey '\<\w\+\.\w\+\>' containedin=vimVar contains=vimDictDot
#     syn match vimDictDot '\.' containedin=vimDictDotKey
#     hi link vimDictDot Delimiter
#     hi link vimDictDotKey vimVar
# TODO(lgc): Commented because it might wrongly highlight some command arguments:{{{
#
# Examples:
#
#     packadd! fzf.vim
#     e file.txt
#
# Revisit this issue once we've handled the highlighting of variables.
#}}}
#}}}1
# Functions {{{1

syn cluster vimFuncList
    \ contains=vimCommand,vimDefKey,vimFuncScope,vimFunctionError

# `vimLineComment` needs to be in `@vimFuncBodyList`.{{{
#
# So that the comment leader is highlighted  on an empty commented line inside a
# function.
#}}}
syn cluster vimFuncBodyList contains=
    \vimAbb,vimAddress,vimAutoCmd,vimCmplxRepeat,vimComment,vimContinue
    \,vimCtrlChar,vimEcho,vimEchoHL,vimEnvVar,vimExecute,vimFBVar
    \,vimCallFuncName,vimFuncVar,vimUserFunctionHeader,vimGlobal,vimHighlight
    \,vimIsCommand,vimLegacyFunction,vimDeclare,vimHereDoc,vimLineComment,vimMap
    \,vimMark,vimNorm,vimNotFunc,vimNotation,vimNumber,vimOper,vimOperParen
    \,vimRegion,vimRegister,vimSearch,vimSet,vimSpecFile,vimString,vimSubst
    \,vimSynLine,vimUnmap

exe 'syn match vimUserFunctionHeader'
    .. ' /'
    .. '\<def!\='
    .. '\s\+\%([gs]:\)\='
    .. '\%(\i\|[#.]\)*'
    .. '\ze('
    .. '/'
    .. ' contains=@vimFuncList'
    .. ' nextgroup=vimFuncBody'

exe 'syn match vimLegacyFunction'
    .. ' /'
    .. '\<fu\%[nction]!\='
    .. '\s\+\%([gs]:\)\='
    .. '\%(\i\|[#.]\)*'
    .. '\ze('
    .. '/'
    .. ' contains=@vimFuncList'
    .. ' nextgroup=vimLegacyFuncBody'

syn region vimFuncBody
    \ start='\ze\s*('
    \ matchgroup=vimCommand
    \ end='\<enddef\>'
    \ contained
    \ contains=@vimFuncBodyList

syn region vimLegacyFuncBody
    \ start='\ze\s*('
    \ matchgroup=vimCommand
    \ end='\<endf\%[unction]'
    \ contained

syn match vimFuncVar 'a:\%(\K\k*\|\d\+\)' contained
syn match vimFuncScope '\<[gs]:' contained
syn keyword vimDefKey def fu[nction] contained
syn match vimFuncBlank '\s\+' contained

syn keyword vimPattern start skip end contained

syn match vimLambdaArrow /\s\@1<==>\%(\s\|\n\)\@=/ containedin=vimFuncBody,vimOperParen

syn region vimBlock
    \ matchgroup=Statement
    \ start=/\s\+=>\s\+{\|^\s*{$/
    \ end='^\s*}'
    \ containedin=vimFuncBody,vimOperParen
    \ contains=vimBuiltinFuncName,vimCommand,vimOper,vimOperParen,vimString,vimVar

# Special Filenames, Modifiers, Extension Removal {{{1

syn match vimSpecFile '<c\%(word\|WORD\)>' nextgroup=vimSpecFileMod,vimSubst

syn match vimSpecFile '<\%([acs]file\|amatch\|abuf\)>'
    \ nextgroup=vimSpecFileMod,vimSubst

# Do *not* add allow a space to match after `%`.{{{
#
#     \s%[: ]
#          ^
#          ✘
#
# Sometimes, it would break the highlighting of the arithmetic modulo operator:
#
#     eval (1) % 2
#              ^
#
# This does  mean that  in some  cases, `%`  might be  wrongly highlighted  as a
# modulo instead of a special filename.  Contrived example:
#
#     e % | eval 0
#       ^
#       ✘
#
# For the moment, it looks like a  corner case which we won't encounter often in
# practice, so let's not try to fix it.
#}}}
syn match vimSpecFile '\s%:'ms=s+1,me=e-1 nextgroup=vimSpecFileMod,vimSubst
syn match vimSpecFile '\s%$'ms=s+1 nextgroup=vimSpecFileMod,vimSubst
syn match vimSpecFile '\s%<'ms=s+1,me=e-1 nextgroup=vimSpecFileMod,vimSubst
syn match vimSpecFile '#\d\+\|[#%]<\>' nextgroup=vimSpecFileMod,vimSubst
syn match vimSpecFileMod '\%(:[phtre]\)\+' contained

# User-Specified Commands {{{1

syn cluster vimUserCmdList contains=
    \vimAddress,vimAutoCmd,vimCmplxRepeat,vimComment,vimCtrlChar,vimEscapeBrace
    \,vimCallFuncName,vimBuiltinFuncName,vimUserFunctionHeader,vimFunctionError
    \,vimHighlight,vimIsCommand,vimLegacyFunction,vimDeclare,vimMark,vimNotation
    \,vimNumber,vimOper,vimRegion,vimRegister,vimSet,vimSetString,vimSpecFile
    \,vimString,vimSubst,vimSubstRange,vimSubstRep,vimSynLine,vimSyntax

syn match vimUserCommand '\<com\%[mand]\>.*$' contains=
    \@vimUserCmdList,vimComFilter,vimUserAttrb,vimUserAttrbError

syn match vimUserAttrbError '-\a\+\ze\s' contained

syn match vimUserAttrb '-nargs=[01*?+]'
    \ contained
    \ contains=vimOper,vimUserAttrbKey

syn match vimUserAttrb '-complete='
    \ contained
    \ contains=vimOper,vimUserAttrbKey
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

syn keyword vimUserAttrbCmplt contained
    \ custom customlist
    \ nextgroup=vimUserAttrbCmpltFunc,vimUserCmdError

syn match vimUserAttrbCmpltFunc
    \ ',\%(s:\)\=\%(\h\w*\%(#\h\w*\)\+\|\h\w*\)'hs=s+1
    \ contained
    \ nextgroup=vimUserCmdError

syn case match
syn match vimUserAttrbCmplt 'custom,\u\w*' contained

# Lower Priority Comments: after some vim commands... {{{1

syn region vimCommentString start='\%(\S\s\+\)\@<="' end='"' contained oneline

# comments - TODO: might be highlighted while they don't work
syn match vimComment '\s\@1<=#.*$'
    \ contains=@vimCommentGroup
    \ excludenl

# comment inside expression
syn match vimComment '\s\@1<=#.*$'ms=s+1
    \ contains=@vimCommentGroup

syn match vimComment '^\s*#.*$' contains=@vimCommentGroup

# In legacy Vim script, a literal dictionary starts with `#{`.
# This syntax is no longer valid in Vim9.
# Highlight it as an error.
syn match vimDictLiteralLegacyError '#{{\@!'

# In-String Specials {{{1

# Try to catch strings, if nothing else matches (therefore it must precede the others!)
# vimEscapeBrace handles ["]  []"] (ie. "s don't terminate string inside [])
syn region vimEscapeBrace
    \ start='[^\\]\%(\\\\\)*\[\zs\^\=\]\='
    \ skip='\\\\\|\\\]'
    \ end=']'me=e-1
    \ contained
    \ oneline
    \ transparent

syn match vimPatSepErr '\\)' contained
syn match vimPatSep '\\|' contained

syn region vimPatSepZone
    \ matchgroup=vimPatSepZ
    \ start='\\%\=\ze('
    \ skip='\\\\'
    \ end=/\\)\|[^\\]['"]/
    \ contained
    \ contains=@vimStringGroup
    \ oneline

syn region vimPatRegion
    \ matchgroup=vimPatSepR
    \ start='\\[z%]\=('
    \ end='\\)'
    \ contained
    \ contains=@vimSubstList
    \ oneline
    \ transparent

syn match vimNotPatSep '\\\\' contained

syn cluster vimStringGroup contains=
    \@Spell,vimEscapeBrace,vimNotPatSep,vimPatSep,vimPatSepErr,vimPatSepZone

syn region vimString
    \ start=/[^a-zA-Z>!\\@]\@1<="/
    \ skip=/\\\\\|\\"/
    \ matchgroup=vimStringEnd
    \ end=/"/
    \ contains=@vimStringGroup
    \ keepend
    \ oneline

# We must not allow a digit to match after the ending quote.{{{
#
#     end=/'\d\@!/
#           ^---^
#
# Otherwise, it  would break  the highlighting  of a  big number  which contains
# quotes to be more readable:
#
#     const BIGNUMBER: number = 1'000'000
#                                ^---^
#                                this would be wrongly highlighted as a string,
#                                instead of a number
#}}}
syn region vimString start=/[^a-zA-Z>!\\@]\@1<='/ end=/'\d\@!/ keepend oneline

syn region vimString
    \ start=/=\@1<=!/
    \ skip=/\\\\\|\\!/
    \ end=/!/
    \ contains=@vimStringGroup
    \ oneline

syn region vimString
    \ start='=\@1<=+'
    \ skip='\\\\\|\\+'
    \ end='+'
    \ contains=@vimStringGroup
    \ oneline

syn match vimString '"[^"]*\\$' contained nextgroup=vimStringCont skipnl
syn match vimStringCont '\%(\\\\\|.\)\{-}[^\\]"' contained

# Substitutions {{{1

syn cluster vimSubstList contains=
    \vimNotation,vimPatRegion,vimPatSep,vimPatSepErr,vimSubstRange,vimSubstTwoBS

syn cluster vimSubstRepList contains=vimNotation,vimSubstSubstr,vimSubstTwoBS
syn cluster vimSubstList add=vimCollection

exe 'syn match vimSubst'
    .. ' /'
    ..     '\%(:\+\s*\|^\s*\||\s*\)'
    ..     '\<\%(\<s\%[ubstitute]\>\|\<sm\%[agic]\>\|\<sno\%[magic]\>\)'
    ..     '[:#[:alpha:]]\@!'
    .. '/'
    .. ' nextgroup=vimSubstPat'

# We don't recognize `(` as a delimiter.{{{
#
# That's because  – sometimes  – it  would cause `s`  or `substitute`  to be
# wrongly highlighted as an Ex command.
#
# Example:
#
#     def A()
#         B(s)
#     enddef
#
# Also, when used as a method:
#
#     fu A()
#         eval substitute('aaa', 'b', 'c', '')->B()
#     endfu
#
#     fu A()
#         call substitute('aaa', 'b', 'c', '')->B()
#     endfu
#
#     fu A()
#         return histget(':')->execute()->substitute('\n', '', '')
#     endfu
#
# Besides, using `(` as a delimiter is a bad idea.
# It makes the code more ambiguous and harder to read:
#
#     :substitute(pattern(replacement(flags
#                ^       ^           ^
#                ✘       ✘           ✘
#
# It's easy to choose a different and less problematic delimiter:
#
#     :substitute@pattern@replacement@flags
#                ^       ^           ^
#                ✔       ✔           ✔
#}}}
syn match vimSubst /\%(^\|[^\\"'(]\)\<\%(s\%[ubstitut]\|substitute(\@!\)\>[:#[:alpha:]"']\@!/
    \ contained
    \ nextgroup=vimSubstPat

syn match vimSubst '/\zs\<s\%[ubstitute]\>\ze/' nextgroup=vimSubstPat
syn match vimSubst '\%(:\+\s*\|^\s*\)s\ze#.\{-}#.\{-}#' nextgroup=vimSubstPat
syn match vimSubst1 '\<s\%[ubstitute]\>' contained nextgroup=vimSubstPat
syn match vimSubst2 's\%[ubstitute]\>' contained nextgroup=vimSubstPat

syn region vimSubstPat
    \ matchgroup=vimSubstDelim
    \ start='\z([^a-zA-Z( \t[\]&]\)'rs=s+1
    \ skip='\\\\\|\\\z1'
    \ end='\z1're=e-1,me=e-1
    \ contained
    \ contains=@vimSubstList
    \ nextgroup=vimSubstRep4
    \ oneline

syn region vimSubstRep4
    \ matchgroup=vimSubstDelim
    \ start='\z(.\)'
    \ skip='\\\\\|\\\z1'
    \ end='\z1'
    \ matchgroup=vimNotation
    \ end='<[cC][rR]>'
    \ contained
    \ contains=@vimSubstRepList
    \ nextgroup=vimSubstFlagErr
    \ oneline

syn region vimCollection
    \ start='\\\@1<!\['
    \ skip='\\\['
    \ end='\]'
    \ contained
    \ contains=vimCollClass
    \ transparent

syn match vimCollClassErr '\[:.\{-\}:\]' contained

exe 'syn match vimCollClass '
    .. ' /\%#=1\[:'
    .. '\%('
    ..         'alnum\|alpha\|blank\|cntrl\|digit\|graph\|lower\|print\|punct'
    .. '\|' .. 'space\|upper\|xdigit\|return\|tab\|escape\|backspace'
    .. '\)'
    .. ':\]/'
    .. ' contained'
    .. ' transparent'

syn match vimSubstSubstr '\\z\=\d' contained
syn match vimSubstTwoBS '\\\\' contained
syn match vimSubstFlagErr '[^< \t\r|]\+' contained contains=vimSubstFlags
syn match vimSubstFlags '[&cegiIlnpr#]\+' contained

# 'String' {{{1

syn match vimString /[^(,]'[^']\{-}\zs'/

# Marks, Registers, Addresses, Filters {{{1

syn match vimMark /'[a-zA-Z0-9]\ze[-+,!]/
    \ nextgroup=vimFilter,vimMarkNumber,vimSubst

syn match vimMark /'[<>]\ze[-+,!]/ nextgroup=vimFilter,vimMarkNumber,vimSubst
syn match vimMark /,\zs'[<>]\ze/ nextgroup=vimFilter,vimMarkNumber,vimSubst

syn match vimMark /[!,:]\zs'[a-zA-Z0-9]/
    \ nextgroup=vimFilter,vimMarkNumber,vimSubst

syn match vimMark /\<norm\%[al]\s\zs'[a-zA-Z0-9]/
    \ nextgroup=vimFilter,vimMarkNumber,vimSubst

syn match vimMarkNumber '[-+]\d\+'
    \ contained
    \ contains=vimOper
    \ nextgroup=vimSubst2

syn match vimPlainMark /'[a-zA-Z0-9]/ contained

syn match vimRange /[`'][a-zA-Z0-9],[`'][a-zA-Z0-9]/
    \ contains=vimMark
    \ nextgroup=vimFilter
    \ skipwhite

syn match vimRegister '[^,;[{: \t]\zs"[a-zA-Z0-9.%#:_\-/]\ze[^a-zA-Z_":0-9]'
syn match vimRegister '\<norm\s\+\zs"[a-zA-Z0-9]'
syn match vimRegister '\<normal\s\+\zs"[a-zA-Z0-9]'
syn match vimRegister '@"'
syn match vimPlainRegister '"[a-zA-Z0-9\-:.%#*+=]' contained

syn match vimAddress ',\zs[.$]' nextgroup=vimSubst1 skipwhite
syn match vimAddress '%\ze\a' nextgroup=vimString,vimSubst1 skipwhite

syn match vimFilter /^!!\=[^"]\{-}\%(|\|\ze"\|$\)/ contains=vimOper,vimSpecFile

syn match vimFilter /!!\=[^"]\{-}\%(|\|\ze"\|$\)/
    \ contained
    \ contains=vimOper,vimSpecFile

syn match vimComFilter /|!!\=[^"]\{-}\%(|\|\ze"\|$\)/
    \ contained
    \ contains=vimOper,vimSpecFile

# Complex Repeats: (`:h complex-repeat`) {{{1

syn match vimCmplxRepeat '[^a-zA-Z_/\\()]\@1<=q[0-9a-zA-Z"]\>'
syn match vimCmplxRepeat '@[0-9a-z".=@:]\ze\%($\|[^a-zA-Z]\>\)'

# Set command and associated set-options (vimOptions) with comment {{{1

# The positive lookahead in the skip argument is necessary in case the last character is escaped.{{{
#
#     \ skip='\%(\\\\\)*\\[| \t].\@='
#                               ^--^
#
# Example:
#
#     set showbreak=↪\_
#                     ^
#                     actually represent a trailing space character
#
# Here, without the positive lookahead, the trailing space would be skipped, and
# the end of  the region would not be  found.  I guess `$` doesn't  work in this
# case because of `oneline`.
#}}}
syn region vimSet
    \ matchgroup=vimCommand
    \ start='\<\%(setl\%[ocal]\|setg\%[lobal]\|se\%[t]\)\>'
    \ skip='\%(\\\\\)*\\[| \t]\n\@!'
    \ end='|\|$'
    \ matchgroup=vimNotation
    \ end='<[cC][rR]>'
    \ contains=vimComment,vimErrSetting,vimOption,vimSetEqual,vimSetMod,vimSetString
    \ keepend
    \ oneline

syn region vimSetEqual
    \ matchgroup=Operator
    \ start='[-+^]\=='
    \ matchgroup=NONE
    \ skip='\%(\\\\\)*\\[| \t]\n\@!'
    \ end='[| \t]\|$'me=e-1
    \ contained
    \ contains=vimCtrlChar,vimEnvVar,vimNotation,vimSetSep
    \ oneline

syn region vimSetString
    \ start=/="/hs=s+1
    \ skip=/\\\\\|\\"/
    \ end=/"/
    \ contained
    \ contains=vimCtrlChar

syn match vimSetSep '[,:]' contained
syn match vimSetMod '&vim\=\|[!&?<]\|all&' contained

# Abbreviations {{{1

syn keyword vimAbb
    \ ab[breviate] ca[bbrev] inorea[bbrev] cnorea[bbrev] norea[bbrev] ia[bbrev]
    \ nextgroup=vimMapLhs,vimMapMod
    \ skipwhite

# Echo And Execute: -- prefer strings! {{{1

# `vimOper` and `vimOperParen` need to be allowed to start in a `vimEcho` region.{{{
#
# Otherwise,  in an  `:echo`  command,  the `->`  method  tokens, and  functions
# parentheses, would be wrongly highlighted.
#
#     echo substitute('aaa', 'b', 'c', '')->OtherFunc()
#                    ^                   ^^^
#                    ✘                   ✘✘✘
#}}}
# `vimComment` needs to be allowed to start in a `vimEcho` region.{{{
#
# Otherwise, an inline comment would not be properly highlighted after an `:echo`:
#
#     echo 1 + 1 # some comment
#                ^------------^
#}}}
syn region vimEcho
    \ matchgroup=vimCommand
    \ start='\<ec\%[ho]\>'
    \ skip='\%(\\\\\)*\\|'
    \ matchgroup=vimCmdSep
    \ end='$\||'
    \ excludenl
    \ oneline
    \ contains=vimCallFuncName,vimComment,vimEnvVar,vimFuncVar,vimNumber,vimOper
    \,vimOperParen,vimString,vimVar

syn region vimExecute
    \ matchgroup=vimCommand
    \ start='\<exe\%[cute]\>'
    \ skip='\%(\\\\\)*\\|'
    \ end='$\||\|<[cC][rR]>'
    \ contains=vimCallFuncName,vimFuncVar,vimIsCommand,vimNotation,vimOper,vimOperParen,vimString,vimVar
    \ excludenl
    \ oneline

syn match vimEchoHL 'echohl\='
    \ nextgroup=vimEchoHLNone,vimGroup,vimHLGroup
    \ skipwhite

syn case ignore
syn keyword vimEchoHLNone none
syn case match

# Maps {{{1

syn match vimMap '\<map\>!\=\ze\s*[^(]' nextgroup=vimMapLhs,vimMapMod skipwhite

syn keyword vimMap
    \ cm[ap] cno[remap] im[ap] ino[remap] lm[ap] ln[oremap] nm[ap] nn[oremap]
    \ no[remap] om[ap] ono[remap] smap snor[emap] tno[remap] tm[ap] vm[ap]
    \ vn[oremap] xm[ap] xn[oremap]
    \ nextgroup=vimMapBang,vimMapLhs,vimMapMod
    \ skipwhite

syn keyword vimMap
    \ mapc[lear] smapc[lear] cmapc[lear] imapc[lear] lmapc[lear]
    \ nmapc[lear] omapc[lear] tmapc[lear] vmapc[lear] xmapc[lear]

syn keyword vimUnmap
    \ cu[nmap] iu[nmap] lu[nmap] nun[map] ou[nmap] sunm[ap]
    \ tunma[p] unm[ap] unm[ap] vu[nmap] xu[nmap]
    \ nextgroup=vimMapBang,vimMapLhs,vimMapMod
    \ skipwhite

syn match vimMapLhs '\S\+'
    \ contained
    \ contains=vimCtrlChar,vimNotation
    \ nextgroup=vimMapRhs
    \ skipwhite

syn match vimMapBang '!' contained nextgroup=vimMapLhs,vimMapMod skipwhite

exe 'syn match vimMapMod '
    .. '/'
    .. '\%#=1\c'
    .. '<' .. '\%('
    ..         'buffer\|expr\|\%(local\)\=leader'
    .. '\|' .. 'nowait\|plug\|script\|sid\|unique\|silent'
    .. '\)\+' .. '>'
    .. '/'
    .. ' contained'
    .. ' contains=vimMapModErr,vimMapModKey'
    .. ' nextgroup=vimMapLhs,vimMapMod'
    .. ' skipwhite'

syn match vimMapRhs '.*'
    \ contained
    \ contains=vimCtrlChar,vimNotation
    \ nextgroup=vimMapRhsExtend
    \ skipnl

syn match vimMapRhsExtend '^\s*\\.*$' contained contains=vimContinue

syn case ignore
syn keyword vimMapModKey contained
    \ buffer expr leader localleader nowait plug script sid silent unique
syn case match

# Menus {{{1

syn cluster vimMenuList
    \ contains=vimMenuBang,vimMenuMod,vimMenuName,vimMenuPriority

syn keyword vimCommand
    \ am[enu] an[oremenu] aun[menu] cme[nu] cnoreme[nu] cunme[nu] ime[nu]
    \ inoreme[nu] iunme[nu] me[nu] nme[nu] nnoreme[nu] noreme[nu] nunme[nu]
    \ ome[nu] onoreme[nu] ounme[nu] unme[nu] vme[nu] vnoreme[nu] vunme[nu]
    \ nextgroup=@vimMenuList
    \ skipwhite

syn match vimMenuName '[^ \t\\<]\+'
    \ contained
    \ nextgroup=vimMenuMap,vimMenuNameMore

syn match vimMenuPriority '\d\+\%(\.\d\+\)*'
    \ contained
    \ nextgroup=vimMenuName
    \ skipwhite

syn match vimMenuNameMore '\c\\\s\|<tab>\|\\\.'
    \ contained
    \ contains=vimNotation
    \ nextgroup=vimMenuName,vimMenuNameMore

syn match vimMenuMod '\c<\%(script\|silent\)\+>'
    \ contained
    \ contains=vimMapModErr,vimMapModKey
    \ nextgroup=@vimMenuList
    \ skipwhite

syn match vimMenuMap '\s' contained nextgroup=vimMenuRhs skipwhite

syn match vimMenuRhs '.*$'
    \ contained
    \ contains=vimComment,vimIsCommand,vimString

syn match vimMenuBang '!' contained nextgroup=@vimMenuList skipwhite

# Angle-Bracket Notation {{{1

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

syn match vimBracket '[\\<>]' contained
syn case match

# User Function Highlighting {{{1

# call to any kind of function (builtin + custom)
exe 'syn match vimCallFuncName '
    .. '/\<'
    .. '\%('
    # with an explicit scope, the name can start with and contain any word character
    ..     '[gs]:\w\+'
    .. '\|'
    # otherwise, it must start with a head of word (i.e. word character except digit);
    # afterward, it can contain any word character and `#` (for autoload functions)
    ..     '\h\%(\w\|#\)*'
    .. '\)'
    # Do *not* allow whitespace between the function name and the open paren.{{{
    #
    #     .. '\ze\s*('
    #            ^^^
    #
    # First, it's not allowed in Vim9 script.
    # Second, it could cause a wrong highlighting:
    #
    #     eval (1 + 2)
    #     ^--^
    #     this should not be highlighted as a function, but as a command
    #}}}
    .. '\ze('
    .. '/'
    .. ' contains=vimBuiltinFuncName,vimUserCallFuncName'

# call to custom function
exe 'syn match vimUserCallFuncName '
    .. '/\<'
    .. '\%('
    ..     '[gs]:\w\+'
    .. '\|'
    # without an explicit scope, the name of the function must not start with a lowercase
    # (that's reserved to builtin functions)
    ..     '[A-Z_]\w*'
    .. '\|'
    # unless it's an autoload function
    ..     '\h\w*#\%(\w\|#\)*'
    .. '\)'
    .. '\ze('
    .. '/'
    .. ' contained'
    .. ' contains=vimNotation'

# User Command Highlighting {{{1

exe 'syn match vimUserCommandName '
    .. '"^\s*\zs\u\%(\w*\)\@>'
    .. '\%('
    # Don't highlight a custom Vim function invoked without ":call".{{{
    #
    #     Func()
    #     ^--^
    #}}}
    # Don't highlight a capitalized autoload function name, in a function call:{{{
    #
    #     Script#func()
    #     ^----^
    #}}}
    # Don't highlight the member of a list/dictionary:{{{
    #
    #     var NAME: list<number> = [1]
    #     NAME[0] = 2
    #     ^--^
    #}}}
    ..     '[(#[]'
    .. '\|'
    # Don't highlight a capitalized variable name, in an assignment without declaration:{{{
    #
    #     var MYCONSTANT: number
    #     MYCONSTANT = 12
    #     MYCONSTANT += 34
    #     MYCONSTANT *= 56
    #     ...
    #}}}
    ..     '\s\+\%([-+*/%]\=\|\.\.\)='
    # Don't highlight a funcref expression at the start of a line; nor a key in a literal dictionary.{{{
    #
    #     def Foo(): string
    #         return 'some text'
    #     enddef
    #
    #     def Bar(F: func): string
    #         return F()
    #     enddef
    #
    #     # should NOT be highlighted as an Ex command
    #     vvv
    #     Foo->Bar()
    #        ->setline(1)
    #
    # ---
    #
    #     var d = {
    #         Key: 123,
    #         ^^^
    #         # should NOT be highlighted as an Ex command
    #     }
    #
    # Actually,  in this  simple example,  there is  no issue,  probably because
    # `Key`  is in  `vimOperParen`.   But  if the  start  of  the dictionary  is
    # far  away,  then  the  syntax  *might*  fail  to  parse  `Key`  as  inside
    # `vimOperParen`, which can cause `Key` to be parsed as `vimUserCommandName`.
    # To reproduce, we  need – approximately – twice the  number assigned to
    # `:syn sync maxlines`:
    #
    #     syn sync maxlines=60
    #                       ^^
    #                       60 * 2 = 120
    #
    # But depending on  how you've scrolled vertically in the  buffer, the issue
    # might not be reproducible or disappear.
    #}}}
    .. '\|' .. '\%(\s*->\|:\)'
    .. '\)\@!"'

# Necessary for a custom command name to be highlighted inside a function.
syn cluster vimFuncBodyList add=vimUserCommandName

# Data Types {{{1

# Order: This section must be sourced *after* the `vimCallFuncName` and `vimUserCallFuncName` rules.{{{
#
# Otherwise, a funcref return type in a function's header would sometimes not be
# highlighted in its entirety:
#
#     def Func(): func(): number
#                 ^-----^
#                 not highlighted
#     enddef
#}}}

# Need to support *at least* these cases:{{{
#
#     var name: type
#     var name: type # comment
#     var name: type = value
#     var name: list<string> =<< trim END
#     def Func(arg: type)
#     def Func(): type
#
#     def Func(
#         arg: type,
#         ...
#
#     (arg: type) => expr
#     (): type => expr
#}}}
exe 'syn match vimDataType /'
    .. '\%(' .. ':\s\+' .. '\)'
    .. '\%('
               # match simple types
    ..         'any\|blob\|bool\|channel\|float\|func\|job\|number\|string\|void'
    .. '\)\>'
    # positive lookahead
    .. '\%('
    # the type could be at the end of a line (e.g. variable declaration without assignment)
    ..     '$'
    # it could be followed by an inline comment
    ..     '\|\s\+#'
    # it could be followed by an assignment operator (`=`, `=<<`)
    # or by an arrow (in a lambda, after its arguments)
    ..     '\|\s\+=[ ><\n]'
    # it could be followed by a paren or a comma (in a function's header),
    # or by a colon (in the case of `func`)
    ..     '\|[),:]'
    .. '\)\@='
    .. '/ containedin=vimFuncBody,vimOperParen'
    #                             ^----------^
    #                             for `:def` function header

# Complex data types need to be handled separately.
# First, let's deal with their leading colon.
syn match vimDataTypeComplexColon /:\s\+\ze\%(\%(list\|dict\)<\|func(\)/
    \ containedin=vimFuncBody,vimOperParen
    \ nextgroup=vimDataTypeListDict,vimDataTypeFuncref

# Now, we can deal with the rest.
# But a list/dict/funcref type can contain  itself; this is too tricky to handle
# with a  match and a  single regex.   It's much simpler  to let Vim  handle the
# possible recursion with a region which can contain itself.
syn region vimDataTypeListDict
    "\ TODO(lgc): why matchgroup?
    "\ And why is it applied *on top of* the start, while it *replaces* the end?
    \ matchgroup=vimDataType
    \ start=/\<\%(list\|dict\)</
    \ end=/>/
    "\ asserts that `list<...>` and `dict<...>` can only match if they follow `: `
    \ contained
    \ contains=vimDataTypeListDict
    \ nextgroup=vimDataTypeCastComplexEnd

syn region vimDataTypeFuncref
    "\ TODO(lgc): why matchgroup?
    \ matchgroup=vimDataType
    \ start=/\<func(/
    \ end=/)/
    \ contained
    \ contains=vimDataTypeFuncref
    \ nextgroup=vimDataTypeCastComplexEnd

# support `:h type-casting` for simple types
exe 'syn match vimDataTypeCast /'
    .. '<\%('
    ..         'any\|blob\|bool\|channel\|float\|func\|job\|number\|string\|void'
    .. '\)>'
    .. '\%([bgtw]:\)\@='
    .. '/ containedin=vimFuncBody,vimOperParen,vimEcho'

# support `:h type-casting` for complex types
syn match vimDataTypeCastComplexStart /<\ze\%(\%(list\|dict\)<\|func(\)/
    \ containedin=vimFuncBody,vimOperParen
    \ nextgroup=vimDataTypeListDict,vimDataTypeFuncref

syn match vimDataTypeCastComplexEnd />/
    \ contained
    \ containedin=vimDataTypeListDict,vimDataTypeFuncref

# Errors And Warnings {{{1

syn match vimFunctionError '\s\zs[a-z0-9]\i\{-}\ze\s*('
    \ contained
    \ contains=vimDefKey,vimFuncBlank

exe 'syn match vimFunctionError '
    .. '/'
    .. '\s\zs\%([gs]:\)'
    .. '\d\i\{-}\ze\s*('
    .. '/'
    .. ' contained'
    .. ' contains=vimDefKey,vimFuncBlank'
syn match vimElseIfErr '\<else\s\+if\>'
syn match vimBufnrWarn /\<bufnr\s*(\s*["']\.['"]\s*)/

syn match vimNotFunc
    \ '\<if\>\|\<el\%[seif]\>\|\<return\>\|\<while\>'
    \ nextgroup=vimCallFuncName,vimNotation,vimOper,vimOperParen,vimVar
    \ skipwhite

# Norm {{{1

syn match vimNorm '\<norm\%[al]\>!\=' nextgroup=vimNormCmds skipwhite
syn match vimNormCmds '.*$' contained

# Syntax {{{1

# Order: This rule must be sourced *before* the one setting `vimHiGroup`.{{{
#
# Otherwise, the name of a highlight group would not be highlighted here:
#
#     syn clear Foobar
#               ^----^
#}}}
syn match vimGroupList '@\=[^ \t,]\+'
    \ contained
    \ contains=vimGroupSpecial,vimPatSep

syn match vimGroupList '@\=[^ \t,]*,'
    \ contained
    \ contains=vimGroupSpecial,vimPatSep
    \ nextgroup=vimGroupList

syn keyword vimGroupSpecial ALL ALLBUT CONTAINED TOP contained
syn match vimSynError '\i\+' contained
syn match vimSynError '\i\+=' contained nextgroup=vimGroupList

syn match vimSynContains '\<contain\%(s\|edin\)='
    \ contained
    \ nextgroup=vimGroupList

syn match vimSynKeyContainedin '\<containedin=' contained nextgroup=vimGroupList
syn match vimSynNextgroup 'nextgroup=' contained nextgroup=vimGroupList

syn match vimSyntax '\<sy\%[ntax]\>'
    \ contains=vimCommand
    \ nextgroup=vimComment,vimSynType
    \ skipwhite

syn cluster vimFuncBodyList add=vimSyntax

# Syntax: case {{{1

syn keyword vimSynType contained
    \ case skipwhite
    \ nextgroup=vimSynCase,vimSynCaseError

syn match vimSynCaseError '\i\+' contained
syn keyword vimSynCase ignore match contained

# Syntax: clear {{{1

# `vimHiGroup` needs  to be in  the `nextgroup`  argument, so that  `{group}` is
# highlighted in `syn clear {group}`.
syn keyword vimSynType clear contained nextgroup=vimGroupList,vimHiGroup skipwhite

# Syntax: cluster {{{1

syn keyword vimSynType cluster contained nextgroup=vimClusterName skipwhite

syn region vimClusterName
    \ matchgroup=vimGroupName
    \ start='\h\w*'
    \ skip='\\\\\|\\|'
    \ matchgroup=vimSep
    \ end='$\||'
    \ contained
    \ contains=vimGroupAdd,vimGroupRem,vimSynContains,vimSynError

syn match vimGroupAdd 'add=' contained nextgroup=vimGroupList
syn match vimGroupRem 'remove=' contained nextgroup=vimGroupList
syn cluster vimFuncBodyList add=vimGroupAdd,vimGroupRem

# Syntax: iskeyword {{{1

syn keyword vimSynType iskeyword contained nextgroup=vimIskList skipwhite
syn match vimIskList '\S\+' contained contains=vimIskSep
syn match vimIskSep ',' contained

# Syntax: include {{{1

syn keyword vimSynType include contained nextgroup=vimGroupList skipwhite

# Syntax: keyword {{{1

syn cluster vimSynKeyGroup
    \ contains=vimSynKeyContainedin,vimSynKeyOpt,vimSynNextgroup

syn keyword vimSynType keyword contained nextgroup=vimSynKeyRegion skipwhite

syn region vimSynKeyRegion
    \ matchgroup=vimGroupName
    \ start='\h\w*'
    \ skip='\\\\\|\\|'
    \ matchgroup=vimSep
    \ end='|\|$'
    \ contained
    \ contains=@vimSynKeyGroup
    \ keepend
    \ oneline

syn match vimSynKeyOpt
    \ '\%#=1\<\%(conceal\|contained\|transparent\|skipempty\|skipwhite\|skipnl\)\>'
    \ contained

# Syntax: match {{{1

syn cluster vimSynMtchGroup contains=
    \vimComment,vimMtchComment,vimNotation,vimSynContains,vimSynError
    \,vimSynMtchOpt,vimSynNextgroup,vimSynRegPat

syn keyword vimSynType match contained nextgroup=vimSynMatchRegion skipwhite

syn region vimSynMatchRegion
    \ matchgroup=vimGroupName
    \ start='\h\w*'
    \ matchgroup=vimSep
    \ end='|\|$'
    \ contained
    \ contains=@vimSynMtchGroup
    \ keepend

exe 'syn match vimSynMtchOpt '
    .. '/'
    .. '\%#=1'
    .. '\<\%('
    ..         'conceal\|transparent\|contained\|excludenl\|keepend\|skipempty'
    .. '\|' .. 'skipwhite\|display\|extend\|skipnl\|fold'
    .. '\)\>'
    .. '/'
    .. ' contained'

syn match vimSynMtchOpt '\<cchar=' contained nextgroup=vimSynMtchCchar
syn match vimSynMtchCchar '\S' contained
syn cluster vimFuncBodyList add=vimSynMtchGroup

# Syntax: off and on {{{1

syn keyword vimSynType enable list manual off on reset contained

# Syntax: region {{{1

syn cluster vimSynRegPatGroup contains=
    \vimNotPatSep,vimNotation,vimPatRegion,vimPatSep,vimPatSepErr,vimSubstSubstr
    \,vimSynNotPatRange,vimSynPatRange

syn cluster vimSynRegGroup contains=
    \vimSynContains,vimSynMtchGrp,vimSynNextgroup,vimSynReg,vimSynRegOpt

syn keyword vimSynType region contained nextgroup=vimSynRegion skipwhite

syn region vimSynRegion
    \ matchgroup=vimGroupName
    \ start='\h\w*'
    \ skip='\\\\\|\\|'
    \ end='|\|$'
    \ contained
    \ contains=@vimSynRegGroup
    \ keepend

exe 'syn match vimSynRegOpt '
    .. '/'
    .. '\%#=1'
    .. '\<\%('
    ..         'conceal\%(ends\)\=\|transparent\|contained\|excludenl'
    .. '\|' .. 'skipempty\|skipwhite\|display\|keepend\|oneline\|extend\|skipnl'
    .. '\|' .. 'fold'
    .. '\)\>'
    .. '/'
    .. ' contained'

syn match vimSynReg '\%(start\|skip\|end\)='he=e-1
    \ contained
    \ nextgroup=vimSynRegPat

syn match vimSynMtchGrp 'matchgroup=' contained nextgroup=vimGroup,vimHLGroup

syn region vimSynRegPat
    \ start=|\z([-`~!@#$%^&*_=+;:'",./?]\)|
    \ skip=/\\\\\|\\\z1/
    \ end='\z1'
    \ contained
    \ contains=@vimSynRegPatGroup
    \ extend
    \ nextgroup=vimSynPatMod,vimSynReg
    \ skipwhite

syn match vimSynPatMod
    \ '\%#=1\%(hs\|ms\|me\|hs\|he\|rs\|re\)=[se]\%([-+]\d\+\)\='
    \ contained

syn match vimSynPatMod
    \ '\%#=1\%(hs\|ms\|me\|hs\|he\|rs\|re\)=[se]\%([-+]\d\+\)\=,'
    \ contained
    \ nextgroup=vimSynPatMod

syn region vimSynPatRange start='\[' skip='\\\\\|\\]' end=']' contained
syn match vimSynNotPatRange '\\\\\|\\\[' contained
syn match vimMtchComment '#[^#]\+$' contained

# Syntax: sync {{{1

syn keyword vimSynType sync
    \ contained
    \ nextgroup=vimSyncC,vimSyncError,vimSyncLinebreak,vimSyncLinecont,vimSyncLines,vimSyncMatch,vimSyncRegion
    \ skipwhite

syn match vimSyncError '\i\+' contained
syn keyword vimSyncC ccomment clear fromstart contained
syn keyword vimSyncMatch match contained nextgroup=vimSyncGroupName skipwhite
syn keyword vimSyncRegion region contained nextgroup=vimSynReg skipwhite

syn match vimSyncLinebreak '\<linebreaks='
    \ contained
    \ nextgroup=vimNumber
    \ skipwhite

syn keyword vimSyncLinecont linecont contained nextgroup=vimSynRegPat skipwhite
syn match vimSyncLines '\%(min\|max\)\=lines=' contained nextgroup=vimNumber
syn match vimSyncGroupName '\h\w*' contained nextgroup=vimSyncKey skipwhite

syn match vimSyncKey '\<groupthere\|grouphere\>'
    \ contained
    \ nextgroup=vimSyncGroup
    \ skipwhite

syn match vimSyncGroup '\h\w*'
    \ contained
    \ nextgroup=vimSynRegPat,vimSyncNone
    \ skipwhite

syn keyword vimSyncNone NONE contained

# Additional IsCommand: here by reasons of precedence {{{1

syn match vimIsCommand '<Bar>\s*\a\+'
    \ contains=vimCommand,vimNotation
    \ transparent

# Highlighting {{{1

syn cluster vimHighlightCluster
    \ contains=vimComment,vimHiClear,vimHiKeyList,vimHiLink

syn match vimHiCtermError '\D\i*' contained

syn match vimHighlight '\<hi\%[ghlight]\>'
    \ nextgroup=@vimHighlightCluster,vimHiBang
    \ skipwhite

syn match vimHiBang '!' contained nextgroup=@vimHighlightCluster skipwhite

syn match vimHiGroup '\i\+' contained

syn case ignore
syn keyword vimHiAttrib contained
    \ none bold inverse italic nocombine reverse standout strikethrough
    \ underline undercurl
syn keyword vimFgBgAttrib none bg background fg foreground contained
syn case match

syn match vimHiAttribList '\i\+' contained contains=vimHiAttrib

syn match vimHiAttribList '\i\+,'he=e-1
    \ contained
    \ contains=vimHiAttrib
    \ nextgroup=vimHiAttribList

syn case ignore
syn keyword vimHiCtermColor contained
    \ black blue brown cyan darkblue darkcyan darkgray darkgreen darkgrey
    \ darkmagenta darkred darkyellow gray green grey lightblue lightcyan
    \ lightgray lightgreen lightgrey lightmagenta lightred magenta red white
    \ yellow
syn match vimHiCtermColor '\<color\d\{1,3}\>' contained
syn case match

syn match vimHiFontname '[a-zA-Z\-*]\+' contained
syn match vimHiGuiFontname /'[a-zA-Z\-* ]\+'/ contained
syn match vimHiGuiRgb '#\x\{6}' contained

# Highlighting: hi group key=arg ... {{{1

syn cluster vimHiCluster contains=
    \vimGroup,vimHiCTerm,vimHiCtermFgBg,vimHiCtermul,vimHiGroup,vimHiGui
    \,vimHiGuiFgBg,vimHiGuiFont,vimHiKeyError,vimHiStartStop,vimHiTerm
    \,vimNotation

syn region vimHiKeyList
    \ start='\i\+'
    \ skip='\\\\\|\\|'
    \ end='$\||'
    \ contained
    \ contains=@vimHiCluster
    \ oneline

syn match vimHiKeyError '\i\+='he=e-1 contained
syn match vimHiTerm '\cterm='he=e-1 contained nextgroup=vimHiAttribList

syn match vimHiStartStop '\c\%(start\|stop\)='he=e-1
    \ contained
    \ nextgroup=vimHiTermcap,vimOption

syn match vimHiCTerm '\ccterm='he=e-1 contained nextgroup=vimHiAttribList

syn match vimHiCtermFgBg '\ccterm[fb]g='he=e-1
    \ contained
    \ nextgroup=vimFgBgAttrib,vimHiCtermColor,vimHiCtermError,vimHiNmbr

syn match vimHiCtermul '\cctermul='he=e-1
    \ contained
    \ nextgroup=vimFgBgAttrib,vimHiCtermColor,vimHiCtermError,vimHiNmbr

syn match vimHiGui '\cgui='he=e-1 contained nextgroup=vimHiAttribList
syn match vimHiGuiFont '\cfont='he=e-1 contained nextgroup=vimHiFontname

syn match vimHiGuiFgBg '\cgui\%([fb]g\|sp\)='he=e-1
    \ contained
    \ nextgroup=vimFgBgAttrib,vimHiGroup,vimHiGuiFontname,vimHiGuiRgb

syn match vimHiTermcap '\S\+' contained contains=vimNotation
syn match vimHiNmbr '\d\+' contained

# Highlight: clear {{{1

# `skipwhite` is necessary for `{group}` to be highlighted in `hi clear {group}`.
syn keyword vimHiClear clear contained nextgroup=vimHiGroup skipwhite

# Highlight: link {{{1
# see tst24 (hi def vs hi) (Jul 06, 2018)

exe 'syn region vimHiLink'
    .. ' matchgroup=vimCommand'
    .. ' start=/'
    .. '\%(\<hi\%[ghlight]\s\+\)\@<='
    .. '\%(\%(def\%[ault]\s\+\)\=link\>\|\<def\>\)'
    .. '/'
    .. ' end=/$/'
    .. ' contained'
    .. ' contains=@vimHiCluster'
    .. ' oneline'

syn cluster vimFuncBodyList add=vimHiLink

# Control Characters {{{1

syn match vimCtrlChar '[\x01-\x08\x0b\x0f-\x1f]'

# Beginners - Patterns that involve ^ {{{1

syn match vimLineComment '^[ \t:]\+#.*$' contains=@vimCommentGroup

# We've tweaked the original rule.{{{
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
syn match vimCommentTitle '#\s*\u\%(\w\|[()]\)*\%(\s\+\u\w*\)*:'hs=s+1
    \ contained
    \ contains=@vimCommentGroup

syn match vimContinue '^\s*\\'
    \ nextgroup=vimSynContains,vimSynMtchGrp,vimSynNextgroup,vimSynReg,vimSynRegOpt
    \ skipwhite

syn region vimString
    \ start=/^\s*\\\z(['"]\)/
    \ skip=/\\\\\|\\\z1/
    \ end=/\z1/
    \ contains=@vimStringGroup,vimContinue
    \ keepend
    \ oneline

# Searches And Globals {{{1

syn match vimSearch '^\s*:[/?].*' contains=vimSearchDelim
syn match vimSearchDelim '^\s*:\zs[/?]\|[/?]$' contained

syn region vimGlobal
    \ matchgroup=Statement
    \ start='\<g\%[lobal]!\=/'
    \ skip='\\.'
    \ end='/'
    \ nextgroup=vimSubst
    \ skipwhite

syn region vimGlobal
    \ matchgroup=Statement
    \ start='\<v\%[global]!\=/'
    \ skip='\\.'
    \ end='/'
    \ nextgroup=vimSubst
    \ skipwhite

# Patterns used as command arguments {{{1

# Problem: A pattern can contain any text; in particular, an unbalanced paren is
# possible.  But this breaks all the subsequent syntax highlighting.
#
# Solution: Make sure all patterns are highlighted as strings.
# Let's start with a `:catch` pattern.
#
# NOTE: We  could  achieve  the  desired  result  with  a  single  rule,  and  a
# lookbehind.  But it would be more costly.
syn match vimCatch '\<catch\s\+/[^/]*/$' containedin=vimFuncBody contains=vimCatchPattern
syn match vimCatchPattern '/.*/' contained

# Embedded Scripts  {{{1

unlet! b:current_syntax
syn include @vimPythonScript syntax/python.vim

syn region vimPythonRegion
    \ matchgroup=vimScriptDelim
    \ start=/py\%[thon][3x]\=\s*<<\s*\z(\S*\)\ze\%(\s*#.*\)\=$/
    \ end=/^\z1\ze\%(\s*".*\)\=$/
    \ contains=@vimPythonScript

syn region vimPythonRegion
    \ matchgroup=vimScriptDelim
    \ start=/py\%[thon][3x]\=\s*<<\s*$/
    \ end=/\.$/
    \ contains=@vimPythonScript

syn region vimPythonRegion
    \ matchgroup=vimScriptDelim
    \ start=/Py\%[thon]2or3\s*<<\s*\z(\S*\)\ze\%(\s*#.*\)\=$/
    \ end=/^\z1\ze\%(\s*".*\)\=$/
    \ contains=@vimPythonScript

syn region vimPythonRegion
    \ matchgroup=vimScriptDelim
    \ start=/Py\%[thon]2or3\=\s*<<\s*$/
    \ end=/\.$/
    \ contains=@vimPythonScript

syn cluster vimFuncBodyList add=vimPythonRegion

unlet! b:current_syntax
syn include @vimLuaScript syntax/lua.vim

syn region vimLuaRegion
    \ matchgroup=vimScriptDelim
    \ start=/lua\s*<<\s*\z(.*\)$/
    \ end=/^\z1$/
    \ contains=@vimLuaScript

syn region vimLuaRegion
    \ matchgroup=vimScriptDelim
    \ start=/lua\s*<<\s*$/
    \ end=/\.$/
    \ contains=@vimLuaScript

syn cluster vimFuncBodyList add=vimLuaRegion

# Synchronize (speed) {{{1

syn sync maxlines=60
syn sync linecont '^\s\+\\'
syn sync match vimAugroupSyncA groupthere NONE '\<aug\%[roup]\>\s\+END'

# Highlight Groups {{{1

hi link vimCommand Statement
# Make Vim highlight custom commands in a similar way as for builtin Ex commands.{{{
#
# With a  twist: we  want them  to be italicized,  so that  we can't  conflate a
# custom command with a builtin one.
#
# If you don't care about this distinction, you could get away with just:
#
#     hi link vimUserCommandName vimCommand
#}}}
# The guard makes sure the highlighting group is defined only if necessary.{{{
#
# Note that  when the syntax  item for `vimusrCmd`  was defined earlier  (with a
# `:syn` command), Vim has automatically created a highlight group with the same
# name; but it's cleared:
#
#     vimUserCommandName      xxx cleared
#
# That's why we don't write this:
#
#     if execute('hi vimUserCommandName') == ''
#                                         ^---^
#                                           ✘
#}}}
if execute('hi vimUserCommandName') =~ '\<cleared$'
    # TODO(lgc): If you intend  to extract the current script  into a standalone
    # plugin, move `Derive()` here (in an  `import/` subdir so that we can still
    # import it from other plugins).
    import Derive from 'lg/syntax.vim'
    Derive('vimUserCallFuncName', 'Function', 'term=italic cterm=italic gui=italic')
    Derive('vimUserCommandName', 'vimCommand', 'term=italic cterm=italic gui=italic')
    Derive('vimUserFunctionHeader', 'Function', 'term=italic cterm=italic gui=italic')
endif

hi link vimCollClassErr vimError
hi link vimErrSetting vimError
hi link vimFTError vimError
hi link vimFunctionError vimError
hi link vimCallFuncName vimError
hi link vimHiAttribList vimError
hi link vimHiCtermError vimError
hi link vimHiKeyError vimError
hi link vimMapModErr vimError
hi link vimSubstFlagErr vimError
hi link vimSynCaseError vimError
hi link vimBufnrWarn vimWarn

hi link vimAbb vimCommand
hi link vimAddress vimMark
hi link vimAugroupEnd Special
hi link vimAugroupError vimError
hi link vimAutoCmd vimCommand
hi link vimAutoEvent Type
hi link vimAutoCmdMod Special
hi link vimBool Boolean
hi link vimBracket Delimiter
hi link vimCatch vimCommand
hi link vimCatchPattern String
hi link vimCmplxRepeat SpecialChar
hi link vimComment Comment
hi link vimCommentString vimString
hi link vimCommentTitle PreProc
hi link vimCondHL vimCommand
hi link vimConstant Constant
hi link vimContinue Special
hi link vimCtrlChar SpecialChar
hi link vimDataType Type
hi link vimDataTypeCast vimDataType
hi link vimDataTypeCastComplexEnd vimDataType
hi link vimDataTypeCastComplexStart vimDataType
hi link vimDataTypeComplexColon vimDataType
hi link vimDataTypeFuncref vimDataType
hi link vimDataTypeListDict vimDataType
hi link vimDictLiteralKey Error
hi link vimDictLiteralKeyValid String
hi link vimDictLiteralLegacyError Error
hi link vimEchoHLNone vimGroup
hi link vimEchoHL vimCommand
hi link vimElseIfErr Error
hi link vimEnvVar vimVar
hi link vimError Error
hi link vimFBVar vimVar
hi link vimFgBgAttrib vimHiAttrib
hi link vimHiCtermul vimHiTerm
hi link vimFTCmd vimCommand
hi link vimFTOption vimSynType
hi link vimDefKey vimCommand
hi link vimBuiltinFuncName Function
hi link vimFuncScope Special
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
hi link vimLambdaArrow Delimiter
hi link vimDeclare vimCommand
hi link vimHereDoc vimString
hi link vimHereDocStart Special
hi link vimHereDocStop Special
hi link vimLineComment vimComment
hi link vimMapBang vimCommand
hi link vimMapModKey vimFuncScope
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
hi link vimNull Constant
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
hi link vimVar Identifier
hi link vimWarn WarningMsg
#}}}1

b:current_syntax = 'vim'
