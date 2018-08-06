" EFFECTS:  Default-initialize a MarkbarBuffers object.
" DETAILS:  MarkbarBuffers stores cached information on buffers, as well as
"           those buffers' markbar buffers. It provides an interface for
"           updating those caches, refreshing markbar buffers, and opening
"           markbar buffers in response to user commands.
function! markbar#MarkbarBuffers#new() abort
    let l:new = {
        \ 'TYPE': 'MarkbarBuffers',
        \ '_buffer_caches': {},
        \ '_active_buffer_stack':
            \ markbar#ConditionalStack#new(
                \ function('markbar#helpers#IsRealBuffer'),
                \ markbar#settings#MaximumActiveBufferHistory()
            \ ),
    \ }
    let l:new['closeMarkbar()'] =
        \ function('markbar#MarkbarBuffers#closeMarkbar', [l:new])
    let l:new['evictBufferCache()'] =
        \ function('markbar#MarkbarBuffers#evictBufferCache', [l:new])
    let l:new['getActiveBuffer()'] =
        \ function('markbar#MarkbarBuffers#getActiveBuffer', [l:new])
    let l:new['getBufferCache()'] =
        \ function('markbar#MarkbarBuffers#getBufferCache', [l:new])
    let l:new['getMarkData()'] =
        \ function('markbar#MarkbarBuffers#getMarkData', [l:new])
    let l:new['markbarIsOpenCurrentTab()'] =
        \ function('markbar#MarkbarBuffers#markbarIsOpenCurrentTab', [l:new])
    let l:new['openMarkbar()'] =
        \ function('markbar#MarkbarBuffers#openMarkbar', [l:new])
    let l:new['populateWithMarkbar()'] =
        \ function('markbar#MarkbarBuffers#populateWithMarkbar', [l:new])
    let l:new['pushNewBuffer()'] =
        \ function('markbar#MarkbarBuffers#pushNewBuffer', [l:new])
    let l:new['spawnNewMarkbarBuffer()'] =
        \ function('markbar#MarkbarBuffers#spawnNewMarkbarBuffer', [l:new])
    let l:new['toggleMarkbar()'] =
        \ function('markbar#MarkbarBuffers#toggleMarkbar', [l:new])
    let l:new['updateCurrentAndGlobal()'] =
        \ function('markbar#MarkbarBuffers#updateCurrentAndGlobal', [l:new])
    let l:new['getMarkbarContents()'] =
        \ function('markbar#MarkbarBuffers#getMarkbarContents', [l:new])

    return l:new
endfunction

function! markbar#MarkbarBuffers#AssertIsMarkbarBuffers(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'MarkbarBuffers'
        throw '(markbar#MarkbarBuffers) Object is not of type MarkbarBuffers: ' . a:object
    endif
endfunction

" EFFECTS:  - Add a new BufferCache for the requested buffer, if one does not
"           yet exist.
" RETURNS:  (markbar#BufferCache)   The buffer cache for the requested buffer.
function! markbar#MarkbarBuffers#getBufferCache(self, buffer_no)
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    if !has_key(a:self['_buffer_caches'], a:buffer_no)
        let a:self['_buffer_caches'][a:buffer_no] =
            \ markbar#BufferCache#new(a:buffer_no)
    endif
    return a:self['_buffer_caches'][a:buffer_no]
endfunction

