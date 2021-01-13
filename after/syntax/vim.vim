vim9

import Derive from 'lg/syntax.vim'
# Make Vim highlight custom commands – like `:Plug` – in a similar way as for builtin Ex commands.{{{
#
# With a  twist: we  want them  to be italicized,  so that  we can't  conflate a
# custom command with a builtin one.
#
# If you don't care about this distinction, you could get away with just:
#
#     hi link vimUsrCmd vimCommand
#}}}
sil! Derive('vimUsrCmd', 'vimCommand', 'term=italic cterm=italic gui=italic')

# TODO: The next rules try to fix various issues.{{{
#
# From time to  time, disable them temporarily to check  whether the issues have
# been fixed in Vim.
#
# ---
#
# Also, I haven't reported all of them on github.
# Look for any snipppet which doesn't include a link to a report.
# Whenever you find one, report the issue.
#}}}

# Vim9 {{{1

# Problem: In a declaration, a variable name is not highlighted correctly if it shadows an Ex command.
# Solution: Include the keyword `var` in the syntax group `vimLet`.{{{
#
# Note  that this  only fixes  the issue  in a  declaration; it  persists in  an
# assignment:
#
#            ✔
#         v------v
#     var undolist: list<number>
#     undolist = [1, 2, 3]
#     ^------^
#        ✘
#}}}
syn keyword vimLet var skipwhite nextgroup=vimVar,vimFuncVar,vimLetHereDoc

# Comments {{{1

# Problem: `:h line-continuation-comment` is not highlighted inside a dictionary.
# Solution: Include the syntax group `vimLineComment` in the cluster `@vimOperGroup`.
# https://github.com/vim/vim/issues/6592

vim#syntax#tweakCluster('@vimOperGroup', 'vimLineComment')

# Problem: Vim9 comment leader not highlighted on empty commented line inside dictionary inside function.
# Solution: Include the syntax group `vim9LineComment` in the `vimOperGroup` cluster.

vim#syntax#tweakCluster('@vimOperGroup', 'vim9LineComment')

# Problem: Vim9 comment leader not highlighted on empty commented line inside function.
# Solution: Include the syntax group `vim9LineComment` in the `vimFuncBodyList` cluster.
# https://github.com/vim/vim/issues/6600

vim#syntax#tweakCluster('@vimFuncBodyList', 'vim9LineComment')

# Problem: The `#` prefix in a literal dictionary is not highlighted.
# Solution: Add a rule to highlight it.

syn region vimOperParen matchgroup=vimSep  start='#{' end='}' contains=@vimOperGroup nextgroup=vimVar,vimFuncVar
#                                                 ^

# Problem: Title in Vim9 comment not highlighted.
# Solution: Recognize `#` comment leader.
# https://github.com/vim/vim/issues/6599

syn clear vimCommentTitle
syn match vimCommentTitle '["#]\s*\%([sS]:\|\h\w*#\)\=\u\w*\(\s\+\u\w*\)*:'hs=s+1
    \ contained contains=vimCommentTitleLeader,vimTodo,@vimCommentGroup

# Problem: `#{` in `#{{ {` is wrongly parsed as the start of a literal dictionary (which breaks all subsequent syntax).
# Solution: Allow `{{ {` after Vim9 comment leader.
# https://github.com/vim/vim/issues/6601

# Problem: A title is not highlighted inside a Vim9 comment at the script level.
# Solution: Allow a title in a comment at the script level.{{{
#
# Make each `vim9Comment` item contain the `vimCommentTitle` syntax group.
#
#     syn match vim9Comment ... contains=@vimCommentGroup,...,vimCommentTitle
#                                                             ^-------------^
#     ...
#}}}

