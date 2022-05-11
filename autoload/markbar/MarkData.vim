let s:MarkData = {
    \ 'TYPE': 'MarkData',
    \ '_data': [],
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
" PARAM:    bufname     (v:t_string)    Name of the buffer holding the mark.
"                                       Ignored when MarkData is a global mark.
function! markbar#MarkData#New(markstring, bufname) abort
    call markbar#ensure#IsString(a:markstring)
    call markbar#ensure#IsString(a:bufname)
    let l:new = deepcopy(s:MarkData)
    let l:new._data = matchlist(
        \ a:markstring, '\(\S\+\)\s\+\(\S\+\)\s\+\(\S\+\)\s*\(.*\)')[1:3]
    if empty(l:new._data)
        throw 'markstring parsing failed for: ' . a:markstring
    endif
    if !l:new.isGlobal()
        let l:new._bufname = a:bufname
    endif
    return l:new
endfunction

" RETURNS:  (v:t_string)    Default name for a 'punctuation' mark, or an empty
"                           string.
function! markbar#MarkData#DefaultMarkName(mark_data) abort
    call markbar#ensure#IsClass(a:mark_data, 'BasicMarkData')
    let l:mark = a:mark_data.mark
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

function! s:MarkData.getMarkChar() abort dict
    return l:self._data[0]
endfunction

function! s:MarkData.getLineNo() abort dict
    return l:self._data[1]
endfunction

function! s:MarkData.getColumnNo() abort dict
    return l:self._data[2]
endfunction

function! s:MarkData.getName() abort dict
    return l:self._name
endfunction

function! s:MarkData.getContext() abort dict
    return l:self._context
endfunction

function! s:MarkData.isGlobal() abort dict
    return markbar#helpers#IsGlobalMark(l:self.getMarkChar())
endfunction

function! s:MarkData.setName(new_name) abort dict
    let l:self._name = a:new_name
endfunction

" EFFECTS:  Update the context for a particular mark.
" PARAM:    new_context (v:t_list)  List of strings, where each string is a
"                                   line of context from around the mark.
function! s:MarkData.setContext(new_context) abort dict
    let l:self._context = a:new_context
endfunction

" RETURNS:  (v:t_string)    Name of the buffer or file holding this mark.
"                           When MarkData represents a global mark, this comes
"                           from a |bufname()| call; otherwise, the bufname
"                           stored at construction is returned.
function! s:MarkData.getFilename() abort dict
    if l:self.isGlobal()
        return bufname(markbar#helpers#BufferNo(l:self.getMarkChar()))
    endif
    return l:self._bufname
endfunction
