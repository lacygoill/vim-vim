" Make Vim color the custom commands `:Pab` and `:Aab` as builtin Ex commands.
" How did you find the syntax for this line of code?{{{
"
"     :e /tmp/vim.vim
"     :put ='inorea'
"     /inorea
"     !s
"     vimAbb~
"
"     :e $VIMRUNTIME/syntax/vim.vim
"     /vimAbb
"}}}
syn keyword vimAbb Aab Pab skipwhite nextgroup=vimMapMod,vimMapLhs
" TODO: Comment how `skipwhite` and `nextgroup` work.

" `:h line-continuation-comment` is not highlighted inside a dictionary
call vim#syntax#override_vimOperGroup()


" The following prevents the syntax highlighting from breaking inside and after a heredoc.
" It has been fixed in Vim:
" https://github.com/vim/vim/commit/574ee7bc1246070dba598f9561a2776aa1a10d07
" ... but not in Nvim yet.
if !has('nvim') | finish | endif

" Purpose:{{{
"
" At the  moment, there is no  syntax highlighting specific to  a heredoc, which
" means that any text it contains is highlighted as if it was Vimscript code.
" Depending on  what is written inside,  it may break the  syntax highlighing of
" what follows.
"
" As an example:
"
"     let list =<< trim END
"         a
"         b
"         c
"     END
"     let var = 123
"
" The `let  var = 123`  assignment is  highlighted according to  the `vimInsert`
" syntax group.
" This is because, inside the heredoc, the  `a` line and the `c` line are parsed
" as resp. the  `:append` and `:change` commands; this is  confirmed by the fact
" that the issue disappears if you append an `x` on these two lines:
"
"     let list =<< trim END
"         ax
"         b
"         cx
"     END
"     let var = 123
"
" Note that the issue does not occur inside a function; so here the highlighting
" is correct:
"
"     fu Func()
"         let list =<< trim END
"             ax
"             b
"             cx
"         END
"         let var = 123
"     endfu
"}}}
" Warning: The `start` and `end` patterns are not 100% correct.{{{
"
" The marker can be any non-whitespace sequence of characters, not starting with
" a lowercase character. So, this would be more reliable:
"
"     syn region vimFixHeredoc
"     \ start=/\%(\<\%(let\|const\)\>.\{-}=<<\s*\)\@<=\%(trim\s\+\)\=\z(\L\S*\)$/
"     \ end=/^\s*\z1$/
"     \ containedin=ALLBUT,vimLineComment
"
" We don't use it because it's way too costly (probably because of `\z(\)`).
" Check out with `:syntime`.
"
" ---
"
" There could be a continuation line anywhere:
"
"     l
"     \et l
"     \ist =
"     \<< t
"     \rim E
"     \ND
"         a
"         b
"         c
"     END
"
" We don't take that into account because it would make the regex too complex.
"
" Although,  you could  still replace  `.\{-}`  with `\_.\{-}`  to support  most
" common cases; atm, I don't, because it makes the regex more costly (≈ 50% time
" increase).
"}}}
syn region vimFixHeredoc
    \ start=/\%(\<\%(let\|const\=\)\>.\{-}=<<\s*\)\@<=\%(trim\s\+\)\=END$/
    \ end=/^\s*END$/
    \ containedin=ALLBUT,vimLineComment
" Is `ALLBUT` really needed?  Can't I be more specific?{{{
"
" First, you need `containedin` for heredocs which are not at the toplevel.
"
" Second, you  could replace `ALLBUT` with  `vimFuncBody`, and it would  fix the
" highlighting of most heredocs which are not at the toplevel. But not all:
"
"     let dict.normal =<< trim END
"         i
"         xx
"     END
"
" Here, everything after `i` is highlighted as a string.
" The issue comes from the `normal` key; here, the highlighting is correct:
"
"              v
"     let dict.xormal =<< trim END
"         i
"         xx
"     END
"
" If you inspect the syntax highlighting on `=<< trim END`, you'll see `vimNormCmds`.
" So, you need `vimFuncBody` and `vimNormCmds`.
" But who knows what other corner cases exist which require additional syntax groups.
" If you want to cover all possible cases, you need `ALL`.
" But that would make you lose syntax highlighting in a commented heredoc.
" Final solution: use `ALLBUT,vimLineComment`.
"}}}

