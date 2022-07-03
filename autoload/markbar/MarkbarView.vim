" BRIEF:    The user's View into the markbar state.
" DETAILS:  MarkbarView manipulates the components of vim-markbar's interface
"           that the user can see. It also stores information about these
"           visible components, and how the user is interacting with these
"           components.

let s:MarkbarView = {
    \ 'TYPE': 'MarkbarView',
    \ '_markbar_model': {},
    \ '_markbar_buffer': -2,
    \ '_cur_winid': 1,
    \ '_saved_view': {},
    \ '_win_resize_cmd:': '',
    \ '_saved_num_win': -1,
    \ '_saved_tabpage_nr': -1,
\ }

" BRIEF:    Construct a MarkbarView object.
" PARAM:    model   (markbar#MarkbarModel)  Reference to stored information
"                                           about the markbar state.
function! markbar#MarkbarView#New(model) abort
    call markbar#ensure#IsClass(a:model, 'MarkbarModel')
    let l:new = deepcopy(s:MarkbarView)
    let l:new._markbar_model = a:model
    return l:new
endfunction

function! markbar#MarkbarView#MarkNotSet(mark) abort
    echohl WarningMsg
    echomsg printf('Mark not set: %s', a:mark)
    echohl None
endfunction

" BRIEF:    Save window state and open a markbar window for the active buffer.
" PARAM:    open_position   (v:t_string)    The position modifier to apply to
"                                           the opened markbar. See
"                                           `:h topleft`, `:h botright`.
" PARAM:    open_vertical   (v:t_bool)  `v:true` if the markbar should be a
"                                       vertical split, `v:false` otherwise.
" PARAM:    size    (v:t_number)    The width of the markbar in columns if
"                                   opened in a vertical split; the height of
"                                   the markbar in lines, otherwise.
function! markbar#MarkbarView#openMarkbar(open_position, open_vertical, size) abort dict
    if !exists('b:is_markbar')
        " only save the window state if we aren't already in the markbar
        call l:self._saveWinState()
    endif
    let l:markbar_buffer = l:self.getMarkbarBuffer()
    let l:markbar_winid = l:self.getMarkbarWinID()
    if l:markbar_winid ==# -1
        let l:orientation = a:open_vertical ? 'vertical ' : ''
        execute printf('keepalt silent %s %s %s split | buffer! %s',
            \ a:open_position, l:orientation, a:size, l:markbar_buffer)

        call l:self._setMarkbarBufferSettings(l:markbar_buffer)
        call setbufvar(l:markbar_buffer, '&buflisted', 0)
    else
        " switch to existing markbar window
        execute win_gotoid(l:markbar_winid)
    endif
    call l:self._setMarkbarWindowSettings(l:markbar_buffer)
endfunction
let s:MarkbarView.openMarkbar = function('markbar#MarkbarView#openMarkbar')

" DETAILS:  Close markbars without calling _restoreWinState, which would move
"           the cursor.
function! markbar#MarkbarView#_closeMarkbar() abort dict
    let l:markbar_buffers = l:self.getOpenMarkbars()
    if empty(l:markbar_buffers)
        return v:false
    endif
    for l:markbar in l:markbar_buffers
        execute bufwinnr(l:markbar) . 'close'
    endfor
    return v:true
endfunction
let s:MarkbarView._closeMarkbar = function('markbar#MarkbarView#_closeMarkbar')

" BRIEF:    Close markbars open in the current tab and restore old window state.
" RETURNS:  (v:t_bool)      `v:true` if a markbar was actually closed,
"                           `v:false` otherwise.
function! markbar#MarkbarView#closeMarkbar() abort dict
    if !l:self._closeMarkbar()
        return v:false
    endif
    call l:self._restoreWinState()
    return v:true
endfunction
let s:MarkbarView.closeMarkbar = function('markbar#MarkbarView#closeMarkbar')

" RETURNS:  (v:t_bool)  `v:true` if a markbar window is open in the current tab.
function! markbar#MarkbarView#markbarIsOpenCurrentTab() abort dict
    let l:tab_buffers = tabpagebuflist()
    for l:bufnr in l:tab_buffers
        if getbufvar(l:bufnr, 'is_markbar')
            return v:true
        endif
    endfor
    return v:false
endfunction
let s:MarkbarView.markbarIsOpenCurrentTab = function('markbar#MarkbarView#markbarIsOpenCurrentTab')

