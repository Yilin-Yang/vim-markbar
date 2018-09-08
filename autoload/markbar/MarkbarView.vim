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
        \ '_markbar_buffer': -1,
        \ '_show_verbose_help': v:false,
    \ }
    " TODO: markbar buffer window id?
    let l:new['openMarkbar']                 = function('markbar#MarkbarView#openMarkbar')
    let l:new['_openMarkbarSplit']           = function('markbar#MarkbarView#_openMarkbarSplit')
    let l:new['closeMarkbar']                = function('markbar#MarkbarView#closeMarkbar')
    let l:new['toggleShowHelp']              = function('markbar#MarkbarView#toggleShowHelp')
    let l:new['markbarIsOpenCurrentTab']     = function('markbar#MarkbarView#markbarIsOpenCurrentTab')
    let l:new['getOpenMarkbars']             = function('markbar#MarkbarView#getOpenMarkbars')
    let l:new['getMarkbarBuffer']            = function('markbar#MarkbarView#getMarkbarBuffer')
    let l:new['getMarkbarWindow']            = function('markbar#MarkbarView#getMarkbarWindow')
    let l:new['getShouldShowHelp']           = function('markbar#MarkbarView#getShouldShowHelp')
    let l:new['_moveCursorToLine']           = function('markbar#MarkbarView#_moveCursorToLine')
    let l:new['_goToMark']                   = function('markbar#MarkbarView#_goToMark')
    let l:new['_cycleToNextMark']            = function('markbar#MarkbarView#_cycleToNextMark')
    let l:new['_cycleToPreviousMark']        = function('markbar#MarkbarView#_cycleToPreviousMark')
    let l:new['_getCurrentMarkHeading']      = function('markbar#MarkbarView#_getCurrentMarkHeading')
    let l:new['_getCurrentMarkHeadingLine']  = function('markbar#MarkbarView#_getCurrentMarkHeadingLine')
    let l:new['_getNextMarkHeadingLine']     = function('markbar#MarkbarView#_getNextMarkHeadingLine')
    let l:new['_getPreviousMarkHeadingLine'] = function('markbar#MarkbarView#_getPreviousMarkHeadingLine')
    let l:new['_setMarkbarBufferSettings']   = function('markbar#MarkbarView#_setMarkbarBufferSettings')
    let l:new['_setMarkbarWindowSettings']   = function('markbar#MarkbarView#_setMarkbarWindowSettings')

    return l:new
endfunction

function! markbar#MarkbarView#AssertIsMarkbarView(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'MarkbarView'
        throw '(markbar#MarkbarView) Object is not of type MarkbarView: ' . a:object
    endif
endfunction

" BRIEF:    Open a markbar window for the currently active buffer.
" DETAILS:  Does nothing if a markbar is already open.
function! markbar#MarkbarView#openMarkbar() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:markbar_buffer = l:self.getMarkbarBuffer()
    let l:markbar_window = l:self.getMarkbarWindow()
    if l:markbar_window ==# -1
        call l:self._openMarkbarSplit(l:markbar_buffer)
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
"                                       split. If none is provided, a new
"                                       buffer will be created.
" RETURNS:  (v:t_number)    The buffer number of the opened markbar.
function! markbar#MarkbarView#_openMarkbarSplit(...) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let a:markbar = get(a:, 1, '')

    let l:position = markbar#settings#OpenPosition() . ' '
    let l:orientation =
        \ markbar#settings#MarkbarOpenVertical() ?
            \ 'vertical ' : ' '
    let l:size =
        \ markbar#settings#MarkbarOpenVertical() ?
            \ markbar#settings#MarkbarWidth() : markbar#settings#MarkbarHeight()
    let l:command = empty(a:markbar) ? 'new ' : 'split #' . a:markbar

    try
        execute 'keepalt silent ' . l:position . l:orientation . l:size . l:command
    catch /E499/
        execute 'keepalt silent ' . l:position . l:orientation . l:size
            \ . 'split | buffer! ' . a:markbar
    endtry

    let l:new_markbar = empty(a:markbar) ? bufnr('%') : a:markbar
    call l:self._setMarkbarBufferSettings(l:new_markbar)

    return l:new_markbar
endfunction

" BRIEF:    Close any markbars open for the active buffer in the current tab.
" RETURNS:  (v:t_bool)      `v:true` if a markbar was actually closed,
"                           `v:false` otherwise.
function! markbar#MarkbarView#closeMarkbar() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:markbar_buffers = l:self.getOpenMarkbars()
    if empty(l:markbar_buffers) | return v:false | endif
    for l:markbar in l:markbar_buffers
        execute bufwinnr(l:markbar) . 'close'
    endfor
    return v:true
