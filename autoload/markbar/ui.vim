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

function! s:GoToTag() abort
    let l:selected_mark = markbar#ui#GetCurrentMarkHeading()
    if !len(l:selected_mark) | return | endif

endfunction

" REQUIRES: A markbar buffer is active and focused.
" EFFECTS:  Sets a buffer-local mapping that sends the user to the selected
"           tag.
function! markbar#actions#SetGoToTag() abort
    call s:CheckBadBufferType()
    noremap <silent> <buffer> <cr> :call <SID>GoToTag()<cr>
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

" REQUIRES: - `g:markbar_marks_to_display` is a properly configured
"           `v:t_string`.
" EFFECTS:  Opens a sidebar with marks visible.
" DETAILS:  Partially adapted from:
"           https://gist.github.com/romainl/eae0a260ab9c135390c30cd370c20cd7
function! markbar#ui#OpenMarkbar() abort
    let l:marks_to_display = markbar#settings#MarksToDisplay()

    let l:cur_buffer = bufnr('%')
    for l:win in range(1, winnr('$'))
        if getwinvar(l:win, 'is_markbar')
            execute l:win . 'windo close'
        endif
    endfor

    vnew
    call append(0, markbar#ui#LinesInMarkbar(l:cur_buffer, l:marks_to_display))
    execute 'vertical resize ' . markbar#settings#MarkbarWidth()
    setlocal nobuflisted buftype=nofile bufhidden=wipe noswapfile
    setlocal nowrap cursorline

    execute 'silent! file ' . markbar#settings#MarkbarBufferName()
    set filetype=markbar syntax=markbar

    let w:is_markbar = 1
    let b:is_markbar = 1

    " TODO: go back to old position?
    normal! gg
endfunction
