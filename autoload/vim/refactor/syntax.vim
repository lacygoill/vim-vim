vim9script noclear

# Purpose:{{{
#
# In Vim syntax files, some `:syntax` commands can be very long.
# We break them on multiple lines.
# But we might need  to edit them to include/remove/rename the  name of a syntax
# group.  If so, we  want to be able to quickly "reflow" the  lines so that they
# don't go beyond a certain length.
#
# For example, refactor sth like this:
#
#     syn cluster vim9AugroupList contains=
#         \@vim9DataTypeList,vim9Address,vim9Augroup,vim9AutoCmd,vim9BacktickExpansion
#         \,vim9BacktickExpansionVimExpr,vim9Bool,vim9BuiltinFuncName,vim9CallFuncName
#         \,vim9CmplxRepeat,vim9Comment,vim9Continue,vim9CtrlChar,vim9Declare,vim9Dict
#         \,vim9EnvVar,vim9Execute,vim9Filter,vim9FunctionError,vim9HereDoc
#         \,vim9IsCommand,vim9LegacyFunction,vim9Map,vim9Mark,vim9NotFunc,vim9Notation
#         \,vim9Number,vim9Oper,vim9OperParen,vim9MayBeOptionScoped,vim9Region,vim9Register
#         \,vim9Set,vim9SpecFile,vim9String,vim9Subst,vim9SynLine,vim9UserCommand
#         \,vim9UserFunctionHeader
#
# Into this:
#
#     syn cluster vim9AugroupList contains=
#         \@vim9DataTypeList,vim9Address,vim9Augroup,vim9AutoCmd,vim9BacktickExpansion
#         \,vim9BacktickExpansionVimExpr,vim9Bool,vim9BuiltinFuncName,vim9CallFuncName
#         \,vim9CmplxRepeat,vim9Comment,vim9Continue,vim9CtrlChar,vim9Declare,vim9Dict
#         \,vim9EnvVar,vim9Execute,vim9Filter,vim9FunctionError,vim9HereDoc
#         \,vim9IsCommand,vim9LegacyFunction,vim9Map,vim9Mark,vim9MayBeOptionScoped
#         \,vim9NotFunc,vim9Notation,vim9Number,vim9Oper,vim9OperParen,vim9Region
#         \,vim9Register,vim9Set,vim9SpecFile,vim9String,vim9Subst,vim9SynLine
#         \,vim9UserCommand,vim9UserFunctionHeader
#
# And this:
#
#     syn match vim9CmdSep /[:|]\+/
#         \ skipwhite
#         \ nextgroup=
#         \vim9Address,vim9AutoCmd,vim9DataType,vim9Echo,vim9ExtCmd,vim9Filter
#         \,vim9IsCommand,vim9Declare,vim9Map,vim9Mark,vim9Set,vim9Syntax
#         \,vim9UserCommand
#
# Into this:
#
#     syn match vim9CmdSep /[:|]\+/
#         \ skipwhite
#         \ nextgroup=
#         \vim9Address,vim9AutoCmd,vim9DataType,vim9Declare,vim9Echo,vim9ExtCmd
#         \,vim9Filter,vim9IsCommand,vim9Map,vim9Mark,vim9Set,vim9Syntax
#         \,vim9UserCommand
#}}}

const MAXLENGTH: number = 80

def vim#refactor#syntax#reflow()
    var lnum1: number = search('^[^ \t\\]\|^\s*\\\s', 'bncW')
    var lnum2: number = search('^\\\|\n\n', 'ncW')

    if lnum1 == -1
    || lnum2 == -1
    || lnum1 == lnum2
        Error('cannot find block of continuation lines to reflow')
        return
    endif

    # grab the lines which needs to be reflowed
    var lines = getline(lnum1 + 1, lnum2)
    if lines->match('^\%(\s*\\\S\)\@!') >= 0
        Error('cannot find block of continuation lines to reflow')
        return
    endif

    # split and sort the lines
    var sorted: list<string> = lines
        ->map((_, v: string): string => v->substitute('^\s*\\', '', ''))
        ->join('')
        ->split(',')
        ->sort()
        ->uniq()

    # reflow the lines
    var indent: string = repeat(' ', &l:shiftwidth) .. '\'
    var reflowed: list<string> = [indent]
    while !sorted->empty()
        while reflowed[-1]->strcharlen() <= MAXLENGTH
            # don't add a comma at the start of the very first line
            var comma: string = reflowed->len() == 1
                && reflowed[0] == indent
                # make sure the previous line  ends with an assignment operator;
                # otherwise, we probably do need a comma
                && getline(lnum1)[-1] == '='
                    ? '' : ','
            # make sure  there is enough  room on  the current reflowed  line to
            # append a new token
            if (reflowed[-1] .. comma .. sorted[0])->strcharlen() <= MAXLENGTH
                # append token  (presumably a syntax group/cluster  name) to the
                # reflowed line
                reflowed[-1] ..= comma .. sorted[0]
                sorted->remove(0)
                if sorted->empty()
                    break
                endif
            # not enough room
            else
                # start a new reflowed line
                reflowed->add(indent)
            endif
        endwhile
    endwhile

    # replace the lines
    exe ':' .. (lnum1 + 1) .. ',' .. lnum2 .. 'd _'
    reflowed->append(lnum1)

    # make sure the cursor is at the start of the refactored text
    exe 'norm! ' .. (lnum1 + 1) .. 'G_'
enddef

def Error(msg: string)
    echohl ErrorMsg
    echom msg
    echohl NONE
enddef

