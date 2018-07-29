" RETURN:   (v:t_string)    The given mark, reformatted into a markbar
"                           'section heading', including the mark's name, if
"                           assigned one by the user.
function! markbar#ui#GetMarkHeading(buffer_no, mark) abort
    return "['" . a:mark . ']:      \n'
endfunction

" RETURN:   (v:t_number)    The line number of the markbar section heading for
"                           the requested mark, or `0` if it wasn't found.
function! markbar#ui#FindMarkHeading(mark) abort
    return search(
        \ '^\[' . "'" . a:mark . '\]      :\n',
        \ 'wnsc'
    \ )
endfunction

" RETURN:   (v:t_number)    The line number of the last line of context for
"                           the requested mark, or `0` if that mark has no
"                           section in the current buffer.
function! markbar#ui#LastLineOfMarkSection(mark) abort
endfunction

" EFFECTS:  - Replaces the lines in the range `[a:start, a:end]` (*fully*
"           inclusive) in the given buffer with the lines in the list `a:set_to`.
function! markbar#ui#SetBufLine(buffer_expr, start, end, set_to) abort
    if a:start <# a:end && a:end >=# -1
        throw 'Invalid range (line a:start must precede line a:end), '
            \ 'gave vals: ' . a:start . ', ' . a:end
    endif
    if has('nvim')
        call nvim_buf_set_lines(
            \ a:buffer_expr,
            \ a:start,
            \ a:end + 1,
            \ v:false,
            \ a:set_to
        \ )
    elseif exists('*setbufline') && exists('*deletebufline')
        " TODO
        " let l:num_lines = abs(a:end - a:start) + 1
        " let l:dummy_lines =

        " while l:i <# len(a:set_to) && l:i + a:start <=# a:end
        "     call setbufline(a:buffer_expr, l:line_no, a:set_to[l:i])
        "     let l:i += 1
        " endwhile
    else
        throw '(vim-markbar) Error: vim version is too old! Need neovim, '
            . 'or vim 8.1+ (with `setbufline` support).'
    endif
endfunction

" REQUIRES: - Given `a:buffer_no` is not a markbar buffer.
"           - Given `a:markbar_no` actually corresponds to a markbar buffer.
"           - Both `a:buffer_no` nor `a:markbar_no` are buffer *numbers.*
" EFFECTS:  - Populates the requested markbar buffer with the requested marks
"           and those marks' contexts.
" PARAM:    marks   (v:t_string)    Every mark that the user wishes to
"                                   display, in order from left to right (i.e.
"                                   first character is the mark that should
"                                   appear at the top of the markbar.)
function! markbar#ui#PopulateMarkbar(buffer_no, markbar_no, marks) abort
    let l:marks = g:buffersToMarks[a:buffer_no]
    let l:marks_to_contexts = g:buffersToMarksToContexts[a:buffer_no]
    let l:i = 0
    while l:i <# len(a:marks)
        let l:mark = a:marks[l:i]
        if !has_key(l:marks, l:mark)
            " TODO wipe out those lines and that section
            continue
        endif
        let l:line_no
    endwhile
endfunction

function! markbar#ui#OpenMarkbar() abort
endfunction
