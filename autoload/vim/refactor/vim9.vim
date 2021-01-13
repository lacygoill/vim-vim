vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

import IsVim9 from 'lg.vim'
import Popup_notification from 'lg/popup.vim'

# Interface {{{1
def vim#refactor#vim9#main(lnum1: number, lnum2: number) #{{{2
    var view = winsaveview()

    # we might need to inspect the syntax under the cursor
    var syntax_was_on = exists('g:syntax_on')
    if !syntax_was_on
        syntax on
    endif
    # folding might interfere
    var folding_was_on = &l:fen
    setl nofen

    # Warning: Do *not* use `:silent` before a substitution command to which you pass the `c` flag.{{{
    #
    # You wouldn't see the prompt message on the command-line:
    #
    #     replace with X (y/n/a/q/l/^E/^Y)?
    #}}}

    var visual_marks = [getpos("'<"), getpos("'>")]
    setpos("'<", [0, lnum1, 0, 0])
    setpos("'>", [0, lnum2, 0, 0])

    # clear stack of location lists
    setloclist(0, [], 'f')

    # TODO: `list[a:b]` → `list[a : b]`
    # TODO: should we highlight each text which is to be modified and ask for the user's confirmation?
    # TODO: should we invoke `:RefDot`?
    # TODO: check that commands starting with a range are prefixed with a colon
    # (tricky to recognize a range; writing a command name in its full form might help)
    # TODO: refactor all eval strings into lambdas (faster)
    # TODO: Refactor dictionaries.{{{
    #
    # Since 8.2.2015 and 8.2.2017, we don't need `#` anymore.
    #
    #     #{key: 123}
    #     →
    #     {key: 123}
    #
    # If a key must be evaluated, you'll need to use square brackets:
    #
    #     {key: 123}
    #     →
    #     {[key]: 123}
    #}}}
    Vim9script()
    Comments()
    # Do *not* move `Fu2Def()` after `UselessConstructs()`.{{{
    #
    # The latter  calls `GetNewFunctionPrefix()` which assumes  that the headers
    # of functions have been refactored from `:fu` to `:def`.
    #}}}
    Fu2Def()
    Let2Var()

    ImportNoReinclusionGuard()
    RemoveInvalid()
    NoPublicVarDeclaration()
    NoScriptLocalVarDeclarationInDef()
    # `ProperWhitespace()` must be invoked *before* `UselessConstructs()`{{{
    #
    # The former might need to find `:call`.
    # And  the latter  might  perform  some wrong  refactorings  if all  useless
    # whitespace has  not been removed.  In  particular, it assumes that  – in a
    # function call –  there is no extra whitespace between  a function name and
    # the opening parenthesis.
    #}}}
    ProperWhitespace()
    # Keep `UselessConstructs()` at the end.{{{
    #
    # It populates a location list.  We  don't want the positions of the entries
    # in this loclist to become invalid by a later refactoring.
    #}}}
    UselessConstructs()
    Misc()

    if !syntax_was_on
        syntax off
    endif
    if folding_was_on
        setl fen
    endif
    setpos("'<", visual_marks[0])
    setpos("'>", visual_marks[1])
    winrestview(view)

    if getloclist(0, {nr: 0}).nr == 0
        return
    endif
    SortUniqLoclists()
    OpenLocationWindow()
enddef
#}}}1
# Core {{{1
def Vim9script() #{{{2
    if getline(1) !~ '^vim9\%[script]\>' && line("'<") == 1 && line("'>") == line('$')
        append(0, ['vim9 noclear', ''])
    endif
enddef

def Comments() #{{{2
    # `:h line-continuation-comment`
    sil keepj keepp lockm :*s/^\s*\zs"\\ /# /ge
    sil keepj keepp lockm :*s/"/\=GetNewCommentLeader()/ge
enddef