syn clear vim9Comment
if getline(1) =~ '^\Cvim9\%[script]\>'
    # FIXME: `#` is wrongly parsed as a comment leader in a legacy function in a Vim9 script.
    # This  is  hard  to  fix,  because  the  default  syntax  plugin  does  not
    # distinguish a `:def` function from a `:fu` one.
    syn match vim9Comment excludenl +^#.*$+               contains=@vimCommentGroup,vimCommentString,vimCommentTitle
    syn match vim9Comment excludenl +\s#.*$+lc=1          contains=@vimCommentGroup,vimCommentString,vimCommentTitle
    syn match vim9Comment           +\<endif\s\+#.*$+lc=5 contains=@vimCommentGroup,vimCommentString,vimCommentTitle
    syn match vim9Comment           +\<else\s\+#.*$+lc=4  contains=@vimCommentGroup,vimCommentString,vimCommentTitle
    syn match vim9Comment           +\s\zs#.*$+ms=s+1     contains=@vimCommentGroup,vimCommentString,vimCommentTitle

    # Problem: A string in an automatic continuation line is wrongly highlighted as a comment.{{{
    #
    #     vim9
    #
    #     var l = [
    #        "highlighted as a comment, while it is a string"
    #         ]
    #}}}
    # Solution: Clear `vimLineComment`.
    # FIXME: This doesn't work in a `:def` function in a legacy Vim script.{{{
    #
    # We really need a different syntax group for `:def` functions.
    #
    # ---
    #
    # Also, this breaks a legacy comment in  a legacy function in a Vim9 script,
    # when the comment leader is on the very first column.
    #}}}
    syn clear vimLineComment
else
    # FIXME: `#` is wrongly parsed as a comment leader in a legacy script.
    # FIXME: `#{}` is wrongly parsed as a literal dictionary in a `:def` function, in a legacy script.
    syn clear vim9Comment
    syn match vim9Comment excludenl +^#\%([^{]\|{{\%x7b\).*$+               contains=@vimCommentGroup,vimCommentString,vimCommentTitle
    syn match vim9Comment excludenl +\s#\%([^{]\|{{\%x7b\).*$+lc=1          contains=@vimCommentGroup,vimCommentString,vimCommentTitle
    syn match vim9Comment           +\<endif\s\+#\%([^{]\|{{\%x7b\).*$+lc=5 contains=@vimCommentGroup,vimCommentString,vimCommentTitle
    syn match vim9Comment           +\<else\s\+#\%([^{]\|{{\%x7b\).*$+lc=4  contains=@vimCommentGroup,vimCommentString,vimCommentTitle
    syn match vim9Comment           +\s\zs#\%([^{]\|{{\%x7b\).*$+ms=s+1     contains=@vimCommentGroup,vimCommentString,vimCommentTitle
endif

# Problem: The `? expr1` might be wrongly highlighted when written at the start of a line.{{{
#
# Only when using an automatic line continuation.
# Example:
#
#     [prefix, size] = cmd =~ '^l'
#         ?     ['l', getloclist(0, {size: 0}).size]
#         :     ['c', getqflist({size: 0}).size]
#}}}
# Solution: Tweak `vimSearch` so that it doesn't highlight `?` as a search command anymore.
syn clear vimSearch
syn match vimSearch +^\s*[/].*+ contains=vimSearchDelim

# Misc. {{{1

# Problem: The new `<cmd>` pseudo-key is not highlighted.
# Solution: Add an item in the `vimNotation` syntax group.
syn match vimNotation '\%#=1\c\%(\\\|<lt>\)\=<cmd>' contains=vimBracket

# Problem: In `hi clear {group}`, `{group}` is not highlighted.
# Solution: Pass `skipwhite` to `:syn keyword`.

syn clear vimHiClear
syn keyword vimHiClear contained clear skipwhite nextgroup=vimHiGroup

# Problem: In `syn clear {group}`, `{group}` is not highlighted.
# Solution: See this diff:{{{
#
#     line 478
#     -syn match	vimGroupList	contained	"@\=[^ \t,]*"	contains=vimGroupSpecial,vimPatSep
#     +syn match	vimGroupList	contained	"@\=[^ \t,]\+"	contains=vimGroupSpecial,vimPatSep
#
#     line 501
#     -syn keyword	vimSynType	contained	clear	skipwhite nextgroup=vimGroupList
#     +syn keyword	vimSynType	contained	clear	skipwhite nextgroup=vimGroupList,vimHiGroup
#}}}
# Why don't you clear `vimSynType`?{{{
#
# We don't need to.
# Besides, it contains too many items.  It would be cumbersome to redefine them.
#}}}

syn keyword vimSynType contained clear skipwhite nextgroup=vimGroupList,vimHiGroup
syn clear vimGroupList
syn match vimGroupList contained '@\=[^ \t,]\+' contains=vimGroupSpecial,vimPatSep
syn match vimGroupList contained '@\=[^ \t,]*,' nextgroup=vimGroupList contains=vimGroupSpecial,vimPatSep
# This is not in the previous diff.  So, why do you redefine `vimHiGroup`?{{{
#
# We need to, otherwise we wouldn't get the desired result.
# It's probably an issue of priority.
#
# The `vimHiGroup` rule must come *after* the `vimGroupList`.
# We've just  redefined the  latter, which –  in effect –  moves its  rule after
# `vimHiGroup`.  To  preserve the relative order  of the rules, we  need to also
# redefine `vimHiGroup`.
#}}}
syn match vimHiGroup contained '\i\+'