" RETURNS:  (v:t_list)      A list of buffer numbers corresponding to all
"                           markbar buffers open in the current tab.
function! markbar#MarkbarView#getOpenMarkbars() abort dict
    let l:tab_buffers = tabpagebuflist()
    let l:markbar_buffers = []
    for l:bufnr in l:tab_buffers
        if getbufvar(l:bufnr, 'is_markbar')
            call add(l:markbar_buffers, l:bufnr)
        endif
    endfor
    return l:markbar_buffers
endfunction
let s:MarkbarView.getOpenMarkbars = function('markbar#MarkbarView#getOpenMarkbars')

" RETURNS:  (v:t_number)    |bufnr| of the markbar buffer.
" DETAILS:  Creates a markbar buffer if one does not yet exist.
function! markbar#MarkbarView#getMarkbarBuffer() abort dict
    if !bufexists(l:self._markbar_buffer)
        let l:bufname = markbar#settings#MarkbarBufferName()
        " escape special characters and create new
        let l:bufnr = bufnr(escape(l:bufname, '~*.$[]'), 1)
        let l:self._markbar_buffer = l:bufnr
        call l:self._setMarkbarBufferSettings(l:bufnr)
    endif
    return l:self._markbar_buffer
endfunction
let s:MarkbarView.getMarkbarBuffer = function('markbar#MarkbarView#getMarkbarBuffer')

" RETURNS:  (v:t_number)    The window ID of the 'markbar buffer', or -1 if
"                           the window doesn't exist in the current tab page.
" DETAILS:  Creates a markbar buffer if one does not yet exist.
function! markbar#MarkbarView#getMarkbarWinID() abort dict
    return bufwinid(l:self.getMarkbarBuffer())
endfunction
let s:MarkbarView.getMarkbarWinID = function('markbar#MarkbarView#getMarkbarWinID')

" BRIEF:    Move cursor to the start of the given line in the current buffer.
" PARAM:    line    (v:t_number)    The target line number.
function! markbar#MarkbarView#_moveCursorToLine(line) abort dict
    execute 'silent normal! ' . a:line . 'G0'
endfunction
let s:MarkbarView._moveCursorToLine = function('markbar#MarkbarView#_moveCursorToLine')

" BRIEF:    Jump to the currently selected mark
" DETAILS:  Requires that the window containing the most recent active buffer
"           still be open in the current tab.
" PARAM:    goto_exact  (v:t_bool)  Whether to go to the line *and column* of
"                                   the selected mark (`v:true`) or just the
"                                   line (`v:false`).
function! markbar#MarkbarView#goToSelectedMark(goto_exact) abort dict
    let l:selected_mark = l:self.getCurrentMarkHeading()
    if !len(l:selected_mark)
        return
    endif
    call l:self.goToMark(l:selected_mark, a:goto_exact)
endfunction
let s:MarkbarView.goToSelectedMark = function('markbar#MarkbarView#goToSelectedMark')

" BRIEF:    Jump to the the mark given.
" DETAILS:  Requires that the window containing the most recent active buffer
"           still be open in the current tab.
" PARAM:    mark_char   (v:t_string)    The mark to jump to.
" PARAM:    goto_exact  (v:t_bool)  Whether to go to the line *and column* of
"                                   the selected mark (`v:true`) or just the
"                                   line (`v:false`).
function! markbar#MarkbarView#goToMark(mark_char, goto_exact) abort dict
    call markbar#ensure#IsMarkChar(a:mark_char)
    let l:active_buffer = l:self._markbar_model.getActiveBuffer()
    let l:mark_is_quote = a:mark_char ==# "'" || a:mark_char ==# '`'

    " save the 'correct' position of the [''] mark
    if l:mark_is_quote
        " note that ['`] isn't actually stored as a distinct mark
        try
            let l:targ_mark = deepcopy(
                \ l:self._markbar_model.getMarkData("'")
            \ )
            let l:mark_line = l:targ_mark.getLineNo()
            let l:mark_col  = l:targ_mark.getColumnNo()
        catch /mark not found in cache/
            call markbar#MarkbarView#MarkNotSet(a:mark_char)
            return
        endtry
    endif

    " if possible, return to the last active window
    call win_gotoid(l:self._cur_winid)
    " if last active window was closed somehow after the markbar opened, then
    " the mark will be opened in the markbar window

    let l:jump_command = 'normal! ' . (a:goto_exact ? '`' : "'")

    try
        if l:mark_is_quote
            " clobber the erroneous ['']/['`] mark position
            " set by the jump from the markbar
            call setpos( "''", [l:active_buffer, l:mark_line, l:mark_col, 0 ])
        endif
        execute l:jump_command . a:mark_char
        if a:mark_char ==# "'"
            normal! ^
        endif
    catch /E20/
        " Mark not set
        execute bufwinnr(l:self._markbar_buffer) . 'wincmd w'
        call markbar#MarkbarView#MarkNotSet(a:mark_char)
        return
    endtry

    if markbar#settings#foldopen()
        normal! zv
    endif

    if markbar#settings#CloseAfterGoTo()
        " close the markbar, but don't _restoreWinState, which could move the
        " cursor away from the mark that we just jumped to
        call l:self._closeMarkbar()
    endif
