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

" REQUIRES: No buffer in the given range shall be a markbar buffer.
" EFFECTS:  Clear and repopulate the marks and contexts of the markbar
"           buffers corresponding to the given buffers.
" PARAM:    bufno_start (v:t_number)    The number of the first buffer to
"                                       refresh.
" PARAM:    bufno_end   (v:t_number)    The number of the last buffer to
"                                       refresh, inclusive. If not specified,
"                                       assumed to be equal to a:bufno_start.
function! markbar#ui#RefreshMarkbar(...) abort
    if get(a:, 0) !=# 1 && get(a:, 0) !=#  2
        throw 'Invalid argument number for markbar#ui#RefreshMarkbar: '
            \ . get(a:, 0)
    endif
    let l:marks_to_display = markbar#settings#MarksToDisplay()
    let a:bufno_start = get(a:, 1)
    let a:bufno_end   = get(a:, 2, a:bufno_start)
    for l:bufno in range(a:bufno_start, a:bufno_end)
        if !markbar#helpers#IsRealBuffer(l:bufno)
            throw '(vim-markbar) Given buffer is not a "real" buffer: '.l:bufno
        endif
        call markbar#state#UpdateCacheForBuffer(l:bufno)
        let l:markbar = g:buffersToMarkbars[l:bufno]
        call markbar#helpers#ReplaceBuffer(
            \ l:markbar,
            \ markbar#ui#LinesInMarkbar(l:bufno, l:marks_to_display)
        \ )
    endfor
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

function! markbar#ui#OpenMarkbarSplit(markbar) abort
    execute 'vsplit #' . a:markbar
    execute 'vertical resize ' . markbar#settings#MarkbarWidth()
endfunction
