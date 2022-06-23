let s:MarkData = {
    \ 'TYPE': 'MarkData',
    \ '_mark_char': '',
    \ '_line_no': '',
    \ '_column_no': '',
    \ '_filepath': '',
    \ '_bufname': '',
    \ '_context': [],
    \ '_name': ''
\ }

" EFFECTS:  Create a MarkData object from a one-line 'markstring'.
" DETAILS:  MarkData holds information about a mark and the context where that
"           mark appears.
" PARAM:    markstring  (v:t_string)    The one-line markstring.
"
"           Shall be formatted as follows:
"               A     10    0   foo.txt
"               ^ mark
"                     ^ line no
"                           ^ col no
"                               ^ file/text
"
"           This is how the `marks` command prints output for a mark. See `:h
"           marks` for more details.
" PARAM:    bufname     (v:t_string)    Bufname or the buffer holding the
"                                       mark. Ignored when MarkData is a
"                                       global mark.
" PARAM:    filepath    (v:t_string)    Full filepath for the buffer holding
"                                       the mark. Ignored when MarkData is a
"                                       global mark.
function! markbar#MarkData#New(markstring, bufname, filepath) abort
    call markbar#ensure#IsString(a:markstring)
    call markbar#ensure#IsString(a:bufname)
    call markbar#ensure#IsString(a:filepath)
    let l:new = deepcopy(s:MarkData)

    let l:parsed_entries =
            \ matchlist(a:markstring,
                      \ '\(\S\+\)\s\+\(\S\+\)\s\+\(\S\+\)\s*\(.*\)')[1:3]
    if empty(l:parsed_entries)
        throw 'markstring parsing failed for: ' . a:markstring
    endif
    let [l:new._mark_char, l:new._line_no, l:new._column_no] =
            \ l:parsed_entries
    if markbar#helpers#IsGlobalMark(l:new._mark_char)
        " filepath and bufname will be looked up on every getFilename,
        " getBufname call
    else  " local mark
        let l:new._filepath = a:filepath
        let l:new._bufname = a:bufname
    endif
    return l:new
endfunction

" RETURNS:  (v:t_string)    Default name for a mark, or an empty string.
function! markbar#MarkData#getDefaultName() abort dict
    let l:mark = l:self.getMarkChar()
    if l:mark ==# "'"
        return 'Last Jump'
    elseif l:mark ==# '<'
        return 'Selection Start'
    elseif l:mark ==# '>'
        return 'Selection End'
    elseif l:mark ==# '"'
        return 'Left Buffer'
    elseif l:mark ==# '^'
        return 'Left Insert Mode'
    elseif l:mark ==# '.'
        return 'Last Change'
    elseif l:mark ==# '['
        return 'Change/Yank Start'
    elseif l:mark ==# ']'
        return 'Change/Yank End'
    elseif l:mark ==# '('
        return 'Sentence Start'
    elseif l:mark ==# ')'
        return 'Sentence End'
    elseif l:mark ==# '{'
        return 'Paragraph Start'
    elseif l:mark ==# '}'
        return 'Paragraph End'
    endif
    return ''
endfunction
let s:MarkData.getDefaultName = function('markbar#MarkData#getDefaultName')

function! markbar#MarkData#getMarkChar() abort dict
    return l:self._mark_char
endfunction
let s:MarkData.getMarkChar = function('markbar#MarkData#getMarkChar')

function! markbar#MarkData#getLineNo() abort dict
    return l:self._line_no
endfunction
let s:MarkData.getLineNo = function('markbar#MarkData#getLineNo')

function! markbar#MarkData#getColumnNo() abort dict
    return l:self._column_no
endfunction
let s:MarkData.getColumnNo = function('markbar#MarkData#getColumnNo')

" RETURNS:  (v:t_string)    User-provided name for this mark, or ''.
function! markbar#MarkData#getUserName() abort dict
    return l:self._name
endfunction
let s:MarkData.getUserName = function('markbar#MarkData#getUserName')

function! markbar#MarkData#getContext() abort dict
    return l:self._context
endfunction
let s:MarkData.getContext = function('markbar#MarkData#getContext')

function! markbar#MarkData#isGlobal() abort dict
    return markbar#helpers#IsGlobalMark(l:self.getMarkChar())
endfunction
let s:MarkData.isGlobal = function('markbar#MarkData#isGlobal')

" EFFECTS:  Set user-given name for this mark.
function! markbar#MarkData#setUserName(new_name) abort dict
    let l:self._name = a:new_name
endfunction
let s:MarkData.setUserName = function('markbar#MarkData#setUserName')

" EFFECTS:  Update the context for a particular mark.
" PARAM:    new_context (v:t_list)  List of strings, where each string is a
"                                   line of context from around the mark.
function! markbar#MarkData#setContext(new_context) abort dict
    let l:self._context = a:new_context
endfunction
let s:MarkData.setContext = function('markbar#MarkData#setContext')

" RETURNS:  (v:t_string)    |bufname()| of the buffer that contains this mark.
"                           When MarkData represents a global mark, this comes
"                           from a |bufname()| lookup.
function! markbar#MarkData#getBufname() abort dict
    if l:self.isGlobal()
        return bufname(markbar#helpers#BufferNo(l:self.getMarkChar()))
    else
        return l:self._bufname
    endif
endfunction
let s:MarkData.getBufname = function('markbar#MarkData#getBufname')

" RETURNS:  (v:t_string)    Full path to the file holding this mark.
"                           When MarkData represents a global mark, this comes
"                           from a lookup.
function! markbar#MarkData#getFilename() abort dict
    if l:self.isGlobal()
        let l:bufnr = markbar#helpers#BufferNo(l:self.getMarkChar())
        return expand(printf('#%s:p', l:bufnr))
    else
        return l:self._filepath
    endif
endfunction
let s:MarkData.getFilename = function('markbar#MarkData#getFilename')
