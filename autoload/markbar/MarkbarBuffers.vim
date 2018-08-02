" EFFECTS:  Default-initializes a MarkbarBuffers object.
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
    let l:new['getBufferCache()'] =
        \ function('markbar#MarkbarBuffers#getBufferCache', [l:new])
    let l:new['openMarkbar()'] =
        \ function('markbar#MarkbarBuffers#openMarkbar', [l:new])
    let l:new['populateWithMarkbar()'] =
        \ function('markbar#MarkbarBuffers#populateWithMarkbar', [l:new])
    let l:new['spawnNewMarkbarBuffer()'] =
        \ function('markbar#MarkbarBuffers#spawnNewMarkbarBuffer', [l:new])
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

" EFFECTS:  - Adds a new BufferCache for the requested buffer, if one does not
"           yet exist.
" RETURN:   (markbar#BufferCache)   The buffer cache for the requested buffer.
function! markbar#MarkbarBuffers#getBufferCache(self, buffer_no)
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    if !has_key(a:self['_buffer_caches'], a:buffer_no)
        let a:self['_buffer_caches'][a:buffer_no] =
            \ markbar#BufferCache#new(a:buffer_no)
    endif
    return a:self['_buffer_caches'][a:buffer_no]
endfunction

" EFFECTS:  - Updates the BufferCache for the currently focused buffer.
"           - Updates the BufferCache for global marks (filemarks, etc.)
function! markbar#MarkbarBuffers#updateCurrentAndGlobal(self) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    let l:cur_buffer_cache    = a:self['getBufferCache()'](bufnr('%'))
    let l:global_buffer_cache = a:self['getBufferCache()'](markbar#constants#GLOBAL_MARKS())
    call    l:cur_buffer_cache['updateCache()'](markbar#helpers#GetLocalMarks())
    call l:global_buffer_cache['updateCache()'](markbar#helpers#GetGlobalMarks())
    call    l:cur_buffer_cache['updateContexts()'](markbar#settings#NumLinesContext())
    call l:global_buffer_cache['updateContexts()'](markbar#settings#NumLinesContext())
endfunction

" EFFECTS:  - Creates a markbar buffer for the currently active buffer if one
"           does not yet exist.
"           - Opens this markbar buffer in a sidebar.
function! markbar#MarkbarBuffers#openMarkbar(self) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)

    call markbar#MarkbarBuffers#updateCurrentAndGlobal(a:self)
    let l:active_buffer       = a:self['_active_buffer_stack']['top()']()
    let l:active_buffer_cache = a:self['_buffer_caches'][l:active_buffer]

    let l:markbar_buffer = l:active_buffer_cache['_markbar_buffer_no']
    if l:markbar_buffer <# 0
        " no existing markbar buffer
        call a:self['spawnNewMarkbarBuffer()']()
    else
        " existing markbar buffer
        call markbar#ui#OpenMarkbarSplit(l:active_buffer_cache['_markbar_buffer_no'])
    endif

    call a:self['populateWithMarkbar()'](l:active_buffer, l:markbar_buffer)
endfunction

" EFFECTS:  - Creates a new markbar buffer for the currently active buffer.
"           - Opens this new markbar buffer in a sidebar.
" RETURN:   (v:t_number)    The buffer number of the new buffer.
function! markbar#MarkbarBuffers#spawnNewMarkbarBuffer(self) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    " TODO: handle exception for no active buffer
    let l:active_buffer = a:self['_active_buffer_stack']['top()']
    let l:buffer_cache  = a:self['_buffer_caches'][l:active_buffer]
    if l:buffer_cache['_markbar_buffer_no'] <# 0
        throw '(markbar#MarkbarBuffers) Active buffer already has a markbar buffer: '
            \ . l:buffer_cache
    endif

    vnew
    let l:markbar = bufnr('%')
    let l:buffer_cache['_markbar_buffer_no'] = l:markbar
    call markbar#ui#SetMarkbarSettings()
    return l:markbar
endfunction

" REQUIRES: - `a:buffer_no` is not a markbar buffer.
"           - `a:buffer_no` is not the global buffer.
"           - `a:buffer_no` is a buffer *number.*
" EFFECTS:  - Returns a list populated linewise with the requested marks
"           and those marks' contexts.
" PARAM:    marks   (v:t_string)    Every mark that the user wishes to
"                                   display, in order from left to right (i.e.
"                                   first character is the mark that should
"                                   appear at the top of the markbar.)
function! markbar#MarkbarBuffers#getMarkbarContents(self, buffer_no, marks) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    if a:buffer_no ==# markbar#constants#GLOBAL_MARKS()
        throw '(markbar#MarkbarBuffers.vim) Bad argument value: ' . a:buffer_no
    endif
    let l:marks   = a:self['_buffer_caches'][a:buffer_no]
    let l:globals = a:self['_buffer_caches'][markbar#constants#GLOBAL_MARKS()]

    let l:lines = [] " to return
    let l:section_separator = markbar#settings#MarkbarSectionSeparator()
    let l:i = -1
    while l:i <# len(a:marks)
        let l:i += 1
        let l:mark_char = a:marks[l:i]

        if !has_key(l:marks, l:mark) && !has_key(l:globals, l:mark)
            continue
        endif

        let l:mark =
            \ markbar#helpers#IsGlobalMark(l:mark) ?
                \ l:globals[l:mark]
                \ :
                \ l:marks[l:mark]
        let l:lines += markbar#ui#MarkHeading(l:mark)

        let l:indent_block = markbar#settings#ContextIndentBlock()
        for l:line in l:mark['_context']
            let l:lines += [l:indent_block . l:line]
        endfor

        let l:lines += [l:section_separator]
    endwhile

    return l:lines
endfunction

" EFFECTS:  - *Replaces* the given buffer with the marks and contexts of the
"           given buffer.
function! markbar#MarkbarBuffers#populateWithMarkbar(
    \ self,
    \ for_buffer_no,
    \ into_buffer_expr
\ ) abort
    call markbar#MarkbarBuffers#AssertIsMarkbarBuffers(a:self)
    let l:buffer_cache = a:self['getBufferCache()'](a:for_buffer_no)
    call a:self['updateCurrentAndGlobal()']()
    let l:contents = a:self['getMarkbarContents()'](a:for_buffer_no)
    call markbar#helpers#ReplaceBuffer(a:into_buffer_expr, l:contents)
endfunction
