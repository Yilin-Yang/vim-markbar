function! markbar#settings#MarksToDisplay() abort
    if !exists(g:markbar_marks_to_display)
        let g:markbar_marks_to_display =
            \ 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    endif
    return g:markbar_marks_to_display
endfunction
