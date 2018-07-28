" REQUIRES: - Updated `g:buffersToDatabases`, or else results will be
"           'outdated'.
" RETURNS:  (v:t_bool)      `v:true` if the given line number, in the *current
"                           buffer*, has a mark. `v:false` otherwise.
function! markbar#state#LineHasMark(line_no) abort
    let l:cur_buffer = bufnr('%')
    let l:marks_ptr = g:buffersToDatabases[l:cur_buffer] " alias
    let l:i = 0
    while l:i <# len(l:marks_ptr)
        if l:marks_ptr[l:i][1] ==# a:line_no
            return v:true
        endif
        let l:i += 1
    endwhile

    let l:marks_ptr = g:buffersToDatabases[0] " alias
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

" REQUIRES: - Updated `g:buffersToDatabases`, or else results will be
"           'outdated'.
" RETURNS:  (v:t_bool)      `v:true` if a line number in the given range, in
"                           the *current buffer*, has a mark. `v:false`
"                           otherwise.
function! markbar#state#RangeHasMark(start, end) abort
    if a:start ># a:end || a:start <# 0 || a:end <# 0
        throw 'Invalid range in call to RangeHasMark: '.a:start.','.a:end
    endif

    let l:cur_buffer = bufnr('%')
    let l:marks_ptr = g:buffersToDatabases[l:cur_buffer] " alias
    let l:i = 0
    while l:i <# len(l:marks_ptr)
        let l:line_no = l:marks_ptr[l:i][1]
        if l:line_no >=# a:start && l:line_no <= a:end
            return v:true
        endif
        let l:i += 1
    endwhile

    let l:marks_ptr = g:buffersToDatabases[0] " alias
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
    let g:buffersToDatabases[l:cur_buffer] =
        \ markbar#textmanip#MarksStringToNestedList(l:raw_local_marks)
endfunction

" EFFECTS:  Totally reconstruct the global marks database.
function! markbar#state#PopulateGlobalDatabase() abort
    let l:raw_global_marks =
        \ markbar#textmanip#TrimMarksHeader(markbar#helpers#GetGlobalMarks())
    let g:buffersToDatabases[0] =
        \ markbar#textmanip#MarksStringToNestedList(l:raw_global_marks)
endfunction

" REQUIRES: - Updated `g:buffersToDatabases`.
"           - `g:buffersToDatabases` entry exists for the requested buffer.
" EFFECTS:  - Creates a context cache entry for the requested buffer, if none
"           yet exists.
"           - Clears cached mark contexts for marks believed to no longer exist.
"           - Tries to fetch updated contexts for all marks in the given buffer.
function! markbar#state#UpdatedContextsForBuffer(buffer_no) abort
    let l:marks_ptr = g:buffersToDatabases[a:buffer_no]
    " TODO
endfunction

" REQUIRES: - Updated `g:buffersToDatabases`.
" EFFECTS:  - Clears cached mark contexts for marks known to no longer exist.
"           - Fetches updated contexts for all accessible marks.
function! markbar#state#UpdateContexts() abort
    " TODO
endfunction
