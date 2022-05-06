let s:BufferCache = {
    \ 'TYPE': 'BufferCache',
    \ 'marks_dict': {},
    \ '_buffer_no': 0,
\ }

" EFFECTS:  Construct and return a BufferCache.
" DETAILS:  BufferCache stores marks and contexts for a particular buffer in
"           a dictionary `marks_dict`. `a_buf_cache['a']` returns a
"           (markbar#MarkData) for mark `a`. The dictionary is exposed
"           directly because encapsulating it with getters and setters is
"           more trouble than it's worth.
" PARAM:    buffer_no   (v:t_number)    This BufferCache's buffer's |bufnr()|.
function! markbar#BufferCache#New(buffer_no) abort
    call markbar#ensure#IsNumber(a:buffer_no)
    let l:new = deepcopy(s:BufferCache)
    let l:new._buffer_no = a:buffer_no
    return l:new
endfunction

" RETURNS:  (markbar#MarkData)  MarkData of the requested mark.
function! s:BufferCache.getMark(mark) abort dict
    let l:is_quote = a:mark ==# "'" || a:mark ==# '`'
    let l:mark = (l:is_quote) ? "'" : a:mark
    try
        let l:md = l:self.marks_dict[l:mark]
    catch /E716/ " Key not present in dictionary
        throw 'Requested mark not in cache: ' . a:mark
    endtry
    return l:md
endfunction

" EFFECTS:  Repopulate BufferCache's `marks_dict` with the given marks output.
" PARAM:    marks_output    (v:t_string)    The 'raw' output of |:marks|.
function! s:BufferCache.updateCache(marks_output) abort dict
    call markbar#ensure#IsString(a:marks_output)

    " strip leading whitespace and columns header ('mark line  col file/text')
    let l:trimmed = markbar#helpers#TrimMarksHeader(a:marks_output)

    let l:markstrings = split(l:trimmed, '\r\{0,1}\n')
    let l:new_marks_dict = {}
    let l:i = len(l:markstrings)
    while l:i
        let l:i -= 1
        try
            let l:markdata = markbar#MarkData#New(l:markstrings[l:i])
            let l:new_marks_dict[l:markdata.getMarkChar()] = l:markdata
        catch /markstring parsing failed/
            " drop this markdata
        endtry
    endwhile

    " copy over existing mark names
    let l:old_dict = l:self.marks_dict
    for l:mark in keys(l:old_dict)
        if !has_key(l:new_marks_dict, l:mark)
            continue
        endif
        call l:new_marks_dict[l:mark].setName(l:old_dict[l:mark].getName())
    endfor

    let l:self.marks_dict = l:new_marks_dict
endfunction

" EFFECTS:  - Retrieve new contexts for this BufferCache's marks.
"           - Clear cached mark contexts for marks that shouldn't exist anymore.
"           - Fetch updated contexts for all marks.
" PARAM:    num_lines   (v:t_number)    Number of lines of context to retrieve.
function! s:BufferCache.updateContexts(num_lines) abort dict
    let l:using_global_marks = l:self.isGlobal()
    let l:buffer_no = l:self._buffer_no
    for l:mark in keys(l:self.marks_dict)
        let l:mark_data = l:self.marks_dict[l:mark]
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
        call l:mark_data.setContext(l:context)
    endfor
endfunction

function! s:BufferCache.isGlobal() abort dict
    return l:self._buffer_no ==# markbar#constants#GLOBAL_MARKS_BUFNR()
endfunction
