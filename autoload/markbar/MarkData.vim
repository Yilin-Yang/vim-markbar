let s:MarkData = {
    \ 'TYPE': 'MarkData',
    \ '_data': [],
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
function! markbar#MarkData#New(markstring) abort
    call markbar#ensure#IsString(a:markstring)
    let l:new = deepcopy(s:MarkData)
    let l:new._data = matchlist(
        \ a:markstring, '\(\S\+\)\s\+\(\S\+\)\s\+\(\S\+\)\s*\(.*\)')[1:3]
    if empty(l:new._data)
        throw 'markstring parsing failed for: ' . a:markstring
    endif
    return l:new
endfunction

" RETURNS:  (v:t_string)    The default name for a local mark.
" PARAM:    mark_data       (markbar#BasicMarkData)     The mark to name.
function! markbar#MarkData#DefaultMarkName(mark_data) abort
    call markbar#ensure#IsClass(a:mark_data, 'BasicMarkData')
    let l:mark = a:mark_data.mark
    let l:format = printf(
        \ '(l: %d, c: %d) ',
        \ a:mark_data.line,
        \ a:mark_data.column,
        \ ) . '%s'
    if l:mark ==# "'"
        return printf(l:format, 'Last Jump')
    elseif l:mark ==# '<'
        return printf(l:format, 'Selection Start')
    elseif l:mark ==# '>'
        return printf(l:format, 'Selection End')
    elseif l:mark ==# '"'
        return printf(l:format, 'Left Buffer')
    elseif l:mark ==# '^'
        return printf(l:format, 'Left Insert Mode')
    elseif l:mark ==# '.'
        return printf(l:format, 'Last Change')
    elseif l:mark ==# '['
        return printf(l:format, 'Change/Yank Start')
    elseif l:mark ==# ']'
        return printf(l:format, 'Change/Yank End')
    elseif l:mark ==# '('
        return printf(l:format, 'Sentence Start')
    elseif l:mark ==# ')'
        return printf(l:format, 'Sentence End')
    elseif l:mark ==# '{'
        return printf(l:format, 'Paragraph Start')
    elseif l:mark ==# '}'
        return printf(l:format, 'Paragraph End')
    endif
    return printf(
        \ 'l: %4d, c: %4d',
        \ a:mark_data.line,
        \ a:mark_data.column)
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

" RETURNS:  (v:t_string)    Name of the file in which this mark is found.
function! s:MarkData.getFilename() abort dict
    return bufname(markbar#helpers#BufferNo(l:self.getMarkChar()))
endfunction