" EFFECTS:  - Update the BufferCache for the currently focused buffer.
"           - Update the BufferCache for global marks (filemarks, etc.)
function! markbar#MarkbarBuffers#updateCurrentAndGlobal(self) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    let l:cur_buffer_cache    = a:self['getBufferCache()'](bufnr('%'))
    let l:global_buffer_cache = a:self['getBufferCache()'](markbar#constants#GLOBAL_MARKS())
    call    l:cur_buffer_cache['updateCache()'](markbar#helpers#GetLocalMarks())
    call l:global_buffer_cache['updateCache()'](markbar#helpers#GetGlobalMarks())
    call    l:cur_buffer_cache['updateContexts()'](markbar#settings#NumLinesContext())
    call l:global_buffer_cache['updateContexts()'](markbar#settings#NumLinesContext())
endfunction

" EFFECTS:  - Close any existing markbars.
"           - Create a markbar buffer for the currently active buffer if one
"           does not yet exist.
"           - Open this markbar buffer in a sidebar.
function! markbar#MarkbarBuffers#openMarkbar(self) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)

    call a:self['closeMarkbar()']()
    call a:self['updateCurrentAndGlobal()']()

    let l:active_buffer       = a:self['_active_buffer_stack']['top()']()
    let l:active_buffer_cache = a:self['_buffer_caches'][l:active_buffer]

    let l:markbar_buffer = l:active_buffer_cache['_markbar_buffer_no']
    if l:markbar_buffer <# 0
        " no existing markbar buffer
        let l:active_buffer_cache['_markbar_buffer_no'] =
            \ a:self['spawnNewMarkbarBuffer()']()
        let l:markbar_buffer = l:active_buffer_cache['_markbar_buffer_no']
    else
        " existing markbar buffer
        let l:markbar_window = bufwinnr(l:markbar_buffer)
        if l:markbar_window ==# -1
            call markbar#ui#OpenMarkbarSplit(l:active_buffer_cache['_markbar_buffer_no'])
        else
            " switch to existing markbar window
            execute l:markbar_window . 'wincmd w'
        endif
    endif

    call a:self['populateWithMarkbar()'](l:active_buffer, l:markbar_buffer)
endfunction

" EFFECTS:  Close the markbar that is open in the current tab page, if one
"           exists. Else, does nothing.
" RETURNS:  (v:t_bool)      `v:true` if a markbar was actually closed,
"                           `v:false` otherwise.
function! markbar#MarkbarBuffers#closeMarkbar(self) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    let l:tab_buffers = tabpagebuflist()
    let l:closed_windows = v:false
    for l:bufnr in l:tab_buffers
        if getbufvar(l:bufnr, 'is_markbar')
            execute bufwinnr(l:bufnr) . 'close'
            let l:closed_windows = v:true
        endif
    endfor
    return l:closed_windows
endfunction

" EFFECTS:  Close the currently open markbar, if one is open. If no markbar
"           is open, open a markbar for the active buffer.
function! markbar#MarkbarBuffers#toggleMarkbar(self) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    if   a:self['closeMarkbar()']() | return | endif
    call a:self['openMarkbar()']()
endfunction

" EFFECTS:  - Create a new markbar buffer for the currently active buffer.
"           - Open this new markbar buffer in a split.
" RETURNS:  (v:t_number)    The buffer number of the new buffer.
function! markbar#MarkbarBuffers#spawnNewMarkbarBuffer(self) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    " TODO: handle exception for no active buffer
    let l:active_buffer = a:self['_active_buffer_stack']['top()']()
    let l:buffer_cache  = a:self['_buffer_caches'][l:active_buffer]
    if l:buffer_cache['_markbar_buffer_no'] ># 0
        throw '(markbar#MarkbarBuffers) Active buffer already has a markbar buffer: '
            \ . string(l:buffer_cache)
    endif

    let l:markbar = markbar#ui#OpenMarkbarSplit()
    let l:buffer_cache['_markbar_buffer_no'] = l:markbar
    return l:markbar
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
function! markbar#MarkbarBuffers#getMarkbarContents(self, buffer_no, marks) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    if a:buffer_no ==# markbar#constants#GLOBAL_MARKS()
        throw '(markbar#MarkbarBuffers) Bad argument value: ' . a:buffer_no
    endif
    let l:marks   = a:self['_buffer_caches'][a:buffer_no]['_marks_dict']
    let l:globals = a:self['_buffer_caches'][markbar#constants#GLOBAL_MARKS()]['_marks_dict']

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
function! markbar#MarkbarBuffers#populateWithMarkbar(
    \ self,
    \ for_buffer_no,
    \ into_buffer_expr
\ ) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    let l:buffer_cache = a:self['getBufferCache()'](a:for_buffer_no)
    call a:self['updateCurrentAndGlobal()']()
    let l:contents = a:self['getMarkbarContents()'](
        \ a:for_buffer_no,
        \ markbar#settings#MarksToDisplay()
    \ )
    call markbar#helpers#ReplaceBuffer(a:into_buffer_expr, l:contents)
endfunction

" EFFECTS:  Push the given buffer number onto the active buffer
"           ConditionalStack.
function! markbar#MarkbarBuffers#pushNewBuffer(self) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    let a:buffer_no = expand('<abuf>') + 0
    call a:self['_active_buffer_stack']['push()'](a:buffer_no)
endfunction

" EFFECTS:  Assign a name to the given mark.
" PARAM:    mark    (v:t_string)    The symbol corresponding to the target
"                                   mark. If the mark is local, it is assumed
"                                   to belong to the active buffer.
function! markbar#MarkbarBuffers#nameMark(self, mark, name) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    if markbar#helpers#IsGlobalMark(a:mark)
        let l:buffer_cache =
            \ a:self['getBufferCache()'](markbar#constants#GLOBAL_MARKS())
    else
        let l:buffer_cache = a:self['getActiveBuffer()']()
    endif
    let l:mark_data = l:buffer_cache['_marks_dict'][a:mark]
    call l:mark_data['setName()'](a:name)
endfunction

" RETURNS:  (v:t_number)    The most recently accessed 'real' buffer.
function! markbar#MarkbarBuffers#getActiveBuffer(self) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    return a:self['_active_buffer_stack']['top()']()
endfunction

" RETURNS:  (v:t_number)    The buffer number of the active buffer's
"                           markbar, or a negative number if it doesn't have
"                           one.
function! markbar#MarkbarBuffers#getActiveBufferMarkbar(self) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    let l:active_buffer       = a:self['_active_buffer_stack']['top()']()
    let l:active_buffer_cache = a:self['_buffer_caches'][l:active_buffer]
    return l:active_buffer_cache['_markbar_buffer_no']
endfunction

" RETURNS:  (MarkData)      The MarkData object corresponding to the given
"                           mark character.
" DETAILS:  - If the requested mark is a local mark, then the MarkbarBuffers
"           object will search the BufferCache for the currently active
"           buffer.
"           - If the requested mark is a global (file or numbered) mark, then
"           the MarkbarBuffers object will search the global BufferCache.
"           - If the requested mark cannot be found, throw an exception.
function! markbar#MarkbarBuffers#getMarkData(self, mark_char) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    let l:is_global = markbar#helpers#IsGlobalMark(a:mark_char)
    let l:mark_buffer =
            \ l:is_global ?
                \ markbar#constants#GLOBAL_MARKS()
                \ :
                \ a:self['getActiveBuffer()']()
    let l:marks_dict =
        \ a:self['getBufferCache()'](l:mark_buffer)['_marks_dict']
    if !has_key(l:marks_dict, a:mark_char)
        throw '(markbar#MarkbarBuffers) Could not find mark ' . a:mark_char
            \ . ' for buffer ' . l:mark_buffer
    endif
    let l:mark = l:marks_dict[a:mark_char]
    return l:mark
endfunction

" RETURNS:  (v:t_bool)      `v:true` if a markbar is open in the current tab,
"                           `v:false` otherwise.
function! markbar#MarkbarBuffers#markbarIsOpenCurrentTab(self) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
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
function! markbar#MarkbarBuffers#evictBufferCache(self, buffer_no) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    if !has_key(a:self['_buffer_caches'], a:buffer_no)
        return v:false
    endif
    call remove(a:self['_buffer_caches'], a:buffer_no)
    return v:true
endfunction