# Problem: The default `vimUsrCmd` highlights too much.{{{
#
#     $VIMRUNTIME/syntax/vim.vim
#     /vimUsrCmd
#
#     syn match vimUsrCmd       '^\s*\zs\u\w*.*$'
#                                            ^^
#                                            ✘
#}}}
# Solution:  Make `vimUsrCmd` highlight only the command name.
# https://github.com/vim/vim/issues/6587

syn clear vimUsrCmd
syn match vimUsrCmd '^\s*\zs\u\%(\w*\)\@>\%([(#]\|\s\+\%([-+*/%]\=\|\.\.\)=\)\@!'
#                                            ├┘   ├─────────────────────────┘ {{{
#                                            │    │
#                                            │    └ and don't highlight a capitalized variable name,
#                                            │      in an assignment without declaration:
#                                            │
#                                            │        var MYCONSTANT: number
#                                            │        MYCONSTANT = 12
#                                            │        MYCONSTANT += 34
#                                            │        MYCONSTANT *= 56
#                                            │        ...
#                                            │
#                                            └ In a Vim9 script, don't highlight a custom Vim function
#                                              invoked without ":call".
#
#                                                  Func()
#                                                  ^--^
#
#                                              And don't highlight a capitalized autoload function name,
#                                              in a function call:
#
#                                                 Script#func()
#                                                 ^----^
#}}}
# Problem: A custom command name is not highlighted inside a function.
# Solution: Include `vimUsrCmd` inside the `vimFuncBodyList` cluster.
syn cluster vimFuncBodyList add=vimUsrCmd

# Problem: In an `:echo` command, the `->` method tokens, and functions parentheses, are wrongly highlighted.
# Solution: Allow `vimOper` and `vimOperParen` to start in a `vimEcho` region.
# Problem: An inline comment is not properly highlighted after an `:echo` in a Vim9 script.{{{
#
#     vim9
#     echo 1 + 1 # some comment
#                ^------------^
#}}}
# Solution: Allow `vim9Comment` to be contained in `vimEcho`.

syn region vimEcho oneline excludenl matchgroup=vimCommand
    \ start="\<ec\%[ho]\>" skip="\(\\\\\)*\\|" end="$\||"
    \ contains=vimFunc,vimFuncVar,vimString,vimVar,vimOper,vimOperParen,vim9Comment
    #                                              ^------------------^ ^---------^

# Problem: The `substitute()` function is wrongly highlighted as a command when used as a method.
# Solution: Disallow `(` after `substitute`.
# https://github.com/vim/vim/issues/6611

syn clear vimSubst
syn match vimSubst
    \ "\(:\+\s*\|^\s*\||\s*\)\<\%(\<s\%[ubstitute]\>\|\<sm\%[agic]\>\|\<sno\%[magic]\>\)[:#[:alpha:]]\@!"
    \ nextgroup=vimSubstPat
syn match vimSubst
    \ "\%(^\|[^\\\"']\)\<\%(s\%[ubstitut]\|substitute(\@!\)\>[:#[:alpha:]\"']\@!"
    \ nextgroup=vimSubstPat contained
syn match vimSubst "/\zs\<s\%[ubstitute]\>\ze/" nextgroup=vimSubstPat
syn match vimSubst "\(:\+\s*\|^\s*\)s\ze#.\{-}#.\{-}#" nextgroup=vimSubstPat

# Problem: Inside a heredoc, the text following a double quote is highlighted as a Vim comment.{{{
#
# First I find  this unexpected.  I would  expect everything in a  heredoc to be
# highlighted  as a  string; because  that's what  it really  is.  A  comment is
# unexecuted source code; a string is not code; it's data.
#
# Second, we applyg various styles inside comments, such as bold or italics.
# Again, it's unexpected and distracting to see those styles in a heredoc.
#}}}
# Solution: Remove `contains=vimComment,vim9Comment` from `vimLetHereDoc`.
syn clear vimLetHereDoc
syn region vimLetHereDoc matchgroup=vimLetHereDocStart
    \ start='=<<\s\+\%(trim\>\)\=\s*\z(\L\S*\)'
    \ matchgroup=vimLetHereDocStop
    \ end='^\s*\z1\s*$'

