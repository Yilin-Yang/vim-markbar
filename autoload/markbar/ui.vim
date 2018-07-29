" RETURN:   (v:t_string)    The given mark, reformatted into a markbar
"                           'section heading'.
function! markbar#ui#GetMarkHeading(mark) abort
    return "['" . a:mark . ']:      \n'
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
    let l:marks = g:buffersToMarks[a:buffer_no]
    let l:marks_to_contexts = g:buffersToMarksToContexts[a:buffer_no]

    let l:lines = []
    let l:i = 0
    while l:i <# len(a:marks)
        let l:mark = a:marks[l:i]
        if !has_key(l:marks, l:mark) | continue | endif
        let l:lines += [markbar#ui#GetMarkHeading()]
        let l:lines += l:marks_to_contexts[l:mark] + ['\n']
    endwhile
endfunction

" REQUIRES: - `g:markbar_marks_to_display` is a properly configured
"           `v:t_string`.
" EFFECTS:  Opens a sidebar with marks visible.
" DETAILS:  Partially adapted from:
"           https://gist.github.com/romainl/eae0a260ab9c135390c30cd370c20cd7
function! markbar#ui#OpenMarkbar() abort
    let l:marks_to_display = markbar#settings#MarksToDisplay()
    assert_true(
        \ type(g:markbar_marks_to_display) ==# v:t_string,
        \ 'g:markbar_marks_to_display must be a string!'
    \ )

    let l:cur_buffer = bufnr('%')
    for l:win in range(1, winnr('$'))
        if getwinvar(l:win, 'is_markbar')
            execute l:win . 'windo close'
        endif
    endfor

    vnew +call append(0, markbar#ui#LinesInMarkbar(l:cur_buffer, l:marks_to_display))
    setlocal nobuflisted buftype=nofile bufhidden=wipe noswapfile
endfunction