def GetNewCommentLeader(): string
    # a legacy comment leader must be highlighted as a comment
    if In('Comment')
        # but the character before must not
        && (!In('Comment', col('.') - 1)
            # unless there is only indentation before
            # (yes, the indentation before a `"` comment leader is also part of the comment)
            || getline('.')->matchstr('^.*\%' .. col('.') .. 'c') =~ '^\s*$')
        # also, leave a quote in a heredoc alone (everything is literal in there)
        && !In('LetHereDoc')
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
    sil keepj keepp lockm :*s/^\C\s*fu\%[nction]\(!\=\)\s\+.\{-}\zs\s*abort\>//e
    sil keepj keepp lockm :*s/^\C\s*\zsfu\%[nction]\(!\=\)\ze\s\+/def\1/e
    sil keepj keepp lockm :*s/^\C\s*\zsendf\%[unction]$/enddef/e
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

def Let2Var() #{{{2
    var info = Popup_notification('let name = 123 → var name = 123')
    sil keepj keepp lockm :*s/\C\<let\>/\=In('vimLet') ? 'var' : 'let'/ge
    popup_close(info[1])
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
        var pat = '\C\<if\>\s*.*\<\(g:[a-zA-Z0-9_#]*loaded[a-zA-Z0-9_#]*\).*'
            .. '\n\s*finish'
            .. '\nendif'
            .. '\nlet\s*\1\s*='
        exe 'sil! :0/' .. pat .. '/;+4 d_'
    endif
enddef

def RemoveInvalid() #{{{2
    # In some cases, we should not remove `a:`.{{{
    #
    #     def Func(arg: number)
    #         var arg = a:arg + 1
    #     enddef
    #
    # Rationale:  This might lead to confusing  errors later, for which you'll –
    # needlessly – spend a lot of time to find a fix.
    #
    # Indeed, in such cases, you can't just remove `a:`; you also need to create
    # a new variable; otherwise:
    #
    #     E1006: arg is used as an argument
    #
    # Sure, you'll quickly find a fix for this error.
    # But  in the  rest  of the  original  function, there  might  have been  an
    # arbitrary mix of `a:arg` and `arg`.  If `a:` has been removed, you've lost
    # information which might not be obvious to get back.
    #}}}
    # TODO: Should we also populate yet another loclist for such cases?
    # FIXME: Sometimes, it still doesn't prevent `a:` from being removed, while it should:{{{
    #
    #     fu Func(arg)
    #         let arg = 123
    #         if arg == a:arg
    #             " ...
    #         endif
    #     endfu
    #
    #     →
    #
    #     def Func(arg)
    #         var arg = 123
    #         if arg == arg
    #             # ...
    #         endif
    #     enddef
    #
    # Notice this line:
    #
    #         if arg == arg
    #
    # It's obviously wrong.
    #
    # Before  removing  `a:`, we  should  check  whether  the variable  name  is
    # declared anywhere else in the function.  This implies we should get a list
    # of all  declared variable  names, which  is tricky  because of  the unpack
    # notation.
    #}}}
    try
        keepj keepp lockm :*s/\C\<var\%(\s\+\)\@>[^=]*\(\w\+\).*=.*\zsa\ze:\1\>/\="\x01"/ge
    # E363: pattern uses more memory than 'maxmempattern'
    catch /^Vim\%((\a\+)\)\=:E363:/
        echohl ErrorMsg
        echom v:exception
        echohl NONE
    endtry
    var info = Popup_notification('a:funcarg → funcarg')
    keepj keepp lockm :*s/\C\<a:\ze\D//gce
    keepj keepp lockm :*s/\%x01/a/ge
    popup_close(info[1])

    info = Popup_notification('l:funcvar → funcvar')
    keepj keepp lockm :*s/\C&\@1<!\<l:\ze\S//gce
    popup_close(info[1])

    info = Popup_notification('is# → ==')
    keepj keepp lockm :*s/\C\<is#/==/gce
    keepj keepp lockm :*s/\C\<isnot#/!=/gce
    keepj keepp lockm :*s/\C\<is?/==?/gce
    keepj keepp lockm :*s/\C\<isnot?/!=?/gce
    popup_close(info[1])
enddef

