" EFFECTS:  Default-initialize a MarkData object.
" DETAILS:  MarkData is a struct that holds information about a particular
"           mark, as well as the context in which that mark appears. It
"           provides basic observer functions and a convenience constructor.
function! markbar#MarkData#new() abort
    let l:new = {
        \ 'TYPE': 'MarkData',
        \ '_data': [],
        \ '_context': [],
        \ '_name': ''
    \ }
    let l:new.getColumnNo = function('markbar#MarkData#getColumnNo')
    let l:new.getLineNo   = function('markbar#MarkData#getLineNo')
    let l:new.getMark     = function('markbar#MarkData#getMark')
    let l:new.getName     = function('markbar#MarkData#getName')
    let l:new.getContext  = function('markbar#MarkData#getContext')
    let l:new.getMarkLineInContext =
            \ function('markbar#MarkData#getMarkLineInContext')
    let l:new.isGlobal    = function('markbar#MarkData#isGlobal')
    let l:new.setName     = function('markbar#MarkData#setName')
    let l:new.setContext  = function('markbar#MarkData#setContext')
    return l:new
endfunction

" EFFECTS:  Create a MarkData object from a one-line 'markstring'.
" PARAM:    markstring  (v:t_string)    The one-line markstring.
"
"           Shall be formatted as follows:
"               A     10    0   foo.txt
"               ^ mark
"                     ^ line no
"                           ^ col no
"                               ^ file/text
"           This is the manner in which the `marks` command prints output for
"           a particular mark. See `:h marks` for more details.
function! markbar#MarkData#fromMarkString(markstring) abort
    if type(a:markstring) !=# v:t_string
        throw '(markbar#MarkData#FromMarkString) Bad argument type for: ' . a:markstring
    endif
    let l:new_markdata = markbar#MarkData#new()
    let l:new_markdata._data = matchlist(
        \ a:markstring,
        \ '\(\S\+\)\s\+\(\S\+\)\s\+\(\S\+\)\s*\(.*\)'
    \ )[1:3]
    if empty(l:new_markdata._data)
        throw '(markbar#MarkData) markstring parsing failed for: ' . a:markstring
    endif
    return l:new_markdata
endfunction

function! markbar#MarkData#AssertIsMarkData(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'MarkData'
        throw '(markbar#MarkData) Object is not of type MarkData: ' . a:object
    endif
endfunction

" RETURNS:  (v:t_string)    The default name for a local mark.
" PARAM:    mark_data       (markbar#BasicMarkData)     The mark to name.
function! markbar#MarkData#DefaultMarkName(mark_data) abort
    call markbar#BasicMarkData#AssertIsBasicMarkData(a:mark_data)
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

function! markbar#MarkData#getMark() abort dict
    call markbar#MarkData#AssertIsMarkData(l:self)
    return l:self._data[0]
endfunction

function! markbar#MarkData#getLineNo() abort dict
    call markbar#MarkData#AssertIsMarkData(l:self)
    return l:self._data[1]
endfunction

function! markbar#MarkData#getColumnNo() abort dict
    call markbar#MarkData#AssertIsMarkData(l:self)
    return l:self._data[2]
endfunction

function! markbar#MarkData#getName() abort dict
    call markbar#MarkData#AssertIsMarkData(l:self)
    return l:self._name
endfunction

function! markbar#MarkData#getContext() abort dict
    call markbar#MarkData#AssertIsMarkData(l:self)
    return l:self._context
endfunction

function! markbar#MarkData#getMarkLineInContext() abort dict
    call markbar#MarkData#AssertIsMarkData(l:self)
    let l:context_len = len(l:self._context)
    if !l:context_len | return l:context_len | endif

    let l:odd_num_lines = l:context_len % 2
    " bump up by one if the context has even length
    return l:context_len / 2 - ((l:odd_num_lines) ? 0 : 1)
endfunction

function! markbar#MarkData#isGlobal() abort dict
    call markbar#MarkData#AssertIsMarkData(l:self)
    return markbar#helpers#IsGlobalMark( l:self.getMark() )
endfunction

function! markbar#MarkData#setName(new_name) abort dict
    call markbar#MarkData#AssertIsMarkData(l:self)
    let l:self._name = a:new_name
endfunction

" EFFECTS:  Update the context for a particular mark.
" PARAM:    new_context (v:t_list)  List of strings, where each string is a
"                                   line of context from around the mark.
"                                   The string at index `len(new_context) / 2`
"                                   should be the line that contains the mark.
function! markbar#MarkData#setContext(new_context) abort dict
    call markbar#MarkData#AssertIsMarkData(l:self)
    let l:self._context = a:new_context
endfunction
