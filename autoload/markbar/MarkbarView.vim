" BRIEF:    The user's View into the markbar state.
" DETAILS:  MarkbarView manipulates the components of vim-markbar's interface
"           that the user can see. It also stores information about these
"           visible components, and how the user is interacting with these
"           components.

" BRIEF:    Construct a MarkbarView object.
" PARAM:    model   (markbar#MarkbarModel)  Reference to stored information
"                                           about the markbar state.
function! markbar#MarkbarView#new(model) abort
    call markbar#MarkbarModel#AssertIsMarkbarModel(a:model)
    let l:new = {
        \ 'TYPE': 'MarkbarView',
        \ '_markbar_model': a:model,
        \ '_markbar_buffer': -2,
        \ '_cur_winnr': 1,
        \ '_saved_view': {},
        \ '_win_resize_cmd:': '',
        \ '_saved_num_win': -1,
        \ '_saved_tabpage_nr': -1,
        \ '_show_verbose_help': v:false,
    \ }
    " TODO: markbar buffer window id?
    let l:new.openMarkbar                 = function('markbar#MarkbarView#openMarkbar')
    let l:new._openMarkbarSplit           = function('markbar#MarkbarView#_openMarkbarSplit')
    let l:new.closeMarkbar                = function('markbar#MarkbarView#closeMarkbar')
    let l:new.toggleShowHelp              = function('markbar#MarkbarView#toggleShowHelp')
    let l:new.markbarIsOpenCurrentTab     = function('markbar#MarkbarView#markbarIsOpenCurrentTab')
    let l:new.getOpenMarkbars             = function('markbar#MarkbarView#getOpenMarkbars')
    let l:new.getMarkbarBuffer            = function('markbar#MarkbarView#getMarkbarBuffer')
    let l:new.getMarkbarWindow            = function('markbar#MarkbarView#getMarkbarWindow')
    let l:new.getShouldShowHelp           = function('markbar#MarkbarView#getShouldShowHelp')
    let l:new._moveCursorToLine           = function('markbar#MarkbarView#_moveCursorToLine')
    let l:new._goToSelectedMark           = function('markbar#MarkbarView#_goToSelectedMark')
    let l:new._goToMark                   = function('markbar#MarkbarView#_goToMark')
    let l:new._selectMark                 = function('markbar#MarkbarView#_selectMark')
    let l:new._cycleToNextMark            = function('markbar#MarkbarView#_cycleToNextMark')
    let l:new._cycleToPreviousMark        = function('markbar#MarkbarView#_cycleToPreviousMark')
    let l:new._getCurrentMarkHeading      = function('markbar#MarkbarView#_getCurrentMarkHeading')
    let l:new._getCurrentMarkHeadingLine  = function('markbar#MarkbarView#_getCurrentMarkHeadingLine')
    let l:new._getNextMarkHeadingLine     = function('markbar#MarkbarView#_getNextMarkHeadingLine')
    let l:new._getPreviousMarkHeadingLine = function('markbar#MarkbarView#_getPreviousMarkHeadingLine')
    let l:new._getSpecificMarkHeadingLine = function('markbar#MarkbarView#_getSpecificMarkHeadingLine')
    let l:new._setMarkbarBufferSettings   = function('markbar#MarkbarView#_setMarkbarBufferSettings')
    let l:new._setMarkbarWindowSettings   = function('markbar#MarkbarView#_setMarkbarWindowSettings')
    let l:new._saveWinState               = function('markbar#MarkbarView#_saveWinState')
    let l:new._restoreWinState            = function('markbar#MarkbarView#_restoreWinState')

    return l:new
endfunction

function! markbar#MarkbarView#AssertIsMarkbarView(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'MarkbarView'
        throw '(markbar#MarkbarView) Object is not of type MarkbarView: ' . a:object
    endif
endfunction

function! markbar#MarkbarView#MarkNotSet(mark) abort
    echohl WarningMsg
    echomsg 'Mark not set: '.a:mark.' (Press any key to continue.)'
    echohl None
    call getchar() " pause until user hits a key
endfunction

" BRIEF:    Open a markbar window for the currently active buffer.
" DETAILS:  - Saves the window state.
"           - Does nothing if a markbar is already open.
" PARAM:    open_position   (v:t_string)    The position modifier to apply to
"                                           the opened markbar. See
"                                           `:h topleft`, `:h botright`.
" PARAM:    open_vertical   (v:t_bool)  `v:true` if the markbar should be a
"                                       vertical split, `v:false` otherwise.
" PARAM:    size    (v:t_number)    The width of the markbar in columns if
"                                   opened in a vertical split; the height of
"                                   the markbar in lines, otherwise.
function! markbar#MarkbarView#openMarkbar(
    \ open_position,
    \ open_vertical,
    \ size
\ ) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    if !exists('b:is_markbar')
        " only save the window state if we aren't already in the markbar
        call l:self._saveWinState()
    endif
    let l:markbar_buffer = l:self.getMarkbarBuffer()
    let l:markbar_window = l:self.getMarkbarWindow()
    if l:markbar_window ==# -1
        call l:self._openMarkbarSplit(
            \ l:markbar_buffer,
            \ a:open_position,
            \ a:open_vertical,
            \ a:size
        \ )
        call setbufvar(l:markbar_buffer, '&buflisted', 0)
    else
        " switch to existing markbar window
        execute l:markbar_window . 'wincmd w'
    endif
    call l:self._setMarkbarWindowSettings(l:markbar_buffer)
endfunction

" BRIEF:    Open a vsplit for a markbar and set settings, if appropriate.
" DETAILS:  Moves the cursor to the newly-opened split.
" PARAM:    markbar     (v:t_number)    The buffer number to be opened in the
"                                       newly created split.
function! markbar#MarkbarView#_openMarkbarSplit(
    \ markbar,
    \ position,
    \ open_vertical,
    \ size
\ ) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)

    let l:position    = a:position . ' '
    let l:orientation = a:open_vertical ? 'vertical ' : ' '
    let l:size        = a:size

    execute 'keepalt silent ' . l:position . l:orientation . l:size
        \ . 'split | buffer! ' . a:markbar

    call l:self._setMarkbarBufferSettings(a:markbar)

    return a:markbar
endfunction

" BRIEF:    Close any markbars open for the active buffer in the current tab.
" RETURNS:  (v:t_bool)      `v:true` if a markbar was actually closed,
"                           `v:false` otherwise.
" PARAM:    restore_view    (v:t_bool)  Whether to try to restore the previous
"                                       stored window view after closing.
function! markbar#MarkbarView#closeMarkbar(...) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:restore_view = get(a:000, 0, 0)
    let l:markbar_buffers = l:self.getOpenMarkbars()
    if empty(l:markbar_buffers) | return v:false | endif
    for l:markbar in l:markbar_buffers
        execute bufwinnr(l:markbar) . 'close'
    endfor
    if l:restore_view
        call l:self._restoreWinState(1)
    endif
    return v:true
endfunction

" BRIEF:    Toggle the visibility of verbose help in the markbar.
" DETAILS:  Won't take effect until the markbar has been repopulated.
function! markbar#MarkbarView#toggleShowHelp() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:self._show_verbose_help = !l:self._show_verbose_help
endfunction

" RETURNS:  (v:t_bool)  `v:true` if a markbar window is open in the current tab.
function! markbar#MarkbarView#markbarIsOpenCurrentTab() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:tab_buffers = tabpagebuflist()
    for l:bufnr in l:tab_buffers
        if getbufvar(l:bufnr, 'is_markbar')
            return v:true
        endif
    endfor
    return v:false
endfunction

" RETURNS:  (v:t_list)      A list of buffer numbers corresponding to all
"                           markbar buffers open in the current tab.
function! markbar#MarkbarView#getOpenMarkbars() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:tab_buffers = tabpagebuflist()
    let l:markbar_buffers = []
    for l:bufnr in l:tab_buffers
        if getbufvar(l:bufnr, 'is_markbar')
            let l:markbar_buffers += [l:bufnr]
        endif
    endfor
    return l:markbar_buffers
endfunction

" RETURNS:  (v:t_number)    The buffer number of the 'markbar buffer.'
" DETAILS:  Creates a markbar buffer if one does not yet exist.
function! markbar#MarkbarView#getMarkbarBuffer() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    if !bufexists(l:self._markbar_buffer)
        let l:bufname = markbar#settings#MarkbarBufferName()
        " escape special characters and create new
        let l:bufnr = bufnr(escape(l:bufname, '~*.$[]'), 1)
        let l:self._markbar_buffer = l:bufnr
        call l:self._setMarkbarBufferSettings(l:bufnr)
    endif
    return l:self._markbar_buffer
endfunction

" RETURNS:  (v:t_number)    The window ID of the 'markbar buffer', or -1 if
"                           the window doesn't exist in the current tab page.
" DETAILS:  Creates a markbar buffer if one does not yet exist.
function! markbar#MarkbarView#getMarkbarWindow() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:markbar_buffer = l:self.getMarkbarBuffer()
    return bufwinnr(l:markbar_buffer)
endfunction

" RETURNS:  (v:t_bool)  Whether or not to show verbose help in the markbar.
function! markbar#MarkbarView#getShouldShowHelp() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    return l:self._show_verbose_help
endfunction

" BRIEF:    Move the cursor to the given line number in the current buffer.
" PARAM:    line    (v:t_number)    The target line number.
function! markbar#MarkbarView#_moveCursorToLine(line) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    execute 'silent normal! ' . a:line . 'G'
endfunction

