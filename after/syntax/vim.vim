import Derive from 'lg/syntax.vim'
" Make Vim highlight custom commands – like `:Plug` – in a similar way as for builtin Ex commands.{{{
"
" With a  twist: we  want them  to be italicized,  so that  we can't  conflate a
" custom command with a builtin one.
"
" If you don't care about this distinction, you could get away with just:
"
"     hi link vimUsrCmd vimCommand
"}}}
sil! call s:Derive('vimUsrCmd', 'vimCommand', 'term=italic cterm=italic gui=italic')

" TODO: The next rules try to fix various issues.{{{
"
" From time to  time, disable them temporarily to check  whether the issues have
" been fixed in Vim.
"
" ---
"
" Also, I haven't reported all of them on github.
" Look for any snipppet which doesn't include a link to a report.
" Whenever you find one, report the issue.
"}}}

" Problem: In `hi clear {group}`, `{group}` is not highlighted.
" Solution: Pass `skipwhite` to `:syn keyword`.
syn clear vimHiClear
syn keyword vimHiClear contained clear skipwhite nextgroup=vimHiGroup

" Problem: In `syn clear {group}`, `{group}` is not highlighted.
" Solution: See this diff:{{{
"
"     line 478
"     -syn match	vimGroupList	contained	"@\=[^ \t,]*"	contains=vimGroupSpecial,vimPatSep
"     +syn match	vimGroupList	contained	"@\=[^ \t,]\+"	contains=vimGroupSpecial,vimPatSep
"
"     line 501
"     -syn keyword	vimSynType	contained	clear	skipwhite nextgroup=vimGroupList
"     +syn keyword	vimSynType	contained	clear	skipwhite nextgroup=vimGroupList,vimHiGroup
"}}}
" Why don't you clear `vimSynType`?{{{
"
" We don't need to.
" Besides, it contains too many items.  It would be cumbersome to redefine them.
"}}}
syn keyword vimSynType contained clear skipwhite nextgroup=vimGroupList,vimHiGroup
syn clear vimGroupList
syn match vimGroupList contained '@\=[^ \t,]\+' contains=vimGroupSpecial,vimPatSep
syn match vimGroupList contained '@\=[^ \t,]*,' nextgroup=vimGroupList contains=vimGroupSpecial,vimPatSep
" This is not in the previous diff.  So, why do you redefine `vimHiGroup`?{{{
"
" We need to, otherwise we wouldn't get the desired result.
" It's probably an issue of priority.
"
" The `vimHiGroup` rule must come *after* the `vimGroupList`.
" We've just  redefined the  latter, which –  in effect –  moves its  rule after
" `vimHiGroup`.  To  preserve the relative order  of the rules, we  need to also
" redefine `vimHiGroup`.
"}}}
syn match vimHiGroup contained '\i\+'

" Comments {{{1

" Problem: `:h line-continuation-comment` is not highlighted inside a dictionary.
" Solution: Include the syntax group `vimLineComment` in the cluster `@vimOperGroup`.
" https://github.com/vim/vim/issues/6592
call vim#syntax#include_group_in_cluster('vimOperGroup', 'vimLineComment')

" Problem: Vim9 comment leader not highlighted on empty commented line inside function.
" Solution: Include the syntax group `vim9LineComment` in the `vimFuncBodyList` cluster.
" https://github.com/vim/vim/issues/6600
call vim#syntax#include_group_in_cluster('vimFuncBodyList', 'vim9LineComment')

" Problem: Title in Vim9 comment not highlighted.
" Solution: Recognize `#` comment leader.
" https://github.com/vim/vim/issues/6599
syn clear vimCommentTitle
syn match vimCommentTitle '["#]\s*\%([sS]:\|\h\w*#\)\=\u\w*\(\s\+\u\w*\)*:'hs=s+1
    \ contained contains=vimCommentTitleLeader,vimTodo,@vimCommentGroup

" Problem: `#{` in `#{{ {` is wrongly parsed as the start of a literal dictionary.
" Solution: Allow `{{ {` after Vim9 comment leader.
" https://github.com/vim/vim/issues/6601
syn clear vim9Comment
syn match vim9Comment excludenl +^#\%([^{]\|{{\%x7b\).*$+               contains=@vimCommentGroup,vimCommentString
syn match vim9Comment excludenl +\s#\%([^{]\|{{\%x7b\).*$+lc=1          contains=@vimCommentGroup,vimCommentString
syn match vim9Comment           +\<endif\s\+#\%([^{]\|{{\%x7b\).*$+lc=5 contains=@vimCommentGroup,vimCommentString
syn match vim9Comment           +\<else\s\+#\%([^{]\|{{\%x7b\).*$+lc=4  contains=@vimCommentGroup,vimCommentString
syn match vim9Comment           +\s\zs#\%([^{]\|{{\%x7b\).*$+ms=s+1     contains=@vimCommentGroup,vimCommentString

" Misc. {{{1

" Problem: The default `vimUsrCmd` highlights too much.{{{
"
"     $VIMRUNTIME/syntax/vim.vim
"     /vimUsrCmd
"
"     syn match vimUsrCmd       '^\s*\zs\u\w*.*$'
"                                            ^^
"                                            ✘
"}}}
" Solution:  Make `vimUsrCmd` highlight only the command name.
" https://github.com/vim/vim/issues/6587
syn clear vimUsrCmd
syn match vimUsrCmd '^\s*\zs\u\%(\w*\)\@>(\@!'
"                                     ^-----^
"                                     don't highlight a custom Vim function
"                                     invoked without ":call" in a Vim9 script

" Problem: In an `:echo` command, the `->` method tokens, and functions parentheses, are wrongly highlighted.
" Solution: Allow `vimOper` and `vimOperParen` to start in a `vimEcho` region.
syn region vimEcho oneline excludenl matchgroup=vimCommand
    \ start="\<ec\%[ho]\>" skip="\(\\\\\)*\\|" end="$\||"
    \ contains=vimFunc,vimFuncVar,vimString,vimVar,vimOper,vimOperParen
    "                                              ^------------------^

" Problem: The `substitute()` function is wrongly highlighted as a command when used as a method.
" Solution: Disallow `(` after `substitute`.
" https://github.com/vim/vim/issues/6611
syn clear vimSubst
syn match vimSubst
    \ "\(:\+\s*\|^\s*\||\s*\)\<\%(\<s\%[ubstitute]\>\|\<sm\%[agic]\>\|\<sno\%[magic]\>\)[:#[:alpha:]]\@!"
    \ nextgroup=vimSubstPat
syn match vimSubst
    \ "\%(^\|[^\\\"']\)\<\%(s\%[ubstitut]\|substitute(\@!\)\>[:#[:alpha:]\"']\@!"
    \ nextgroup=vimSubstPat contained
syn match vimSubst "/\zs\<s\%[ubstitute]\>\ze/" nextgroup=vimSubstPat
syn match vimSubst "\(:\+\s*\|^\s*\)s\ze#.\{-}#.\{-}#" nextgroup=vimSubstPat