def NoPublicVarDeclaration() #{{{2
    # E1016: Cannot declare a global variable: g:var
    # You can declare a script-local variable at  the script level, but not in a
    # `:def` function.
    var info = Popup_notification('var g:var = 123 → g:var = 123')
    keepj keepp lockm :*s/\C\zs\<var\s\+\ze[bgtvw]:\S//gce
    popup_close(info[1])

    # Cannot declare environment variable (`E1016`), nor Vim option (`E1052`)
    info = Popup_notification('var $ENVVAR = 123 → $ENVVAR = 123')
    keepj keepp lockm :*s/\C\zs\<var\s\+\ze[$&]\S//gce
    popup_close(info[1])
enddef

def NoScriptLocalVarDeclarationInDef() #{{{2
    var lines =<< trim END
        # in `:def` function
        var s:var = 123
        →
        s:var = 123
    END
    var info = Popup_notification(lines)
    keepj keepp lockm sil :*s/\C\<\%(var\|const\=\)\s\+\zes:\S/\=MaybeRemoveDeclaration()/gce
    popup_close(info[1])
enddef

def MaybeRemoveDeclaration(): string
    if In('vimFuncBody')
        return ''
    endif
    return submatch(0)
enddef

def ProperWhitespace() #{{{2
    var lines =<< trim END
        {_,v -> ...}
        →
        {_, v -> ...}
    END
    var info = Popup_notification(lines)
    keepj keepp lockm :*s/{\s*[^ ,]\+,\zs\ze[^ ,]\+\s*->/ /gce
    popup_close(info[1])

    # TODO: What about  assignments which  don't use `:var`?  (global variables,
    # environment variables, Vim options, ...)
    info = Popup_notification('var name= 234    # Error!')
    keepj keepp lockm :*s:\C\<var\s\+.*\S\zs\ze[-+*/%.!='"<>\\@]\@1<!=: :gce
    popup_close(info[1])

    info = Popup_notification('var name =234    # Error!')
    keepj keepp lockm :*s/\C\<var\s\+.*>\@1<!=[\\~=<]\@!\zs\ze\S\%(.*\i\)/ /gce
    popup_close(info[1])

    info = Popup_notification('var name = 234# Error!')
    # TODO: In the future, `#{}` might be parsed as a comment.
    # If that happens, consider removing `#` from the regex used in the pattern field.
    keepj keepp lockm :*s/\C\<var\s\+.*=.*\S\~\@1<!\zs\ze#{\@!\s\+/ /gce
    #                                                         ^--^{{{
    #                                                         technically, we should remove this, but:
    #                                                         - in practice, it probably won't matter
    #                                                         - it should remove false positives
    #                                                         (e.g. # inside a string)
    #}}}
    popup_close(info[1])

    info = Popup_notification('call Func (arg) # Error!')
    keepj keepp lockm :*s/\C\<call\s\+[a-zA-Z_:]\+\zs\s\+\ze(//gce
    popup_close(info[1])

    # Commented because it gives too many false positives.
    #
    #     info = Popup_notification("{'a' : 1} # Error!")
    #     keepj keepp lockm :*s/\s\+\ze:/\=RemoveOnlyInDictionary()/gce
    #     popup_close(info[1])

    # TODO: check white space is correctly used in other contexts{{{
    #
    #     var x = 1+2 # Error! (tricky to find; many possible operators, and many types of operands)
    #     var l = [1 , 2 , 3] # Error!
    #     var d = {'a': 1 , 'b': 2 , 'c': 3} # Error!
    #     var d = {'a' : 1, 'b' : 2, 'c' : 3} # Error!
    #
    #     if index(win_in_this_tab , 1) != -1
    #                             ^
    #                             ✘
    #}}}
enddef

def RemoveOnlyInDictionary(): string
    if !In('vimOperParen')
        return submatch(0)
    else
        return ''
    endif
enddef

def UselessConstructs() #{{{2
    # TODO: The code repeats itself too much.{{{
    #
    #     info = Popup_notification('...')
    #     keepj keepp lockm :*s/.../.../...
    #     popup_close(info[1])
    #
    # Try to refactor each of these blocks into a single function call.
    #}}}
    var info = Popup_notification('==# → ==')
    keepj keepp lockm :*s/[!=][=~]\zs#//gce
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

    info = Popup_notification('v:true → true')
    keepj keepp lockm :*s/\C\<v:\ze\%(true\|false\)\>//gce
    popup_close(info[1])

    info = Popup_notification(':call → ∅')
    var pat = printf('\%(^\%(\s*%s\>\)\@!.*\)\@<=\C\<call\>\s\+\ze\S\+(', MAPCMDPAT)
    exe 'keepj keepp lockm :*s/' .. pat .. '//gce'
    popup_close(info[1])

    info = Popup_notification('line continuations')
    # TODO: don't remove a leading backslash in a multiline autocmd or custom Ex command
    keepj keepp lockm :*s/^\s*\zs\\\s\=//ce
    popup_close(info[1])

    # TODO: Try to remove `s:` in front of a variable name at the script level.
    # Inspect the stack of syntax items under the cursor.

    # TODO: Eliminate `function()`:{{{
    #
    #     def Func()
    #         var Funcref = function('s:foo')
    #     enddef
    #
    #     fu s:foo()
    #         " ...
    #     endfu
    #
    #     →
    #
    #     def Func()
    #         var Funcref = Foo
    #     enddef
    #
    #     fu s:Foo()
    #         " ...
    #     endfu
    #
    # This is a bit tricky, because we  might need to capitalize a function name
    # outside the function which we're  refactoring.  If we invoke `:RefVim9` on
    # a function (!= whole script), is it ok to refactor sth outside of it?
    # If not, don't do anything; just add `function(...)` as an entry into a new
    # loclist.
    #}}}

    if getline(1) =~ '^vim9\%[script]\>'
        info = Popup_notification('s:var → var')
        # We need `\%#=1` to prevent `\@>` from causing `\ze` to be ignored.
        keepj keepp lockm :*s/\%#=1\C\%(\<function(\s*['"]\s*\)\@<!\<s:\ze\h\%(\w*\)\@>(\@!//gce
        popup_close(info[1])
    endif

    # Keep this at the very end!{{{
    #
    # `GetNewFunctionPrefix()` populates a location list with names of functions
    # which need  to be capitalized.   But the previous refactorings  might make
    # the column  positions of entries  in the loclist invalid  (especially true
    # after the removal  of `:call`).  We want these positions  to stay the same
    # for when we review the location lists later.
    #}}}
    info = Popup_notification('s:func() → Func()')
    # let's make sure to reset `funclist` across several invocations of `:RefVim9`
    funclist = []
    keepj keepp lockm :*s/\C\<s:\(\h\)\ze\(\w*\)(/\=GetNewFunctionPrefix()/gce
    # Don't try to do this right from `GetNewFunctionPrefix()`.{{{
    #
    # We need to wait for the substitutions to have been performed.
    # Otherwise,  we  might  get  qf  entries for  which  there  is  nothing  to
    # capitalize, which – in practice – is very confusing.
    #}}}
    for funcname in funclist
        # the function  name has been capitalized  in its header; we'll  need to
        # capitalize it everywhere in the file (i.e. at the call sites)
        # We use `:lvimgrepadd` instead of `:lvim` to not create too many loclists.{{{
        #
        # Remember that the stack can only contain 10 lists.
        # Beyond that, Vim overwrites the oldest loclists.
        # We don't want to lose any loclist.
        #}}}
        exe 'sil! lvimgrepadd /\C\<' .. funcname .. '\>(/gj %'
        setloclist(0, [], 'a', {
            title: 'capitalize function name at call sites',
            context: 'Vim9-capitalize-function-names',
            })
    endfor
    popup_close(info[1])
enddef

var funclist: list<string>

def GetNewFunctionPrefix(): string
    var funcname = submatch(1) .. submatch(2)
    if submatch(1) =~ '[[:lower:]]'
        funclist += [funcname]
    endif

    var pfx = submatch(1)->toupper()
    # can not drop `s:` in the header of a Vim9 function in a legacy script
    if getline(1) !~ '^vim9\%[script]\>' && getline('.') =~ '^\s*def\>'
        return 's:' .. pfx
    # can drop `s:` in the Vim9 context
    elseif IsVim9()
        return pfx
    # can not drop `s:` otherwise
    else
        return 's:' .. pfx
    endif
enddef

const MAPCMDS =<< trim END
    map
    nm\%[ap]
    vm\%[ap]
    xm\%[ap]
    smap
    om\%[ap]
    map!
    im\%[ap]
    lm\%[ap]
    cm\%[ap]
    tma\%[p]
    no\%[remap]
    nn\%[oremap]
    vn\%[oremap]
    xn\%[oremap]
    snor\%[emap]
    ono\%[remap]
    no\%[remap]!
    ino\%[remap]
    ln\%[oremap]
    cno\%[remap]
    tno\%[remap]
END
const MAPCMDPAT = '\%(' .. join(MAPCMDS, '\|') .. '\)'

def Misc() #{{{2
    # Warning: Do not add too many loclists.{{{
    #
    # The stack's size is limited to 10.  From `:h quickfix-ID`:
    #
    #    > There is also a quickfix list  number which may change whenever more
    #    > than **ten** lists are added to a quickfix stack.
    #
    # From `:h quickfix-error-lists`:
    #
    #    > Actually the ten  last used lists are remembered.   When starting a
    #    > new list, the  previous ones are automatically  kept.  Two commands
    #    > can be used to access older error
    #
    # If the  stack gets  full, the  next loclist  that we  try to  add will
    # replace the first one.  IOW, we might lose valuable info.
    #
    # ---
    #
    # Remember that in `GetNewFunctionPrefix()`, we already add 1 loclist on the
    # stack.
    #}}}
    var db = [{
        pat: '^\C\s*def.*,\s*\zs\.\.\.\s*)',
        title: 'refactor ... from legacy function''s header',
        helptag: 'Vim9-refactoring-...',
    },
    {
        pat: '\Ca:\d',
        title: 'refactor a:1, a:2, ...',
        helptag: 'Vim9-refactoring-a:123',
    },
    {
        pat: '^\C\s*def\>!\=\s\+\S\+(\s*\zs[^) ]',
        title: 'declare function arguments types',
        helptag: 'Vim9-function-arguments-types',
    },
    {
        pat: FUNCRETPAT,
        title: 'declare function return type',
        helptag: 'Vim9-function-return-type',
    },
    {
        # E1003: Missing return value
        pat: MISSINGRETPAT,
        title: 'return missing value',
        helptag: 'Vim9-function-return-missing-value',
    },
    {
        pat: '\C\<var\>\s\+\(\S\+\)\s\%(\%(\n\s*enddef\s*\n\)\@!\_.\)*\zs\<var\>\s\+\1\s',
        title: 'assignments',
        helptag: 'Vim9-assignments',
    },
    {
        pat: '\C\<var\>\s\+\[',
        title: 'cannot use list for declaration',
        helptag: 'Vim9-cannot-use-list-for-declaration',
    },
    {
        pat: '^\s*#\s*\zs"',
        title: 'commented legacy comment leaders',
        helptag: 'Vim9-commented-legacy-comment-leaders',
    },
    ]

    var cmd: string
    var pat: string
    var anchor = '\%>' .. (line("'<") - 1) .. 'l\%<' .. (line("'>") + 1) .. 'l'
    # TODO: For each location list, write a help tag documenting what should be refactored and how.{{{
    #
    # About `:var` assignments:
    #
    #    - we can't declare a variable multiple times
    #    - sometimes, we might need to declare a specific type
    #    - we might need to declare a variable outside a block, so that it's visible afterward
    #    - the unpack notation is disallowed for multiple declarations (it *is* allowed for assignments)
    #
    #         ✘
    #         var [a, b] = [1, 2]
    #
    #         ✔
    #         var a: number
    #         var b: number
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
        pat = anchor .. entry.pat .. anchor
        # `:noa` suppresses an  autocmd from opening the qf window;  we need to stay
        # in the current window, for the next `:lvim` to be run in the right context
        exe 'sil! lvim /' .. pat .. '/gj %'
        setloclist(0, [], 'a', {
            title: entry.title,
            context: entry.helptag,
        })
    endfor
enddef

# a `return` statement in a `:def` function which returns some value
# (not a simple `return` statement used to end a function's execution)
const FUNCRETPAT = '^\C\s*def\>!\=\s\+\S\+('
    .. '\%(\%(\<enddef\>\)\@!\_.\)\{-}'
    .. '\%(^\s*#\s.*\)\@<!\<return\>\s\+[ \n|]\@!'
    .. '\_.\{-}\n\s*enddef\s*\%(\%(\n\|\%$\)\)\@='

# a `return` statement in a `:def` function which returns some value
# followed by a `return` statement which does not return any value
const MISSINGRETPAT = '^\C\s*def\>!\=\s\+\S\+('
    .. '\%(\%(\<enddef\>\)\@!\_.\)\{-}'
    .. '\%(^\s*#\s.*\)\@<!\<return\>\s\+[ \n|]\@!'
    .. '\%(\%(\<enddef\>\)\@!\_.\)\{-}'
    .. '\C\<return\>\s*[\n|]\@='
    .. '\_.\{-}\n\s*enddef\s*\%(\n\|\%$\)'
    # or a  `return` statement in  a `:def` function  which does not  return any
    # value followed by a `return` statement which returns some value
    .. '\|^\C\s*def\>!\=\s\+\S\+('
    .. '\%(\%(\<enddef\>\)\@!\_.\)\{-}'
    .. '\C\<return\>\s*[\n|]\@='
    .. '\%(\%(\<enddef\>\)\@!\_.\)\{-}'
    .. '\%(^\s*#\s.*\)\@<!\<return\>\s\+[ \n|]\@!'
    .. '\_.\{-}\n\s*enddef\s*\%(\n\|\%$\)'

def SortUniqLoclists() #{{{2
    var stack: list<dict<any>>
    var info: dict<any>
    var loclistsNumbers = range(1, getloclist(0, {nr: '$'}).nr)
    for nr in loclistsNumbers
        info = getloclist(0, {nr: nr, items: true, title: true})
        if info.items == []
            continue
        endif
        # sort the entries in the location list according to their location
        sort(info.items, (i, j) =>
            i.lnum > j.lnum || i.lnum == j.lnum && i.col > j.col
                ? 1
                : -1
            )
        # We don't want redundant entries in the location lists.{{{
        #
        # That can happen, for example, when `GetNewFunctionPrefix()` is invoked
        # several  times for  the same  function, because  the latter  is called
        # multiple times.
        #}}}
        stack += [{items: uniq(info.items), title: info.title}]
    endfor

    # Make sure no empty loclist is in the stack.
    setloclist(0, [], 'f')
    for nr in len(stack)->range()
        setloclist(0, [], ' ', {
            items: stack[nr].items,
            title: stack[nr].title,
            })
    endfor
enddef
def OpenLocationWindow() #{{{2
    # bail out if the stack is empty
    if getloclist(0, {nr: '$'}).nr == 0
        return
    endif
    :1lhi
    lwindow
    if &bt == 'quickfix'
        # install a  mapping which opens a  help page explaining what  should be
        # refactored and how
        nno <buffer><nowait> g? <cmd>exe 'h ' .. getloclist(0, #{context: 1}).context<cr>
    endif
    # print the whole stack of location lists so that we know that there is more
    # than what we can currently see
    lhi
enddef

#}}}1
# Utilities {{{1
def In(syngroup: string, col = col('.')): bool #{{{2
    return synstack('.', col)
        ->mapnew((_, v) => synIDattr(v, 'name'))
        ->match('\c' .. syngroup) != -1
enddef

