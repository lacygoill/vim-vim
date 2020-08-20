vim9script

import Popup_notification from 'lg/popup.vim'

# Interface {{{1
def vim#refactor#vim9#main() #{{{2
    let view = winsaveview()

    # we might need to inspect the syntax under the cursor
    let syntax_was_on = exists('g:syntax_on')
    if !syntax_was_on
        syntax on
    endif
    # folding might interfere
    let folding_was_on = &l:fen
    setl nofen

    # Warning: Do *not* use `:silent` before a substitution command to which you pass the `c` flag.{{{
    #
    # You wouldn't see the prompt message on the command-line:
    #
    #     replace with X (y/n/a/q/l/^E/^Y)?
    #}}}

    # TODO: Make `:RefVim9` support a range.
    # TODO: should we highlight each text which is to be modified and ask for the user's confirmation?
    # TODO: should we invoke `:RefDot`?
    # TODO: check that commands starting with a range are prefixed with a colon
    # (tricky to recognize a range; writing a command name in its full form might help)
    # TODO: refactor all eval strings into lambdas (faster)
    Vim9script()
    Comments()
    Fu2Def()

    ImportNoReinclusionGuard()
    RemoveInvalid()
    CannotDeclarePublicVariable()
    ScriptLocalVariables()
    # `ProperWhitespace()` must be invoked *before* `UselessConstructs()`{{{
    #
    # The former might need to find `:call`.
    # And  the latter  might  perform  some wrong  refactorings  if all  useless
    # whitespace has  not been removed.  In  particular, it assumes that  – in a
    # function call –  there is no extra whitespace between  a function name and
    # the opening parenthesis.
    #}}}
    ProperWhitespace()
    UselessConstructs()
    Misc()
    OpenLocationWindow()

    if !syntax_was_on
        syntax off
    endif
    if folding_was_on
        setl fen
    endif
    winrestview(view)
enddef
#}}}1
# Core {{{1
def Vim9script() #{{{2
    if getline(1) != 'vim9script'
        append(0, ['vim9script', ''])
    endif
enddef

def Comments() #{{{2
    # `:h line-continuation-comment`
    :sil keepj keepp lockm %s/^\s*\zs"\\ /# /ge
    :sil keepj keepp lockm %s/"/\=GetNewCommentLeader()/ge
enddef

def GetNewCommentLeader(): string
    # a legacy comment leader must be highlighted as a comment
    if synstack('.', col('.'))
            ->map({_, v -> synIDattr(v, 'name')})
            ->match('\ccomment') != -1
        &&
            # but the character before must not
            (synstack('.', col('.') - 1)
                ->map({_, v -> synIDattr(v, 'name')})
                ->match('\ccomment') == -1
                # unless there is only indentation before
                # (yes, the indentation before a `"` comment leader is also part of the comment)
                || getline('.')->matchstr('^.*\%' .. col('.') .. 'c') =~ '^\s*$')
        return '#'
    else
        # the quote under the cursor is not a comment leader; leave it unchanged
        return '"'
    endif
enddef

def Fu2Def() #{{{2
    # TODO: Should support commented functions.
    # Look for the pattern `\^` in  this script, for other possible refactorings
    # which should be extended to comments.
    :sil keepj keepp lockm %s/^\C\s*fu\%[nction]\(!\=\)\s\+.\{-}\zs\s*abort\>//e
    :sil keepj keepp lockm %s/^\C\s*\zsfu\%[nction]\(!\=\)\ze\s\+/def\1/e
    :sil keepj keepp lockm %s/^\C\s*\zsendf\%[unction]$/enddef/e
    # TODO: In an  `import/` subdirectory, add  export in front of  the autoload
    # functions.  Also, refactor their names:
    #
    #     fu foo#bar#baz()
    #     →
    #     export def Baz()
    #
    # But don't forget to refactor this name everywhere, including in the script
    # which  you're refactoring  (yes, it  might call  one of  its own  autoload
    # functions).
    # For matches outside the refactored script, the refactoring is non-trivial,
    # because you  need to import  the function; you'll  need to add  a location
    # list on the stack, and let the user perform those refactorings manually.
enddef

def ImportNoReinclusionGuard() #{{{2
    # No need of a re-inclusion guard in an import script. {{{
    #
    # From `:h :import`:
    #
    #    > Once a vim9 script file has been imported, the result is cached and used the
    #    > next time the same script is imported.  It will not be read again.
    #}}}
    if expand('%:p') =~ '/import/'
        let pat = '\C\<if\>\s*.*\<\(g:[a-zA-Z0-9_#]*loaded[a-zA-Z0-9_#]*\).*'
            .. '\n\s*finish'
            .. '\nendif'
            .. '\nlet\s*\1\s*='
        exe ':sil! 0/' .. pat .. '/;+4 d_'
    endif
