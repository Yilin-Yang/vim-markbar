" EFFECTS:  Default-initialize a BufferCache object.
" DETAILS:  BufferCache stores marks and contexts for a particular buffer.
" PARAM:    buffer_no   (v:t_number)
function! markbar#BufferCache#new(...) abort
    let a:buffer_no = get(a:, 1, -1)
    let l:new = {
        \ 'TYPE': 'BufferCache',
        \ 'marks_dict': {},
        \ '_buffer_no': a:buffer_no,
    \ }
    let l:new['isGlobal']       = function('markbar#BufferCache#isGlobal')
    let l:new['getMark']        = function('markbar#BufferCache#getMark')
    let l:new['updateCache']    = function('markbar#BufferCache#updateCache')
    let l:new['updateContexts'] = function('markbar#BufferCache#updateContexts')
    return l:new
endfunction

function! markbar#BufferCache#AssertIsBufferCache(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'BufferCache'
        throw '(markbar#BufferCache) Object is not of type BufferCache: ' . a:object
    endif
    if a:object['_buffer_no'] <# 0
        throw "(markbar#BufferCache) Given BufferCache hasn't been initialized: " . a:object
    endif
endfunction

" RETURNS:  (markbar#MarkData)  The MarkData corresponding to the requested mark.
function! markbar#BufferCache#getMark(mark) abort dict
    call markbar#BufferCache#AssertIsBufferCache(l:self)
    let l:is_quote = a:mark ==# "'" || a:mark ==# '`'
    let l:mark = (l:is_quote) ? "'" : a:mark
    try
        let l:md = l:self['marks_dict'][l:mark]
    catch /E716/ " Key not present in dictionary
        throw '(markbar#BufferCache) Requested mark not found in cache: ' . a:mark
    endtry
    return l:md
endfunction

" EFFECTS:  Repopulate the internal marks database of this BufferCache with
"           the given marks.
" PARAM:    marks_output    (v:t_string)    The 'raw' output of `:marks`.
function! markbar#BufferCache#updateCache(marks_output) abort dict
    call markbar#BufferCache#AssertIsBufferCache(l:self)
    if type(a:marks_output) !=# v:t_string
        throw '(markbar#BufferCache#updateCache) Bad argument type for: ' . a:marks_output
    endif
    let l:trimmed = markbar#textmanip#TrimMarksHeader(a:marks_output)
    let l:markstrings = split(l:trimmed, '\r\{0,1}\n') " split on linebreaks
    let l:new_marks_dict = {}
    let l:i = len(l:markstrings)
    while l:i
        let l:i -= 1
        try
            let l:markdata = markbar#MarkData#fromMarkString(l:markstrings[l:i])
            let l:new_marks_dict[ l:markdata.getMark() ] =
                \ l:markdata
        catch /^(markbar#MarkData).*markstring parsing failed/
            " drop this markdata
        endtry
    endwhile

    " copy over existing mark names
    let l:old_dict = l:self['marks_dict']
    for l:mark in keys(l:old_dict)
        if !has_key(l:new_marks_dict, l:mark) | continue | endif
        call l:new_marks_dict[l:mark].setName(
            \ l:old_dict[l:mark].getName()
        \ )
    endfor

    let l:self['marks_dict'] = l:new_marks_dict
endfunction

" EFFECTS:  - Retrieve new contexts for the marks held in this buffer cache.
"           - Clears cached mark contexts for marks believed to no longer exist.
"           - Tries to fetch updated contexts for all marks in the given buffer.
" PARAM:    buffer_no   (v:t_number)    The number of the buffer to check.
" PARAM:    num_lines   (v:t_number)    The total number of lines of context
"                                       to retrieve.
function! markbar#BufferCache#updateContexts(num_lines) abort dict
    call markbar#BufferCache#AssertIsBufferCache(l:self)

    let l:marks_database = l:self['marks_dict']

    " remove orphaned contexts
    " for l:mark in keys(l:marks_to_contexts)
    "     if !has_key(l:marks_database, l:mark)
    "         " mark not found in updated marks database
    "         call remove(l:marks_to_contexts, l:mark)
    "     endif
    " endfor

    " fetch updated mark contexts
    let l:i = 0
    let l:using_global_marks = l:self.isGlobal()
    let l:buffer_no = l:self['_buffer_no']

    for l:mark in keys(l:marks_database)
        let l:mark_data = l:marks_database[l:mark]
        let l:line_no = l:mark_data.getLineNo()

        " if these are global marks, perform file lookup for each mark
        if l:using_global_marks
            let l:buffer_no = markbar#helpers#BufferNo(l:mark)
        endif

        let l:context = markbar#helpers#FetchContext(
            \ l:buffer_no,
            \ l:line_no,
            \ a:num_lines
        \ )
        let l:mark_data['_context'] = l:context
    endfor
endfunction

function! markbar#BufferCache#isGlobal() abort dict
    call markbar#BufferCache#AssertIsBufferCache(l:self)
    return l:self['_buffer_no'] ==# markbar#constants#GLOBAL_MARKS()
endfunction
