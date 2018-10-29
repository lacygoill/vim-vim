" Make Vim color the custom commands `:Aab` and `Lnorea`, and their arguments,
" (lhs, rhs) like it would with a default Ex command.
"
" I found the skeleton of this command in $VIMRUNTIME/syntax/vim.vim
" after searching for 'ino' (only 5 matches).

syn keyword vimMap Aab Pab skipwhite nextgroup=vimMapBang,vimMapMod,vimMapLhs

" replace noisy/ugly markers, used in folds, with ❭ and ❬

" We want to be sure that the folding markers will be concealed no matter
" the type of comments they are in.
" We can't use the value ALL for the `containedin` argument, because it would
" display several consecutive concealed markers, instead of a single one.
" So, we use a comma-separated list of syntax groups.
" We found it by typing:
"
"         :syn list vim*comment* C-d
"
" It lists all syntax groups, used in Vim files, containing the keyword `comment`.

syn cluster vimContainedin contains=vimComment,
                                   \vimCommentString,
                                   \vimCommentTitle,
                                   \vimCommentTitleLeader,
                                   \vimLineComment,
                                   \vimMtchComment,
                                   \vimMyComments

syn cluster vimContains contains=vimComment,
                                \vimCommentCode,
                                \vimCommentCodeAt,
                                \vimCommentString,
                                \vimCommentTitle,
                                \vimCommentTitleLeader,
                                \vimLineComment,
                                \vimMtchComment,

exe 'syn match vimFoldMarkers  /"\=\s*{'.'{{\d*\s*\ze\n/  conceal cchar=❭  containedin=@vimContainedin'
exe 'syn match vimFoldMarkers  /"\=\s*}'.'}}\d*\s*\ze\n/  conceal cchar=❬  containedin=@vimContainedin'

" syn match vimCommentCode '^\s*"@.*' containedin=vimComment,vimLineComment contains=vimCommentCodeAt
" syn match vimCommentCodeAt '^\s*"\zs@' conceal
" hi link vimCommentCode Number

" syn region vimMyComments oneline matchgroup=Comment start=/^\s*\zs"\s\?/ end=/$/ concealends contains=@vimContains,@vimCommentGroup
" hi link vimMyComments Comment