enddef

def RemoveInvalid() #{{{2
    let info = Popup_notification('a:funcarg → funcarg')
    :keepj keepp lockm %s/\C\<a:\ze\D//gce
    popup_close(info[1])

    info = Popup_notification('l:funcvar → funcvar')
    :keepj keepp lockm %s/\C&\@1<!\<l://gce
    popup_close(info[1])

    info = Popup_notification('is# → ==')
    :keepj keepp lockm %s/\C\<is#/==/gce
    :keepj keepp lockm %s/\C\<isnot#/!=/gce
    :keepj keepp lockm %s/\C\<is?/==?/gce
    :keepj keepp lockm %s/\C\<isnot?/!=?/gce
    popup_close(info[1])
enddef

def CannotDeclarePublicVariable() #{{{2
    # E1016: Cannot declare a global variable: g:var
    # You can declare a script-local variable at  the script level, but not in a
    # `:def` function.
    let info = Popup_notification('let g:var = 123 → g:var = 123')
    :keepj keepp lockm %s/\C\zs\<let\s\+\ze[bgtvw]:\S//gce
    popup_close(info[1])

    # Cannot declare environment variable (`E1016`), nor Vim option (`E1052`)
    info = Popup_notification('let $ENVVAR = 123 → $ENVVAR = 123')
    :keepj keepp lockm %s/\C\zs\<let\s\+\ze[$&]\S//gce
    popup_close(info[1])
enddef

def ScriptLocalVariables() #{{{2
    let lines =<< trim END
    " in function
    let s:var = 123
    →
    s:var = 123

    " at script level
    let s:var = 123
    →
    let var = 123
    END
    let info = Popup_notification(lines)
    :keepj keepp lockm sil %s/\C\<\(let\|const\=\)\s\+s:\ze\S/\=GetNewAssignment()/gce
    popup_close(info[1])
enddef

def GetNewAssignment(): string
    # Why not `searchpair()`?{{{
    #
    #     searchpair('^\C\s*\<def\>', '', '^\C\s*\<enddef\>$', 'cnW')
    #
    # We could,  but we would have  to be careful not  to move the order  of the
    # function calls in  `#vim9#main()`.  Depending on the order,  we might need
    # to look for `fu`  and `endfu`, instead of `def` and  `enddef`.  I guess we
    # could look for both (`fu\|def`, `endfu\|enddef`)...
    #
    # In any case, inspecting the syntax seems more reliable.
    #}}}
    if synstack('.', col('.'))
        ->map({_, v -> synIDattr(v, 'name')})
        ->match('\cvimfuncbody') == -1
        return submatch(1) .. ' '
    else
        return 's:'
    endif
enddef

