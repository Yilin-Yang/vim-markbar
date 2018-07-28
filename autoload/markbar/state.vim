" REQUIRES: - Updated `g:buffersToMarks`, or else results will be
"           'outdated'.
" RETURNS:  (v:t_bool)      `v:true` if the given line number, in the *current
"                           buffer*, has a mark. `v:false` otherwise.
function! markbar#state#LineHasMark(line_no) abort
    let l:cur_buffer = bufnr('%')
    let l:marks_ptr = g:buffersToMarks[l:cur_buffer] " alias
    let l:i = 0
    while l:i <# len(l:marks_ptr)
        if l:marks_ptr[l:i][1] ==# a:line_no
            return v:true
        endif
        let l:i += 1
    endwhile

    let l:marks_ptr = g:buffersToMarks[0] " alias
    let l:i = 0
    while l:i <# len(l:marks_ptr)
        let l:mark_ptr = l:marks_ptr[l:i]
        if InCurrentBuffer(l:mark_ptr[0]) && l:mark_ptr[1] ==# a:line_no
            return v:true
        endif
        let l:i += 1
    endwhile

    return v:false
endfunction

" REQUIRES: - Updated `g:buffersToMarks`, or else results will be
"           'outdated'.
" RETURNS:  (v:t_bool)      `v:true` if a line number in the given range, in
"                           the *current buffer*, has a mark. `v:false`
"                           otherwise.
function! markbar#state#RangeHasMark(start, end) abort
    if a:start ># a:end || a:start <# 0 || a:end <# 0
        throw 'Invalid range in call to RangeHasMark: '.a:start.','.a:end
    endif

    let l:cur_buffer = bufnr('%')
    let l:marks_ptr = g:buffersToMarks[l:cur_buffer] " alias
    let l:i = 0
    while l:i <# len(l:marks_ptr)
        let l:line_no = l:marks_ptr[l:i][1]
        if l:line_no >=# a:start && l:line_no <= a:end
            return v:true
        endif
        let l:i += 1
    endwhile

    let l:marks_ptr = g:buffersToMarks[0] " alias
    let l:i = 0
    while l:i <# len(l:marks_ptr)
        let l:mark_ptr = l:marks_ptr[l:i]
        let l:line_no = l:mark_ptr[1]
        if InCurrentBuffer(l:mark_ptr[0])
        \ && (l:line_no >=# a:start && l:line_no <=# a:end)
            return v:true
        endif
        let l:i += 1
    endwhile

    return v:false
endfunction

" EFFECTS:  Totally reconstruct the local marks database for the current
"           buffer.
function! markbar#state#PopulateBufferDatabase() abort
    let l:cur_buffer = bufnr('%')
    let l:raw_local_marks =
        \ markbar#textmanip#TrimMarksHeader(markbar#helpers#GetLocalMarks())
    let g:buffersToMarks[l:cur_buffer] =
        \ markbar#textmanip#MarksStringToDictionary(l:raw_local_marks)
endfunction

" EFFECTS:  Totally reconstruct the global marks database.
function! markbar#state#PopulateGlobalDatabase() abort
    let l:raw_global_marks =
        \ markbar#textmanip#TrimMarksHeader(markbar#helpers#GetGlobalMarks())
    let g:buffersToMarks[0] =
        \ markbar#textmanip#MarksStringToDictionary(l:raw_global_marks)
endfunction

" REQUIRES: - Updated `g:buffersToMarks`.
"           - `g:buffersToMarks` entry exists for the requested buffer.
" EFFECTS:  - Creates a context cache entry for the requested buffer, if none
"           yet exists.
"           - Clears cached mark contexts for marks believed to no longer exist.
"           - Tries to fetch updated contexts for all marks in the given buffer.
" PARAM:    buffer_no   (v:t_number)    The number of the buffer to check.
" PARAM:    num_lines   (v:t_number)    The total number of lines of context
"                                       to retrieve.
function! markbar#state#UpdateContextsForBuffer(buffer_no, num_lines) abort
    if type(a:buffer_no) != v:t_number
        throw '`a:buffer_no` must be of type v:t_number. Gave value: ' . a:buffer_no
    endif

    " E716 check (for nonextant dictionary key) + convenience alias
    let l:marks_database = g:buffersToMarks[a:buffer_no]

    if !has_key(g:buffersToMarksToContexts, a:buffer_no)
        g:buffersToMarksToContexts[a:buffer_no] = {}
    endif
    let l:marks_to_contexts = g:buffersToMarksToContexts[a:buffer_no]

    " remove orphaned contexts
    let l:marks_w_context = keys(l:marks_to_contexts)
    let l:i = 0
    while l:i < len(l:marks_w_context)
        let l:mark   = l:marks_w_context[l:i]
        if !has_key(l:marks_database, l:mark)
            " mark not found in updated marks database
            call remove(l:marks_to_contexts, l:mark)
        endif
        let l:i += 1
    endwhile

    " fetch updated mark contexts
    let l:i = 0
    let l:using_global_marks = !a:buffer_no
    let l:buffer_no = a:buffer_no

    for l:mark in keys(l:marks_database)
        let l:line_no = l:marks_database[l:mark][1]

        " if these are global marks, perform file lookup for each mark
        if l:using_global_marks
            let l:buffer_no = markbar#helpers#BufferNo(l:mark)
        endif

        let l:context = markbar#helpers#FetchContext(
            \ l:buffer_no,
            \ l:line_no,
            \ a:num_lines
        \ )
        if empty(l:context) | continue | endif
        let l:marks_to_contexts[l:mark] = l:context
    endfor
endfunction

" REQUIRES: - Updated `g:buffersToMarks`.
" EFFECTS:  - Clears cached mark contexts for marks known to no longer exist.
"           - Fetches updated contexts for all accessible/cached marks.
function! markbar#state#UpdateAllContexts() abort
    let l:i = 0
    let l:buffers = keys(g:buffersToMarks)
    while l:i < len(l:buffers)
        let l:buffer_no = l:buffers[l:i]
        call markbar#state#UpdateContextsForBuffer(l:buffer_no)
    endwhile
endfunction
