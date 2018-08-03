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
        \ '^\[''.\]',
        \ 'bnc',
        \ 1
    \ )
    return getline(l:cur_heading)[2]
endfunction

function! s:GoToMark() abort
    let l:selected_mark = markbar#ui#GetCurrentMarkHeading()
    if !len(l:selected_mark) | return | endif
    execute 'wincmd p'
    let l:jump_command = 'normal! '
    let l:jump_command .= markbar#settings#JumpToExactPosition() ?
        \ '`' : "'"
    execute l:jump_command . l:selected_mark
    if markbar#settings#CloseAfterGoTo()
        call markbar#ui#CloseMarkbar()
    endif
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

    setlocal winfixwidth winfixheight cursorline
    setlocal nobuflisted buftype=nofile bufhidden=hide noswapfile
    setlocal nowrap nospell
    execute 'silent! file ' . markbar#settings#MarkbarBufferName()
    setlocal filetype=markbar syntax=markbar

    let b:is_markbar = 1
    let w:is_markbar = 1

    call markbar#ui#SetGoToMark()
endfunction

" EFFECTS:  - Opens an appropriately sized vertical split for a markbar.
"           - Sets appropriate markbar settings, if a new buffer was created.
" PARAM:    markbar     (v:t_number)    The buffer number to be opened in the
"                                       split. If none is provided, a new
"                                       buffer will be created.
" RETURNS:  (v:t_number)    The buffer number of the opened markbar.
function! markbar#ui#OpenMarkbarSplit(...) abort
    let a:markbar = get(a:, 1, '')

    let l:position = markbar#settings#OpenPosition() . ' '
    let l:orientation =
        \ markbar#settings#MarkbarOpenVertical() ?
            \ 'vertical ' : ' '
    let l:size = markbar#settings#MarkbarWidth() . ' '
    let l:command = empty(a:markbar) ? 'new ' : 'split #' . a:markbar

    try
        execute 'keepalt ' . l:position . l:orientation . l:size . l:command
    catch /E499/
        execute 'keepalt ' . l:position . l:orientation . l:size
            \ . 'split | buffer! ' . a:markbar
    endtry
    if empty(a:markbar)
        call markbar#ui#SetMarkbarSettings()
        return bufnr('%')
    endif

    return a:markbar
endfunction

" EFFECTS:  Opens a markbar for the currently active buffer.
function! markbar#ui#OpenMarkbar() abort
    call g:markbar_buffers['openMarkbar()']()
endfunction

" EFFECTS:  Closes the markbar for the currently active buffer, if a markbar
"           is open.
function! markbar#ui#CloseMarkbar() abort
    return g:markbar_buffers['closeMarkbar()']()
endfunction

" EFFECTS:  Closes the currently open markbar(s), if they are open. If none
"           are open, open a markbar for the active buffer.
function! markbar#ui#ToggleMarkbar() abort
    call g:markbar_buffers['toggleMarkbar()']()
endfunction
