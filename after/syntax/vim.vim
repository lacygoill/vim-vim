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
"     i
"     xx
"     END
"
" Here, everything after `i` is highlighted as a string.
" The issue comes from the `normal` key; here, the highlighting is correct:
"
"              v
"     let dict.xormal =<< trim END
"     i
"     xx
"     END
"
" If you inspect the syntax highlighting on `=<< trim END`, you'll see `vimNormCmds`.
" So, you need `vimFuncBody` and `vimNormCmds`.
" But who knows what other corner cases exist which require additional syntax groups.
" If you want to cover all possible cases, you need `ALL`.
" But that would make you lose syntax highlighting in a commented heredoc.
" Final solution: use `ALLBUT,vimLineComment`.
"}}}
