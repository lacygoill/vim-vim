if exists('g:loaded_vim')
    finish
endif
let g:loaded_vim = 1

" Suppress spurious errors highlighting (frequently happens when the syntax is temporarily out of sync).
let g:vimsyn_noaugrouperror = 1
" You can be more radical with:
"     let g:vimsyn_noerror = 1