endfunction
let s:MarkbarView.goToMark = function('markbar#MarkbarView#goToMark')

" BRIEF:    Move the cursor to the line of the given mark in the markbar.
" DETAILS:  Prints an error message if the given mark could not be found.
function! markbar#MarkbarView#selectMark(mark) abort dict
    let l:line_no = l:self._getSpecificMarkHeadingLine(a:mark)
    if !l:line_no
        echohl WarningMsg
        echomsg 'Mark not in markbar: ' . a:mark
        echohl None
        return
    endif
    call l:self._moveCursorToLine(l:line_no)
endfunction
let s:MarkbarView.selectMark = function('markbar#MarkbarView#selectMark')

" BRIEF:    Move the cursor to the section heading of the next mark.
" PARAM:    count   (v:t_number)    Move forward this many headings. Defaults
"                                   to 1.
function! markbar#MarkbarView#cycleToNextMark(...) abort dict
    let l:count = get(a:, 1, 1)
    if l:count <=# 0
        throw printf('Bad count: %s', l:count)
    endif
    let l:i = 0
    while l:i <# l:count
        call l:self._moveCursorToLine(l:self._getNextMarkHeadingLine())
        let l:i += 1
    endwhile
endfunction
let s:MarkbarView.cycleToNextMark = function('markbar#MarkbarView#cycleToNextMark')

" BRIEF:    Move the cursor to the section heading of the previous mark.
" PARAM:    count   (v:t_number)    Move back this many headings. Defaults to 1.
function! markbar#MarkbarView#cycleToPreviousMark(...) abort dict
    let l:count = get(a:, 1, 1)
    if l:count <=# 0
        throw printf('Bad count: %s', l:count)
    endif
    let l:i = 0
    while l:i <# l:count
        call l:self._moveCursorToLine(l:self._getPreviousMarkHeadingLine())
        let l:i += 1
    endwhile
endfunction
let s:MarkbarView.cycleToPreviousMark = function('markbar#MarkbarView#cycleToPreviousMark')

" RETURNS:  (v:t_string)    The 'currently selected' mark, or an empty string
"                           if no mark is selected.
function! markbar#MarkbarView#getCurrentMarkHeading() abort dict
    return getline(l:self.getCurrentMarkHeadingLine())[2]
endfunction
let s:MarkbarView.getCurrentMarkHeading = function('markbar#MarkbarView#getCurrentMarkHeading')

