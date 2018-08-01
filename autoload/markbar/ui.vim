function! s:CheckBadBufferType() abort
    if !w:is_markbar || !b:is_markbar
        throw '(vim-markbar) Cannot invoke this function outside of a markbar buffer/window!'
    endif
endfunction

" RETURN:   (v:t_list)      The given mark, reformatted into a markbar
"                           'section heading'.
function! markbar#ui#MarkHeading(mark) abort
    let l:suffix = ' '
    if markbar#helpers#IsGlobalMark(a:mark)
        let l:suffix .= markbar#helpers#ParentFilename(a:mark)
    endif
    return ["['" . a:mark . ']:   ' . l:suffix]
endfunction

" REQUIRES: User has focused a markbar buffer/window.
" RETURN:   (v:t_string)    The 'currently selected' mark, or an empty string
"                           if no mark is selected.
function! markbar#ui#GetCurrentMarkHeading() abort
    call s:CheckBadBufferType()
    let l:cur_heading = search(
        \ "^\['.\]",
        \ 'bnc',
        \ 1
    \ )
    return getline(l:cur_heading)[2]
endfunction

function! s:GoToMark() abort
    let l:selected_mark = markbar#ui#GetCurrentMarkHeading()
    if !len(l:selected_mark) | return | endif

endfunction

" REQUIRES: A markbar buffer is active and focused.
" EFFECTS:  Sets a buffer-local mapping that sends the user to the selected
"           tag.
function! markbar#ui#SetGoToMark() abort
    call s:CheckBadBufferType()
    noremap <silent> <buffer> <cr> :call <SID>GoToMark()<cr>
endfunction

" REQUIRES: - `a:buffer_no` is not a markbar buffer.
"           - `a:buffer_no` is a buffer *number.*
" EFFECTS:  - Returns a list populated linewise with the requested marks
"           and those marks' contexts.
" PARAM:    marks   (v:t_string)    Every mark that the user wishes to
"                                   display, in order from left to right (i.e.
"                                   first character is the mark that should
"                                   appear at the top of the markbar.)
function! markbar#ui#LinesInMarkbar(buffer_no, marks) abort
    let l:marks   = g:buffersToMarks[a:buffer_no]
    let l:globals = g:buffersToMarks[0]
    let l:marks_to_contexts   = g:buffersToMarksToContexts[a:buffer_no]
    let l:globals_to_contexts = g:buffersToMarksToContexts[0]

    let l:lines = []
    let l:i = -1
    while l:i <# len(a:marks)
        let l:i += 1
        let l:mark = a:marks[l:i]

        if !has_key(l:marks, l:mark) && !has_key(l:globals, l:mark)
            continue
        endif

        let l:lines += markbar#ui#MarkHeading(l:mark)

        let l:contexts =
            \ markbar#helpers#IsGlobalMark(l:mark) ?
                \ l:globals_to_contexts[l:mark]
                \ :
                \ l:marks_to_contexts[l:mark]

        let l:j = 0
        while l:j <# len(l:contexts)
            let l:lines +=
                \ [markbar#settings#ContextIndentBlock() . l:contexts[l:j]]
            let l:j += 1
        endwhile

        let l:lines += markbar#settings#MarkbarSectionSeparator()
    endwhile

    return l:lines
endfunction

" EFFECTS:  Opens the given markbar buffer in an appropriately-sized split.
function! markbar#ui#OpenMarkbarSplit(markbar) abort
    execute 'vsplit #' . a:markbar
    execute 'vertical resize ' . markbar#settings#MarkbarWidth()
endfunction

" EFFECTS:  Sets buffer-local markbar settings for the current buffer.
function! markbar#ui#SetMarkbarSettings() abort
    " TODO: user-configurable buffer settings?

    execute 'vertical resize ' . markbar#settings#MarkbarWidth()
    setlocal nobuflisted buftype=nofile bufhidden=hide noswapfile
    setlocal nowrap cursorline
    execute 'silent! file ' . markbar#settings#MarkbarBufferName()
    set filetype=markbar syntax=markbar

    let b:is_markbar = 1
endfunction

" REQUIRES: No buffer in the given range shall be a markbar buffer.
" EFFECTS:  Clear and repopulate the marks and contexts of the markbar
"           buffers corresponding to the given buffers.
" PARAM:    bufno_start (v:t_number)    The number of the first buffer to
"                                       refresh.
" PARAM:    bufno_end   (v:t_number)    The number of the last buffer to
"                                       refresh, inclusive. If not specified,
"                                       assumed to be equal to a:bufno_start.
function! markbar#ui#RefreshMarkbar(...) abort
    call assert_inrange(1, 2, a:0,
        \ 'Invalid argument number for markbar#ui#RefreshMarkbar.')
    let l:marks_to_display = markbar#settings#MarksToDisplay()
    let a:bufno_start = a:1
    let a:bufno_end   = get(a:, 2, a:bufno_start)
    for l:bufno in range(a:bufno_start, a:bufno_end)
        if !markbar#helpers#IsRealBuffer(l:bufno)
            throw '(vim-markbar) Given buffer is not a "real" buffer: '.l:bufno
        endif
        let l:markbar = g:buffersToMarkbars[l:bufno]
        call markbar#helpers#ReplaceBuffer(
            \ l:markbar,
            \ markbar#ui#LinesInMarkbar(l:bufno, l:marks_to_display)
        \ )
    endfor
endfunction

" REQUIRES: - `g:markbar_marks_to_display` is a properly configured
"           `v:t_string`.
" EFFECTS:  Opens a sidebar with marks visible.
" DETAILS:  Partially adapted from:
"           https://gist.github.com/romainl/eae0a260ab9c135390c30cd370c20cd7
function! markbar#ui#OpenMarkbar() abort
    let l:cur_buffer = markbar#state#GetActiveBuffer()

    if !has_key(g:buffersToMarkbars, l:cur_buffer)
        call markbar#state#SpawnNewMarkbarBuffer(l:cur_buffer)
    else
        let l:markbar = g:buffersToMarkbars[l:cur_buffer]
        call markbar#ui#OpenMarkbarSplit(l:markbar)
    endif
    call markbar#ui#RefreshMarkbar(l:cur_buffer)

    " TODO: go back to old position?
    normal! gg
endfunction
