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
        let g:buffersToMarksToContexts[a:buffer_no] = {}
    endif
    let l:marks_to_contexts = g:buffersToMarksToContexts[a:buffer_no]

    " remove orphaned contexts
    for l:mark in keys(l:marks_to_contexts)
        if !has_key(l:marks_database, l:mark)
            " mark not found in updated marks database
            call remove(l:marks_to_contexts, l:mark)
        endif
    endfor

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
        let l:marks_to_contexts[l:mark] = l:context
    endfor
endfunction

" REQUIRES: - Updated `g:buffersToMarks`.
" EFFECTS:  - Clears cached mark contexts for marks known to no longer exist.
"           - Fetches updated contexts for all accessible/cached marks.
" PARAM:    num_lines   (v:t_number)    The total number of lines of context
"                                       to retrieve.
function! markbar#state#UpdateAllContexts(num_lines) abort
    let l:i = 0
    let l:buffers = keys(g:buffersToMarks)
    while l:i < len(l:buffers)
        let l:buffer_no = l:buffers[l:i]
        call markbar#state#UpdateContextsForBuffer(l:buffer_no, a:num_lines)
    endwhile
endfunction

" EFFECTS:  - Repopulates the mark cache for the given buffer, if it is the
"           currently focused buffer.
"           - Repopulates the global buffer cache.
"           - Fetch new contexts from the local buffer and for global marks.
function! markbar#state#UpdateCacheForBuffer(buffer_no) abort
    if !bufexists(a:buffer_no)
        throw "Can't update cache for nonexistent buffer: " . a:buffer_no
    endif
    if !markbar#helpers#IsRealBuffer(a:buffer_no)
        throw "Can't update cache for ignored buffer: " . a:buffer_no
    endif
    if a:buffer_no ==# bufnr('%')
        call markbar#state#PopulateBufferDatabase()
    endif
    call markbar#state#PopulateGlobalDatabase()
    call markbar#state#UpdateContextsForBuffer(
        \ a:buffer_no,
        \ markbar#settings#NumLinesContext()
    \ )
    call markbar#state#UpdateContextsForBuffer(
        \ 0,
        \ markbar#settings#NumLinesContext()
    \ )
endfunction

" EFFECTS:  Pushes `a:buffer_no` onto `g:activeBufferStack` if `a:buffer_no`
"           is a real buffer.
function! markbar#state#PushNewActiveBuffer() abort
    let a:buffer_no = expand('<abuf>') + 0
    if markbar#helpers#IsRealBuffer(a:buffer_no)
        let g:activeBufferStack += [a:buffer_no]
    endif
    call markbar#state#SizeCheckActiveBufferStack()
endfunction

" RETURN:   The topmost active buffer in the stack.
" MODIFIES: `g:activeBufferStack`, if the topmost buffer is a 'fake' buffer.
function! markbar#state#GetActiveBuffer() abort
    while len(g:activeBufferStack)
            \ && !markbar#helpers#IsRealBuffer(g:activeBufferStack[-1])
        call remove(g:activeBufferStack, -1)
    endwhile
    return g:activeBufferStack[-1]
endfunction

" EFFECTS:  Walks through the active buffer stack and removes buffers that are
"           now known to be 'fake'.
" MODIFIES: `g:activeBufferStack`, if it contains 'fake' buffers.
function! markbar#state#CleanActiveBufferStack() abort
    let l:i = len(g:activeBufferStack)
    while l:i
        let l:i -= 1
        if markbar#helpers#IsRealBuffer(g:activeBufferStack[l:i])
            continue
        endif
        call remove(g:activeBufferStack, l:i)
    endwhile
endfunction

" EFFECTS:  Reduce the size of the active buffer stack if it exceeds a
"           threshold.
" MODIFIES: `g:activeBufferStack`
function! markbar#state#SizeCheckActiveBufferStack() abort
    let l:max_stack_size = markbar#settings#MaximumActiveBufferHistory()
    if len(g:activeBufferStack) ># l:max_stack_size
        call markbar#state#CleanActiveBufferStack()
    else
        return
    endif
    let l:stack_len = len(g:activeBufferStack)
    if  l:stack_len ># l:max_stack_size
        let g:activeBufferStack = g:activeBufferStack[l:stack_len / 2 : ]
    endif
endfunction

" EFFECTS:  - Creates a new markbar buffer for the given buffer, with
"           the appropriate buffer-local settings.
"           - Opens the new buffer.
"           - Creates an entry for the given buffer in `g:buffersToMarkbars`.
" RETURN:   (v:t_number)    The buffer number of the new buffer.
function! markbar#state#SpawnNewMarkbarBuffer(buffer_no) abort
    if has_key(g:buffersToMarkbars, a:buffer_no)
        throw 'Tried to create a new markbar for a buffer that already had one!'
    endif
    vnew
    let l:markbar = bufnr('%')
    let g:buffersToMarkbars[a:buffer_no] = l:markbar
    call markbar#ui#SetMarkbarSettings()
    return l:markbar
endfunction
