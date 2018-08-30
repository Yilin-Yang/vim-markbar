" EFFECTS:  Default-initialize a MarkbarState object.
" DETAILS:  MarkbarState stores cached information on buffers, as well as
"           the 'shared' buffer that appears when a user actually opens the
"           markbar. It provides an interface for updating those caches,
"           refreshing markbar buffers, and opening markbar buffers in
"           response to user commands.
function! markbar#MarkbarState#new() abort
    let l:new = {
        \ 'TYPE': 'MarkbarState',
        \ '_buffer_caches': {},
        \ '_active_buffer_stack':
            \ markbar#ConditionalStack#new(
                \ function('markbar#helpers#IsRealBuffer'),
                \ markbar#settings#MaximumActiveBufferHistory()
            \ ),
        \ '_markbar_buffer': -1
    \ }

    " opening/closing markbar
    let l:new['closeMarkbar'] =
        \ function('markbar#MarkbarState#closeMarkbar')
    let l:new['openMarkbar'] =
        \ function('markbar#MarkbarState#openMarkbar')
    let l:new['toggleMarkbar'] =
        \ function('markbar#MarkbarState#toggleMarkbar')

    " markbar ui observers, utility functions
    let l:new['getMarkbarContents'] =
        \ function('markbar#MarkbarState#getMarkbarContents')
    let l:new['getOpenMarkbars'] =
        \ function('markbar#MarkbarState#getOpenMarkbars')
    let l:new['markbarIsOpenCurrentTab'] =
        \ function('markbar#MarkbarState#markbarIsOpenCurrentTab')
    let l:new['populateWithMarkbar'] =
        \ function('markbar#MarkbarState#populateWithMarkbar')

    " active buffers
    let l:new['getActiveBuffer'] =
        \ function('markbar#MarkbarState#getActiveBuffer')
    let l:new['pushNewBuffer'] =
        \ function('markbar#MarkbarState#pushNewBuffer')

    " other observers
    let l:new['getMarkData'] =
        \ function('markbar#MarkbarState#getMarkData')
    let l:new['getMarkbarBuffer'] =
        \ function('markbar#MarkbarState#getMarkbarBuffer')

    " buffer mark caches
    let l:new['getBufferCache'] =
        \ function('markbar#MarkbarState#getBufferCache')
    let l:new['evictBufferCache'] =
        \ function('markbar#MarkbarState#evictBufferCache')
    let l:new['updateCurrentAndGlobal'] =
        \ function('markbar#MarkbarState#updateCurrentAndGlobal')

    return l:new
endfunction

function! markbar#MarkbarState#AssertIsMarkbarState(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'MarkbarState'
        throw '(markbar#MarkbarState) Object is not of type MarkbarState: ' . a:object
    endif
endfunction

" EFFECTS:  - Add a new BufferCache for the requested buffer, if one does not
"           yet exist.
" RETURNS:  (markbar#BufferCache)   The buffer cache for the requested buffer.
function! markbar#MarkbarState#getBufferCache(buffer_no) abort dict
    call markbar#MarkbarState#AssertIsMarkbarState(self)
    if !has_key(self['_buffer_caches'], a:buffer_no)
        let self['_buffer_caches'][a:buffer_no] =
            \ markbar#BufferCache#new(a:buffer_no)
    endif
    return self['_buffer_caches'][a:buffer_no]
endfunction