" RETURNS:  (v:t_number)    The line number of the 'currently selected' mark.
function! markbar#MarkbarView#getCurrentMarkHeadingLine() abort dict
    let l:cur_heading_no = search(
        \ markbar#constants#MARK_HEADING_SEARCH_PATTERN(), 'bnc', 1)
    return l:cur_heading_no
endfunction
let s:MarkbarView.getCurrentMarkHeadingLine = function('markbar#MarkbarView#getCurrentMarkHeadingLine')

" RETURNS:  (v:t_number)    The line number of the mark heading below the
"                           'currently selected' mark.
function! markbar#MarkbarView#_getNextMarkHeadingLine() abort dict
    let l:cur_heading_no = search(
        \ markbar#constants#MARK_HEADING_SEARCH_PATTERN(), 'n', 0)
    return l:cur_heading_no
endfunction
let s:MarkbarView._getNextMarkHeadingLine = function('markbar#MarkbarView#_getNextMarkHeadingLine')

" RETURNS:  (v:t_number)    The line number of the mark heading above the
"                           'currently selected' mark.
function! markbar#MarkbarView#_getPreviousMarkHeadingLine() abort dict
    let l:searched_from_line = getcurpos()[1]
    " if the cursor is on a mark header, but right of column 0, then search
    " will return the current line; skip the match if that happens
    let l:cur_heading_no = search(
        \ markbar#constants#MARK_HEADING_SEARCH_PATTERN(), 'bn', 0)
    return l:cur_heading_no
endfunction
let s:MarkbarView._getPreviousMarkHeadingLine = function('markbar#MarkbarView#_getPreviousMarkHeadingLine')

" RETURNS:  (v:t_number)    The line number of the heading corresponding to
"                           the requested mark, if it exists; 0, otherwise.
function! markbar#MarkbarView#_getSpecificMarkHeadingLine(mark) abort dict
    let l:heading_no = search(
        \ markbar#constants#MARK_SPECIFIC_HEADING_SEARCH_PATTERN(a:mark),
        \ 'bnc', 0)
    return l:heading_no
endfunction
let s:MarkbarView._getSpecificMarkHeadingLine = function('markbar#MarkbarView#_getSpecificMarkHeadingLine')

" BRIEF:    Set buffer-local settings for the given markbar buffer.
function! markbar#MarkbarView#_setMarkbarBufferSettings(buffer_expr) abort dict
    if !bufexists(a:buffer_expr)
        throw printf('Buffer does not exist: %s', a:buffer_expr)
    endif

    " has no effect?
    " call setbufvar(a:buffer_expr,      '&buflisted',         0)
    call setbufvar(a:buffer_expr,       '&buftype',  'nofile')
    call setbufvar(a:buffer_expr,     '&bufhidden',    'hide')
    call setbufvar(a:buffer_expr,      '&swapfile',         0)
    call setbufvar(a:buffer_expr,      '&filetype', 'markbar')
    call setbufvar(a:buffer_expr,        '&syntax', 'markbar')
    call setbufvar(a:buffer_expr,  '&conceallevel',         3)
    call setbufvar(a:buffer_expr, '&concealcursor',       'n')

    call setbufvar(a:buffer_expr,      'is_markbar',         1)
endfunction
let s:MarkbarView._setMarkbarBufferSettings = function('markbar#MarkbarView#_setMarkbarBufferSettings')

" EFFECTS:  Set window-local settings for the given markbar buffer.
function! markbar#MarkbarView#_setMarkbarWindowSettings(buffer_expr) abort dict
    if !bufexists(a:buffer_expr)
        throw printf('Buffer does not exist: %s', a:buffer_expr)
    endif
    let l:winnr = bufwinnr(a:buffer_expr)
    if l:winnr ==# -1
        throw printf('Window does not exist for: %s', a:buffer_expr)
    endif

    call setwinvar(l:winnr,    '&winfixwidth',         1)
    call setwinvar(l:winnr,   '&winfixheight',         1)
    call setwinvar(l:winnr,     '&cursorline',         1)
    call setwinvar(l:winnr,     '&foldcolumn',         0)
    call setwinvar(l:winnr,     '&signcolumn',      'no')
    call setwinvar(l:winnr, '&relativenumber',         0)
    call setwinvar(l:winnr,         '&number',         0)
    call setwinvar(l:winnr,           '&wrap',         0)
    call setwinvar(l:winnr,          '&spell',         0)

    call setwinvar(l:winnr,      'is_markbar',         1)
endfunction
let s:MarkbarView._setMarkbarWindowSettings = function('markbar#MarkbarView#_setMarkbarWindowSettings')

" BRIEF:    Save the current window number and window state.
" DETAILS:  If the current window is a markbar window, throw an exception.
function! markbar#MarkbarView#_saveWinState() abort dict
    if exists('b:is_markbar')  " we're inside a markbar window
      throw 'Tried to save winstate from inside markbar!'
    endif
    let l:self._cur_winid = win_getid()
    let l:self._saved_view = winsaveview()
    let l:self._win_resize_cmd = winrestcmd()
    let l:self._saved_num_win = winnr('$')
    let l:self._saved_tabpage_nr = tabpagenr()
endfunction
let s:MarkbarView._saveWinState = function('markbar#MarkbarView#_saveWinState')

" BRIEF:    Restore the last-saved window state, if it exists and is valid.
" DETAILS:  Returns the cursor to the saved window number, restores the old
"           view, and resizes all windows to their previously saved sizes.
"           Only works if markbar is on the same tabpage, and the windows on
"           the screen are the same as they were during the last call to
"           `_saveWinState`.
function! markbar#MarkbarView#_restoreWinState() abort dict
    if tabpagenr() !=# l:self._saved_tabpage_nr
        return
    elseif winnr('$') !=# l:self._saved_num_win
        " new non-markbar windows were opened or closed
        return
    endif
    if l:self._cur_winid <# 1 || empty(l:self._saved_view)
            \ || empty(l:self._win_resize_cmd)
        throw 'Did not properly save window state before this call. (FAILURE)'
    endif
    call win_gotoid(l:self._cur_winid)
    execute l:self._win_resize_cmd
    call winrestview(l:self._saved_view)
endfunction
let s:MarkbarView._restoreWinState = function('markbar#MarkbarView#_restoreWinState')
