function! s:CheckBadBufferType() abort
    if !exists('b:is_markbar') || !b:is_markbar
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

" EFFECTS:  Sets buffer-local markbar settings for the current buffer.
function! markbar#ui#SetMarkbarSettings() abort
    " TODO: user-configurable buffer settings?

    execute 'vertical resize ' . markbar#settings#MarkbarWidth()
    setlocal nobuflisted buftype=nofile bufhidden=hide noswapfile
    setlocal nowrap cursorline
    execute 'silent! file ' . markbar#settings#MarkbarBufferName()
    set filetype=markbar syntax=markbar

    let b:is_markbar = 1
    let w:is_markbar = 1

    call markbar#ui#SetGoToMark()
endfunction

" EFFECTS:  Opens an appropriately sized vertical split for a markbar.
function! markbar#ui#OpenMarkbarSplit(markbar) abort
    execute 'vsplit #' . a:markbar
    execute 'vertical resize ' . markbar#settings#MarkbarWidth()
endfunction

" EFFECTS:  Opens a markbar for the currently active buffer.
function! markbar#ui#OpenMarkbar() abort
    call g:markbar_buffers['openMarkbar()']()
endfunction
