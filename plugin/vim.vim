vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

# Suppress spurious errors highlighting (frequently happens when the syntax is temporarily out of sync).
g:vimsyn_noaugrouperror = 1
# You can be more radical with:
#
#     g:vimsyn_noerror = 1