def ProperWhitespace() #{{{2
    let lines =<< trim END
        {_,v -> ...}
        →
        {_, v -> ...}
    END
    let info = Popup_notification(lines)
    :keepj keepp lockm %s/{\s*[^ ,]\+,\zs\ze[^ ,]\+\s*->/ /gce
    popup_close(info[1])

    info = Popup_notification('let var= 234    # Error!')
    :keepj keepp lockm %s/\C\<let\s\+.*\S\zs\ze\\\@1<!=/ /gce
    popup_close(info[1])

    info = Popup_notification('let var =234    # Error!')
    :keepj keepp lockm %s/\C\<let\s\+.*=\\\@!\zs\ze\S\%(.*\i\)/ /gce
    popup_close(info[1])

    info = Popup_notification('let var = 234# Error!')
    :keepj keepp lockm %s/\C\<let\s\+.*=.*\S\zs\ze#{\@!\s\+/ /gce
    #                                                  ^--^{{{
    #                                                  technically, we should remove this, but:
    #                                                  - in practice, it probably won't matter
    #                                                  - it should remove false positives
    #                                                  (e.g. # inside a string)
    #}}}
    popup_close(info[1])

    info = Popup_notification('call Func (arg) # Error!')
    :keepj keepp lockm %s/\C\<call\s\+[a-zA-Z_:]\+\zs\s\+\ze(//gce
    popup_close(info[1])
    # TODO: check white space is correctly used in other contexts{{{
    #
    #     let x = 1+2 # Error! (tricky to find; many possible operators, and many types of operands)
    #     let l = [1 , 2 , 3] # Error!
    #     let d = {'a': 1 , 'b': 2 , 'c': 3} # Error!
    #     let d = {'a' : 1, 'b' : 2, 'c' : 3} # Error!
    #}}}
enddef

def UselessConstructs() #{{{2
    let info = Popup_notification('==# → ==')
    :keepj keepp lockm %s/[!=][=~]\zs#//gce
    # What about the `?` family of comparison operators?{{{
    #
    #     ==?
    #     !=?
    #     =~?
    #     !~?
    #
    # We still need them in Vim9 script.
    #}}}
    popup_close(info[1])

    info = Popup_notification('s:func() → Func()')
    :keepj keepp lockm %s/\C\<s:\(\h\)\ze\w*(/\U\1/gce
    popup_close(info[1])
    # TODO: Try to remove `s:` in front of a variable name at the script level.
    # Inspect the stack of syntax items under the cursor.

    info = Popup_notification('v:true → true')
    :keepj keepp lockm %s/\C\<v:\ze\%(true\|false\)\>//gce
    popup_close(info[1])

    info = Popup_notification(':call → ∅')
    :keepj keepp lockm %s/\C\zs\<call\>\s\+\ze\S\+(//gce
    popup_close(info[1])

    info = Popup_notification('line continuations')
    # TODO: don't remove a leading backslash in a multiline autocmd or custom Ex command
    :keepj keepp lockm %s/^\s*\zs\\\s\=//ce
    popup_close(info[1])
enddef

def Misc() #{{{2
    # clear stack of location lists
    setloclist(0, [], 'f')

    let db = [#{
        pat: '^\C\s*def.*,\s*\zs\.\.\.\s*)',
        title: 'refactor ... from legacy function''s header',
        helptag: 'Vim9-refactoring-...',
    },
    #{
        pat: '\Ca:\d',
        title: 'refactor a:1, a:2, ...',
        helptag: 'Vim9-refactoring-a:123',
    },
    #{
        pat: '^\C\s*def\>\s\+\S\+(\s*\zs[^) ]',
        title: 'declare function arguments types',
        helptag: 'Vim9-function-arguments-types',
    },
    #{
        pat: '^\C\s*def\>\s\+\S\+(\%(\%(\<enddef\>\)\@!\_.\)\{-}\n\s*return\>\s\+\_.\{-}\nenddef',
        title: 'declare function return type',
        helptag: 'Vim9-function-return-type',
    },
    #{
        pat: '\C\<let\>\s',
        title: 'assignments',
        helptag: 'Vim9-assignments',
    },
    #{
        pat: '^\s*#\s*\zs"',
        title: 'commented legacy comment leaders',
        helptag: 'Vim9-commented-legacy-comment-leaders',
    },
    ]

    let cmd: string
    # TODO: For each location list, write a help tag documenting what should be refactored and how.{{{
    #
    # About `:let` assignments:
    #
    #    - we can't declare a variable multiple times
    #    - sometimes, we might need to declare a specific type
    #    - we might need to declare a variable outside a block, so that it's visible afterward
    #    - the unpack notation is disallowed for multiple declarations (it *is* allowed for assignments)
    #
    #         ✘
    #         let [a, b] = [1, 2]
    #
    #         ✔
    #         let a: number
    #         let b: number
    #         [a, b] = [1, 2]
    #
    # ---
    #
    # About commented legacy comment leaders.
    # Right now, we automatically replace this:
    #
    #     "    " ...
    #
    # Into this:
    #
    #     #    " ...
    #
    # Don't try to go further:
    #
    #     #    # ...
    #          ^
    #          ✘
    #}}}
    for entry in db
        cmd = getloclist(0)->empty() ? 'lvimgrepadd' : 'lvimgrep'
        # `:noa` suppresses an  autocmd from opening the qf window;  we need to stay
        # in the current window, for the next `:lvim` to be run in the right context
        exe 'noa sil! ' .. cmd .. ' /' .. entry.pat .. '/gj %'
        if !getloclist(0)->empty()
            setloclist(0, [], 'a', #{
                title: entry.title,
                context: entry.helptag,
            })
        endif
    endfor
enddef

def OpenLocationWindow() #{{{2
    while getloclist(0, {'size': 0}).size == 0
        # `sil!` in case there is no location list
        sil! lolder
        if getloclist(0, {'nr': 0}).nr == 1
            break
        endif
    endwhile
    sil! lwindow
    if &bt == 'quickfix'
        # install a  mapping which opens a  help page explaining what  should be
        # refactored and how
        nno <buffer><nowait><silent> g? :<c-u>exe 'h ' .. getloclist(0, {'context': 1}).context<cr>
    endif
    # print the whole stack of location lists so that we know that there is more
    # than what we can currently see
    lhi
enddef