" EFFECTS:  - Update the BufferCache for the currently focused buffer.
"           - Update the BufferCache for global marks (filemarks, etc.)
function! markbar#MarkbarState#updateCurrentAndGlobal() abort dict
    call markbar#MarkbarState#AssertIsMarkbarState(self)
    let l:cur_buffer_cache    = self.getBufferCache(bufnr('%'))
    let l:global_buffer_cache = self.getBufferCache(markbar#constants#GLOBAL_MARKS())
    call    l:cur_buffer_cache.updateCache(markbar#helpers#GetLocalMarks())
    call l:global_buffer_cache.updateCache(markbar#helpers#GetGlobalMarks())
    call    l:cur_buffer_cache.updateContexts(markbar#settings#NumLinesContext())
    call l:global_buffer_cache.updateContexts(markbar#settings#NumLinesContext())
endfunction

" EFFECTS:  - Close any existing markbars.
"           - Create a markbar buffer for the currently active buffer if one
"           does not yet exist.
"           - Open this markbar buffer in a sidebar.
function! markbar#MarkbarState#openMarkbar() abort dict
    call markbar#MarkbarState#AssertIsMarkbarState(self)

    call self.updateCurrentAndGlobal()

    let l:markbar_buffer = self.getMarkbarBuffer()
    let l:markbar_window = bufwinnr(l:markbar_buffer)
    if l:markbar_window ==# -1
        call markbar#ui#OpenMarkbarSplit(self['_markbar_buffer'])
        call setbufvar(l:markbar_buffer, '&buflisted', 0)
    else
        " switch to existing markbar window
        execute l:markbar_window . 'wincmd w'
    endif
    call markbar#ui#SetMarkbarWindowSettings(l:markbar_buffer)

    let l:active_buffer = self['_active_buffer_stack'].top()
    call self.populateWithMarkbar(l:active_buffer, l:markbar_buffer)
endfunction

" EFFECTS:  Close the markbar that is open in the current tab page, if one
"           exists. Else, does nothing.
" RETURNS:  (v:t_bool)      `v:true` if a markbar was actually closed,
"                           `v:false` otherwise.
function! markbar#MarkbarState#closeMarkbar() abort dict
    call markbar#MarkbarState#AssertIsMarkbarState(self)
    let l:markbar_buffers = self.getOpenMarkbars()
    if empty(l:markbar_buffers) | return v:false | endif
    for l:markbar in l:markbar_buffers
        execute bufwinnr(l:markbar) . 'close'
    endfor
    return v:true
endfunction

" EFFECTS:  Close the currently open markbar, if one is open. If no markbar
"           is open, open a markbar for the active buffer.
function! markbar#MarkbarState#toggleMarkbar() abort dict
    call markbar#MarkbarState#AssertIsMarkbarState(self)
    if   self.closeMarkbar() | return | endif
    call self.openMarkbar()
endfunction

" REQUIRES: - `a:buffer_no` is not a markbar buffer.
"           - `a:buffer_no` is not the global buffer.
"           - `a:buffer_no` is a buffer *number.*
" EFFECTS:  - Return a list populated linewise with the requested marks
"           and those marks' contexts.
" PARAM:    marks   (v:t_string)    Every mark that the user wishes to
"                                   display, in order from left to right (i.e.
"                                   first character is the mark that should
"                                   appear at the top of the markbar.)
function! markbar#MarkbarState#getMarkbarContents(buffer_no, marks) abort dict
    call markbar#MarkbarState#AssertIsMarkbarState(self)
    if a:buffer_no ==# markbar#constants#GLOBAL_MARKS()
        throw '(markbar#MarkbarState) Bad argument value: ' . a:buffer_no
    endif
    let l:marks   = self['_buffer_caches'][a:buffer_no]['_marks_dict']
    let l:globals = self['_buffer_caches'][markbar#constants#GLOBAL_MARKS()]['_marks_dict']

    let l:lines = [] " to return
    let l:section_separator = markbar#settings#MarkbarSectionSeparator()
    let l:i = -1
    while l:i <# len(a:marks)
        let l:i += 1
        let l:mark_char = a:marks[l:i]

        if !has_key(l:marks, l:mark_char) && !has_key(l:globals, l:mark_char)
            continue
        endif

        let l:mark =
            \ markbar#helpers#IsGlobalMark(l:mark_char) ?
                \ l:globals[l:mark_char]
                \ :
                \ l:marks[l:mark_char]
        let l:lines += [ markbar#ui#MarkHeading(l:mark) ]

        let l:indent_block = markbar#settings#ContextIndentBlock()
        for l:line in l:mark['_context']
            let l:lines += [l:indent_block . l:line]
        endfor

        let l:lines += l:section_separator
    endwhile

    return l:lines
endfunction

" EFFECTS:  *Replace* the given buffer with the marks and contexts of the
"           given buffer.
function! markbar#MarkbarState#populateWithMarkbar(
    \ for_buffer_no,
    \ into_buffer_expr
\ ) abort dict
    call markbar#MarkbarState#AssertIsMarkbarState(self)
    let l:buffer_cache = self.getBufferCache(a:for_buffer_no)
    call self.updateCurrentAndGlobal()
    let l:contents  = markbar#ui#GetHelptext(g:markbar_show_verbose_help)
    let l:contents += self.getMarkbarContents(
        \ a:for_buffer_no,
        \ markbar#settings#MarksToDisplay()
    \ )
    call markbar#helpers#ReplaceBuffer(a:into_buffer_expr, l:contents)
endfunction

" EFFECTS:  Push the given buffer number onto the active buffer
"           ConditionalStack.
function! markbar#MarkbarState#pushNewBuffer(buffer_no) abort dict
    call markbar#MarkbarState#AssertIsMarkbarState(self)
    call self['_active_buffer_stack'].push(a:buffer_no)
endfunction

" EFFECTS:  Assign a name to the given mark.
" PARAM:    mark    (v:t_string)    The symbol corresponding to the target
"                                   mark. If the mark is local, it is assumed
"                                   to belong to the active buffer.
function! markbar#MarkbarState#nameMark(mark, name) abort dict
    call markbar#MarkbarState#AssertIsMarkbarState(self)
    if markbar#helpers#IsGlobalMark(a:mark)
        let l:buffer_cache =
            \ self.getBufferCache(markbar#constants#GLOBAL_MARKS())
    else
        let l:buffer_cache = self.getActiveBuffer()
    endif
    let l:mark_data = l:buffer_cache['_marks_dict'][a:mark]
    call l:mark_data.setName(a:name)
endfunction

" RETURNS:  (v:t_number)    The most recently accessed 'real' buffer.
function! markbar#MarkbarState#getActiveBuffer() abort dict
    call markbar#MarkbarState#AssertIsMarkbarState(self)
    return self['_active_buffer_stack'].top()
endfunction

" RETURNS: (v:t_number)     The buffer number of the 'markbar buffer.'
" EFFECTS:  Creates a markbar buffer for the MarkbarState object if one does
"           not yet exist.
function! markbar#MarkbarState#getMarkbarBuffer() abort dict
    call markbar#MarkbarState#AssertIsMarkbarState(self)
    if !bufexists(self['_markbar_buffer'])
        let l:bufname = markbar#settings#MarkbarBufferName()
        execute 'badd ' . l:bufname
        let l:bufnr = bufnr(
            \ escape(l:bufname, '~*.$[]')
        \ )
        let self['_markbar_buffer'] = l:bufnr
        call markbar#ui#SetMarkbarBufferSettings(l:bufnr)
    endif
    return self['_markbar_buffer']
endfunction

" RETURNS:  (MarkData)      The MarkData object corresponding to the given
"                           mark character.
" DETAILS:  - If the requested mark is a local mark, then the MarkbarState
"           object will search the BufferCache for the currently active
"           buffer.
"           - If the requested mark is a global (file or numbered) mark, then
"           the MarkbarState object will search the global BufferCache.
"           - If the requested mark cannot be found, throw an exception.
function! markbar#MarkbarState#getMarkData(mark_char) abort dict
    call markbar#MarkbarState#AssertIsMarkbarState(self)
    let l:is_global = markbar#helpers#IsGlobalMark(a:mark_char)
    let l:mark_buffer =
            \ l:is_global ?
                \ markbar#constants#GLOBAL_MARKS()
                \ :
                \ self.getActiveBuffer()
    let l:marks_dict =
        \ self.getBufferCache(l:mark_buffer)['_marks_dict']
    if !has_key(l:marks_dict, a:mark_char)
        throw '(markbar#MarkbarState) Could not find mark ' . a:mark_char
            \ . ' for buffer ' . l:mark_buffer
    endif
    let l:mark = l:marks_dict[a:mark_char]
    return l:mark
endfunction

" RETURNS:  (v:t_list)      A list of buffer numbers corresponding to all
"                           markbar buffers open in the current tab.
function! markbar#MarkbarState#getOpenMarkbars() abort dict
    call markbar#MarkbarState#AssertIsMarkbarState(self)
    let l:tab_buffers = tabpagebuflist()
    let l:markbar_buffers = []
    for l:bufnr in l:tab_buffers
        if getbufvar(l:bufnr, 'is_markbar')
            let l:markbar_buffers += [l:bufnr]
        endif
    endfor
    return l:markbar_buffers
endfunction

" RETURNS:  (v:t_bool)      `v:true` if a markbar is open in the current tab,
"                           `v:false` otherwise.
function! markbar#MarkbarState#markbarIsOpenCurrentTab() abort dict
    call markbar#MarkbarState#AssertIsMarkbarState(self)
    let l:tab_buffers = tabpagebuflist()
    for l:bufnr in l:tab_buffers
        if getbufvar(l:bufnr, 'is_markbar')
            return v:true
        endif
    endfor
    return v:false
endfunction

" RETURNS:  (v:t_bool)      `v:true` if a cache was successfully removed,
"                           `v:false` otherwise.
function! markbar#MarkbarState#evictBufferCache(buffer_no) abort dict
    call markbar#MarkbarState#AssertIsMarkbarState(self)
    if !has_key(self['_buffer_caches'], a:buffer_no)
        return v:false
    endif
    call remove(self['_buffer_caches'], a:buffer_no)
    return v:true
endfunction
