function! s:CheckBadBufferType() abort
    if !exists('b:is_markbar') || !b:is_markbar
        throw '(vim-markbar) Cannot invoke this function outside of a markbar buffer/window!'
    endif
endfunction

" RETURNS:  (v:t_string)    The given mark, reformatted into a markbar
"                           'section heading'.
" PARAM:    mark    (MarkData)  The mark for which to produce a heading.
function! markbar#ui#MarkHeading(mark) abort
    call markbar#MarkData#AssertIsMarkData(a:mark)
    let l:suffix = ' '
    let l:user_given_name = a:mark['getName()']()
    if empty(l:user_given_name)
        let l:suffix .= markbar#ui#getDefaultName(a:mark)
    else
        let l:suffix .= l:user_given_name
    endif
    return "['" . a:mark['getMark()']() . ']:' . l:suffix
endfunction

" RETURNS:  (v:t_string)    The 'default name' for the given mark, as
"                           determined by the global mark name format strings.
" PARAM:    mark    (MarkData)  The mark for which to produce a name.
function! markbar#ui#getDefaultName(mark) abort
    call markbar#MarkData#AssertIsMarkData(a:mark)
    let l:mark_char = a:mark['getMark()']()
    if !markbar#helpers#IsGlobalMark(l:mark_char)
        let l:format_str = markbar#settings#MarkNameFormatString()
        let l:format_arg = markbar#settings#MarkNameArguments()
    elseif markbar#helpers#IsUppercaseMark(l:mark_char)
        let l:format_str = markbar#settings#FileMarkFormatString()
        let l:format_arg = markbar#settings#FileMarkArguments()
    else " IsNumberedMark
        let l:format_str = markbar#settings#NumberedMarkFormatString()
        let l:format_arg = markbar#settings#NumberedMarkArguments()
    endif
    let l:name = ''
    if empty(l:format_str) | return l:name | endif

    let l:cmd = 'let l:name = printf(''' . l:format_str . "'"
    let l:arg_to_val = {
        \ 'line':  a:mark['getLineNo()'],
        \ 'col':   a:mark['getColumnNo()'],
        \ 'fname': function('markbar#helpers#ParentFilename', [l:mark_char])
    \ }

    for l:Arg in l:format_arg " capital 'Arg' to handle funcrefs
        let l:cmd .= ', '
        if type(l:Arg) == v:t_func
            let l:cmd .= string(l:Arg(markbar#BasicMarkData#new(a:mark)))
        elseif has_key(l:arg_to_val, l:Arg)
            let l:cmd .= string(l:arg_to_val[l:Arg]())
        else
            throw '(markbar#ui#getDefaultName) Unrecognized format argument: '
                \ . l:Arg
        endif
    endfor
    let l:cmd .= ')'
    execute l:cmd
    return l:name
endfunction

" REQUIRES: User has focused a markbar buffer/window.
" RETURNS:  (v:t_number)    The line number of the 'currently selected' mark.
function! markbar#ui#GetCurrentMarkHeadingLine() abort
    call s:CheckBadBufferType()
    let l:cur_heading_no = search(
        \ '^\[''.\]',
        \ 'bnc',
        \ 1
    \ )
    return l:cur_heading_no
endfunction

" REQUIRES: User has focused a markbar buffer/window.
" RETURNS:  (v:t_string)    The 'currently selected' mark, or an empty string
"                           if no mark is selected.
function! markbar#ui#GetCurrentMarkHeading() abort
    return getline(markbar#ui#GetCurrentMarkHeadingLine())[2]
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
" EFFECTS:  Set a buffer-local mapping that sends the user to the selected
"           tag.
function! markbar#ui#SetGoToMark() abort
    call s:CheckBadBufferType()
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#JumpToMarkMapping()
        \ . ' :call <SID>GoToMark()<cr>'
endfunction

" REQUIRES: A markbar buffer is active and focused.
" EFFECTS:  Set a buffer-local mapping that prompts the user to rename the
"           selected mark.
function! markbar#ui#SetRenameMark() abort
    call s:CheckBadBufferType()
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#RenameMarkMapping()
        \ . ' :call markbar#ui#RenameMark()<cr>'
endfunction

" REQUIRES: A markbar buffer is active and focused.
" EFFECTS:  Set a buffer-local mapping that resets the name of the current
"           mark back to its default.
function! markbar#ui#SetResetMark() abort
    call s:CheckBadBufferType()
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#ResetMarkMapping()
        \ . ' :call markbar#ui#ResetMarkName()<cr>'
endfunction

" REQUIRES: A markbar buffer is active and focused.
" EFFECTS:  Set a buffer-local mapping that deletes the currently
"           selected mark.
function! markbar#ui#SetDeleteMark() abort
    call s:CheckBadBufferType()
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#DeleteMarkMapping()
        \ . ' :call markbar#ui#DeleteMark()<cr>'
endfunction

" EFFECTS:  Set buffer-local markbar settings for the current buffer.
function! markbar#ui#SetMarkbarSettings() abort
    " TODO: user-configurable buffer settings?

    setlocal winfixwidth winfixheight cursorline
    setlocal foldcolumn=0 signcolumn=no
    setlocal nobuflisted buftype=nofile bufhidden=hide noswapfile
    setlocal norelativenumber nonumber
    setlocal nowrap nospell
    execute 'keepalt silent! file! ' . markbar#settings#MarkbarBufferName()
    setlocal filetype=markbar syntax=markbar

    let b:is_markbar = 1
    let w:is_markbar = 1

    call markbar#ui#SetGoToMark()
    call markbar#ui#SetRenameMark()
    call markbar#ui#SetResetMark()
    call markbar#ui#SetDeleteMark()
endfunction

" EFFECTS:  Set an autocommand to print the current mark heading, or disable
"           the same if the current buffer is not a markbar buffer.
function! markbar#ui#SetEchoHeaderAutocmds() abort
    if getbufvar(bufnr('%'), 'is_markbar')
        augroup vim_markbar_echo_header
            au!
            autocmd CursorHold,CursorMoved *
                \ echo getline(markbar#ui#GetCurrentMarkHeadingLine())
        augroup end
    else
        augroup vim_markbar_echo_header
            au!
        augroup end
    endif
endfunction

" EFFECTS:  - Open an appropriately sized vertical split for a markbar.
"           - Set appropriate markbar settings, if a new buffer was created.
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
        execute 'keepalt silent ' . l:position . l:orientation . l:size . l:command
    catch /E499/
        execute 'keepalt silent ' . l:position . l:orientation . l:size
            \ . 'split | buffer! ' . a:markbar
    endtry
    if empty(a:markbar)
        call markbar#ui#SetMarkbarSettings()
        return bufnr('%')
    endif

    return a:markbar
endfunction

" EFFECTS:  Open a markbar for the currently active buffer.
function! markbar#ui#OpenMarkbar() abort
    call g:markbar_buffers['openMarkbar()']()
endfunction

" EFFECTS:  Close the markbar for the currently active buffer, if a markbar
"           is open.
function! markbar#ui#CloseMarkbar() abort
    return g:markbar_buffers['closeMarkbar()']()
endfunction

" EFFECTS:  Close the currently open markbar(s), if they are open. If none
"           are open, open a markbar for the active buffer.
function! markbar#ui#ToggleMarkbar() abort
    call g:markbar_buffers['toggleMarkbar()']()
endfunction

" EFFECTS:  If any markbars are open,
"           - Close any open markbars,
"           - Open an updated markbar for the current active buffer.
function! markbar#ui#RefreshMarkbar() abort
    if !markbar#helpers#IsRealBuffer(bufnr('%')) | return | endif
    if g:markbar_buffers['markbarIsOpenCurrentTab()']()
        let l:cur_winnr = winnr()
        call markbar#ui#OpenMarkbar()
        execute l:cur_winnr . 'wincmd w'
    endif
endfunction

function! markbar#ui#RenameMark() abort
    let l:selected_mark = markbar#ui#GetCurrentMarkHeading()
    if !len(l:selected_mark) | return | endif
    let l:mark = g:markbar_buffers['getMarkData()'](l:selected_mark)

    call inputsave()
    let l:new_name = input('New name for mark [''' . l:selected_mark . ']: ',
        \ l:mark['getName()'](),
        \ markbar#settings#RenameMarkCompletion()
    \ )
    call inputrestore()

    call l:mark['setName()'](l:new_name)

    let l:cur_pos = getcurpos()
    call markbar#ui#OpenMarkbar()
    call setpos('.', l:cur_pos)
endfunction

function! markbar#ui#ResetMarkName() abort
    let l:selected_mark = markbar#ui#GetCurrentMarkHeading()
    if !len(l:selected_mark) | return | endif
    let l:mark = g:markbar_buffers['getMarkData()'](l:selected_mark)

    call l:mark['setName()']('')

    let l:cur_pos = getcurpos()
    call markbar#ui#OpenMarkbar()
    call setpos('.', l:cur_pos)
endfunction

function! markbar#ui#DeleteMark() abort
    let l:selected_mark = markbar#ui#GetCurrentMarkHeading()
    if !len(l:selected_mark) | return | endif

    let l:cur_pos = getcurpos()
    if !markbar#helpers#IsGlobalMark(l:selected_mark)
        let l:active_buffer = g:markbar_buffers['getActiveBuffer()']()
        execute bufwinnr(l:active_buffer) . 'wincmd w'
    endif

    execute 'delmarks ' . l:selected_mark

    call markbar#ui#OpenMarkbar()
    call setpos('.', l:cur_pos)
endfunction