endfunction

" BRIEF:    Toggle the visibility of verbose help in the markbar.
" DETAILS:  Won't take effect until the markbar has been repopulated.
function! markbar#MarkbarView#toggleShowHelp() abort dict
    call markbar#MarkbarModel#AssertIsMarkbarModel(l:self)
    let l:self['_show_verbose_help'] = !l:self['_show_verbose_help']
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
" DETAILS:  Creates a markbar buffer for the MarkbarState object if one does
"           not yet exist.
function! markbar#MarkbarView#getMarkbarBuffer() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    if !bufexists(l:self['_markbar_buffer'])
        let l:bufname = markbar#settings#MarkbarBufferName()
        execute 'badd ' . l:bufname
        let l:bufnr = bufnr(
            \ escape(l:bufname, '~*.$[]')
        \ )
        let l:self['_markbar_buffer'] = l:bufnr
        call l:self._setMarkbarBufferSettings(l:bufnr)
    endif
    return l:self['_markbar_buffer']
endfunction

" RETURNS:  (v:t_number)    The window ID of the 'markbar buffer', or -1 if
"                           the window doesn't exist in the current tab page.
" DETAILS:  Creates a markbar buffer for the MarkbarState object if one does
"           not yet exist.
function! markbar#MarkbarView#getMarkbarWindow() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:markbar_buffer = l:self.getMarkbarBuffer()
    return bufwinnr(l:markbar_buffer)
endfunction

" RETURNS:  (v:t_bool)  Whether or not to show verbose help in the markbar.
function! markbar#MarkbarView#getShouldShowHelp() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    return l:self['_show_verbose_help']
endfunction

" BRIEF:    Move the cursor to the given line number in the current buffer.
" PARAM:    line    (v:t_number)    The target line number.
function! markbar#MarkbarView#_moveCursorToLine(line) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    execute 'silent normal! ' . a:line . 'G'
endfunction

" BRIEF:    Jump to the currently selected mark.
" DETAILS:  Requires that the window containing the most recent active buffer
"           still be open in the current tab.
function! markbar#MarkbarView#_goToMark() abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let l:selected_mark = l:self._getCurrentMarkHeading()
    if !len(l:selected_mark) | return | endif

    let l:active_buffer = l:self['_markbar_model'].getActiveBuffer()
    execute bufwinnr(l:active_buffer) . 'wincmd w'
    let l:jump_command = 'normal! '
    let l:jump_command .= markbar#settings#JumpToExactPosition() ? '`' : "'"
    execute l:jump_command . l:selected_mark

    if markbar#settings#CloseAfterGoTo()
        call l:self.closeMarkbar()
    endif
endfunction

" BRIEF:    Move the cursor to the section heading of the next mark.
" PARAM:    count   (v:t_number)    Move forward this many headings. Defaults
"                                   to 1.
function! markbar#MarkbarView#_cycleToNextMark(...) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    let a:count = get(a:, 1, 1)
    if a:count <=# 0 | throw '(MarkbarView#_cycleToNextMark) Bad count: ' . a:count | endif
    let l:count = a:count + 0
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
    let a:count = get(a:, 1, 1)
    if a:count <=# 0 | throw '(MarkbarView#_cycleToPreviousMark) Bad count: ' . a:count | endif
    let l:count = a:count + 0
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

" BRIEF:    Set buffer-local settings for the given markbar buffer.
function! markbar#MarkbarView#_setMarkbarBufferSettings(buffer_expr) abort dict
    call markbar#MarkbarView#AssertIsMarkbarView(l:self)
    if !bufexists(a:buffer_expr)
        throw '(MarkbarView#_setMarkbarBufferSettings) Buffer does not exist: ' . a:buffer_expr
    endif

    " has no effect?
    " call setbufvar(a:buffer_expr,      '&buflisted',         0)
    call setbufvar(a:buffer_expr,        '&buftype',  'nofile')
    call setbufvar(a:buffer_expr,      '&bufhidden',    'hide')
    call setbufvar(a:buffer_expr,       '&swapfile',         0)
    call setbufvar(a:buffer_expr,       '&filetype', 'markbar')
    call setbufvar(a:buffer_expr,         '&syntax', 'markbar')

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