" BRIEF:    Jump to the currently selected mark
" DETAILS:  Requires that the window containing the most recent active buffer
"           still be open in the current tab.
" PARAM:    goto_exact  (v:t_bool)  Whether to go to the line *and column* of
"                                   the selected mark (`v:true`) or just the
"                                   line (`v:false`).
function! markbar#MarkbarView#_goToSelectedMark(goto_exact) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:selected_mark = l:self._getCurrentMarkHeading()
    if !len(l:selected_mark) | return | endif
    call l:self._goToMark(l:selected_mark, a:goto_exact)
endfunction

" BRIEF:    Jump to the the mark given.
" DETAILS:  Requires that the window containing the most recent active buffer
"           still be open in the current tab.
" PARAM:    mark    (v:t_string)    The mark to jump to.
" PARAM:    goto_exact  (v:t_bool)  Whether to go to the line *and column* of
"                                   the selected mark (`v:true`) or just the
"                                   line (`v:false`).
function! markbar#MarkbarView#_goToMark(mark, goto_exact) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)

    let l:active_buffer = l:self._markbar_model.getActiveBuffer()
    let l:mark_is_quote = a:mark ==# "'" || a:mark ==# '`'

    " save the 'correct' position of the [''] mark
    if l:mark_is_quote
        " note that ['`] isn't actually stored as a distinct mark
        try
            let l:targ_mark = deepcopy(
                \ l:self._markbar_model
                    \.getBufferCache(l:active_buffer)
                    \.getMark("'")
            \ )
            let l:mark_line = l:targ_mark.getLineNo()
            let l:mark_col  = l:targ_mark.getColumnNo() + 1
        catch /mark not found in cache/
            call markbar#MarkbarView#MarkNotSet(a:mark)
            return
        endtry
    endif

    " try to return to the user's old window, if possible
    if l:self._cur_winnr ># 0 && l:self._cur_winnr <=# winnr('$')
        " the saved previous window number is still valid
        execute l:self._cur_winnr . 'wincmd w'
    else
        " switch to a window that has this buffer open
        execute bufwinnr(l:active_buffer) . 'wincmd w'
    endif
    let l:jump_command = 'normal! '
    let l:jump_command .= a:goto_exact ? '`' : "'"

    try
        if l:mark_is_quote
            " clobber the erroneous ['']/['`] mark position
            " set by the jump from the markbar
            call setpos( "''", [l:active_buffer, l:mark_line, l:mark_col, 0 ])
        endif
        execute l:jump_command . a:mark
        if a:mark ==# "'"
            normal! ^
        endif
    catch /E20/
        " Mark not set
        execute bufwinnr(l:self._markbar_buffer) . 'wincmd w'
        call markbar#MarkbarView#MarkNotSet(a:mark)
        return
    endtry

    if markbar#settings#foldopen()
        normal! zv
    endif

    if markbar#settings#CloseAfterGoTo()
        call l:self.closeMarkbar()
    endif
endfunction

" BRIEF:    Move the cursor to the line of the given mark in the markbar.
" DETAILS:  Prints an error message if the given mark could not be found.
function! markbar#MarkbarView#_selectMark(mark) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:line_no = l:self._getSpecificMarkHeadingLine(a:mark)
    if !l:line_no
        echohl WarningMsg
        echomsg 'Mark not in markbar: ' . a:mark
        echomsg 'Press any key to continue.'
        echohl None
        call getchar() " pause until user hits a key
        return
    endif
    call l:self._moveCursorToLine(l:line_no)
endfunction

" BRIEF:    Move the cursor to the section heading of the next mark.
" PARAM:    count   (v:t_number)    Move forward this many headings. Defaults
"                                   to 1.
function! markbar#MarkbarView#_cycleToNextMark(...) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:count = get(a:, 1, 1)
    if l:count <=# 0 | throw '(MarkbarView#_cycleToNextMark) Bad count: ' . l:count | endif
    let l:i = 0
    while l:i <# l:count
        call l:self._moveCursorToLine(l:self._getNextMarkHeadingLine())
        let l:i += 1
    endwhile
endfunction

" BRIEF:    Move the cursor to the section heading of the previous mark.
" PARAM:    count   (v:t_number)    Move back this many headings. Defaults to 1.
function! markbar#MarkbarView#_cycleToPreviousMark(...) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:count = get(a:, 1, 1)
    if l:count <=# 0 | throw '(MarkbarView#_cycleToPreviousMark) Bad count: ' . l:count | endif
    let l:i = 0
    while l:i <# l:count
        call l:self._moveCursorToLine(l:self._getPreviousMarkHeadingLine())
        let l:i += 1
    endwhile
endfunction

" RETURNS:  (v:t_string)    The 'currently selected' mark, or an empty string
"                           if no mark is selected.
function! markbar#MarkbarView#_getCurrentMarkHeading() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    return getline(l:self._getCurrentMarkHeadingLine())[2]
endfunction

" RETURNS:  (v:t_number)    The line number of the 'currently selected' mark.
function! markbar#MarkbarView#_getCurrentMarkHeadingLine() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:cur_heading_no = search(
        \ markbar#constants#MARK_HEADING_SEARCH_PATTERN(),
        \ 'bnc',
        \ 1
    \ )
    return l:cur_heading_no
endfunction

" RETURNS:  (v:t_number)    The line number of the mark heading below the
"                           'currently selected' mark.
function! markbar#MarkbarView#_getNextMarkHeadingLine() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:cur_heading_no = search(
        \ markbar#constants#MARK_HEADING_SEARCH_PATTERN(),
        \ 'n',
        \ 0
    \ )
    return l:cur_heading_no
endfunction

" RETURNS:  (v:t_number)    The line number of the mark heading below the
"                           'currently selected' mark.
function! markbar#MarkbarView#_getPreviousMarkHeadingLine() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:cur_heading_no = search(
        \ markbar#constants#MARK_HEADING_SEARCH_PATTERN(),
        \ 'bn',
        \ 0
    \ )
    return l:cur_heading_no
endfunction

" RETURNS:  (v:t_number)    The line number of the heading corresponding to
"                           the requested mark, if it exists; 0, otherwise.
function! markbar#MarkbarView#_getSpecificMarkHeadingLine(mark) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:heading_no = search(
        \ markbar#constants#MARK_SPECIFIC_HEADING_SEARCH_PATTERN(a:mark),
        \ 'bnc',
        \ 0
    \ )
    return l:heading_no
endfunction

" BRIEF:    Set buffer-local settings for the given markbar buffer.
function! markbar#MarkbarView#_setMarkbarBufferSettings(buffer_expr) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    if !bufexists(a:buffer_expr)
        throw '(MarkbarView#_setMarkbarBufferSettings) Buffer does not exist: ' . a:buffer_expr
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

" EFFECTS:  Set window-local settings for the given markbar buffer.
function! markbar#MarkbarView#_setMarkbarWindowSettings(buffer_expr) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    if !bufexists(a:buffer_expr)
        throw '(MarkbarView#_setMarkbarWindowSettings) Buffer does not exist: ' . a:buffer_expr
    endif
    let l:winnr = bufwinnr(a:buffer_expr)
    if l:winnr ==# -1
        throw '(MarkbarView#_setMarkbarWindowSettings) Window does not exist for: ' . a:buffer_expr
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

" BRIEF:    Save the current window number and window state.
" DETAILS:  If the current window is a markbar window, throw an exception.
function! markbar#MarkbarView#_saveWinState() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    if exists('b:is_markbar')  " we're inside a markbar window
      throw '(MarkbarView#_saveWinState) Tried to save winstate from '
          \ . 'inside markbar!'
    endif
    let l:self._cur_winnr = winnr()
    let l:self._saved_view = winsaveview()
    let l:self._win_resize_cmd = winrestcmd()
    let l:self._saved_num_win = winnr('$')
    let l:self._saved_tabpage_nr = tabpagenr()
endfunction

" BRIEF:    Restore the last-saved window state, if it exists and is valid.
" DETAILS:  Returns the cursor to the saved window number, restores the old
"           view, and resizes all windows to their previously saved sizes.
"           Only works if markbar is on the same tabpage, and the windows on
"           the screen are the same as they were during the last call to
"           `_saveWinState`.
function! markbar#MarkbarView#_restoreWinState(fail_silent) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    if tabpagenr() !=# l:self._saved_tabpage_nr
        if a:fail_silent
            return
        else
            throw '(MarkbarView#_restoreWinState) Current tabpage '
                \ . tabpagenr() . ' is different from saved: '
                \ . l:self._saved_tabpage_nr
        endif
    elseif winnr('$') !=# l:self._saved_num_win
        if a:fail_silent
            return
        else
            throw '(MarkbarView#_restoreWinState) Number of windows '
                \ . winnr('$') . ' is different from when winstate was saved: '
                \ . l:self._saved_num_win
        endif
    endif
    if l:self._cur_winnr <# 1 || empty(l:self._saved_view)
            \ || empty(l:self._win_resize_cmd)
        throw '(MarkbarView#_restoreWinState) Did not properly save window '
            \ . 'state before this call. (FAILURE)'
    endif
    execute l:self._cur_winnr . 'wincmd w'
    execute l:self._win_resize_cmd
    call winrestview(l:self._saved_view)
endfunction
