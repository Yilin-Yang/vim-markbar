" BRIEF:    vim-markbar's accumulated data. Info for MarkbarView to display.
" DETAILS:  The 'model' in Model-View-Controller. Stores BufferCache objects
"           for each of the user's open buffers, and automatically updates
"           them using autocmds. Provides an interface for retrieving
"           information about the current model state.

" BRIEF:    Construct a MarkbarModel object.
function! markbar#MarkbarModel#new() abort
    let l:new = {
        \ 'TYPE': 'MarkbarModel',
        \ '_buffer_caches': {},
        \ '_active_buffer_stack':
            \ markbar#ConditionalStack#new(
                \ function('markbar#helpers#IsRealBuffer'),
                \ markbar#settings#MaximumActiveBufferHistory()
            \ ),
    \ }
    let l:new['getActiveBuffer'] =
        \ function('markbar#MarkbarModel#getActiveBuffer')
    let l:new['pushNewBuffer'] =
        \ function('markbar#MarkbarModel#pushNewBuffer')
    let l:new['getMarkData'] =
        \ function('markbar#MarkbarModel#getMarkData')
    let l:new['getBufferCache'] =
        \ function('markbar#MarkbarModel#getBufferCache')
    let l:new['evictBufferCache'] =
        \ function('markbar#MarkbarModel#evictBufferCache')
    let l:new['updateCurrentAndGlobal'] =
        \ function('markbar#MarkbarModel#updateCurrentAndGlobal')

    " TODO: variable lifetime an issue here?
    " TODO: put in augroup? limit to exactly one MarkbarModel?
    autocmd BufEnter * call l:new.pushNewBuffer(expand('<abuf>') + 0)
    autocmd BufDelete,BufWipeout *
        \ call l:new.evictBufferCache(expand('<abuf>') + 0)

    return l:new
endfunction

function! markbar#MarkbarModel#AssertIsMarkbarModel(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'MarkbarModel'
        throw '(markbar#MarkbarModel) Object is not of type MarkbarModel: ' . a:object
    endif
endfunction

" RETURNS:  (v:t_number)    The most recently accessed 'real' buffer.
function! markbar#MarkbarModel#getActiveBuffer() abort dict
    call markbar#MarkbarModel#AssertIsMarkbarModel(self)
    return self['_active_buffer_stack'].top()
endfunction

" EFFECTS:  Push the given buffer number onto the active buffer
"           ConditionalStack.
function! markbar#MarkbarModel#pushNewBuffer(buffer_no) abort dict
    call markbar#MarkbarModel#AssertIsMarkbarModel(self)
    call self['_active_buffer_stack'].push(a:buffer_no)
endfunction

" RETURNS:  (markbar#MarkData)  The MarkData object corresponding to the given
"                               mark character.
" DETAILS:  - If the requested mark is a local mark, then the MarkbarModel
"           object will search the BufferCache for the currently active
"           buffer.
"           - If the requested mark is a global (file or numbered) mark, then
"           the MarkbarModel object will search the global BufferCache.
"           - If the requested mark cannot be found, throw an exception.
function! markbar#MarkbarModel#getMarkData(mark_char) abort dict
    call markbar#MarkbarModel#AssertIsMarkbarModel(self)
    let l:is_global = markbar#helpers#IsGlobalMark(a:mark_char)
    let l:mark_buffer =
            \ l:is_global ?
                \ markbar#constants#GLOBAL_MARKS()
                \ :
                \ self.getActiveBuffer()
    let l:marks_dict =
        \ self.getBufferCache(l:mark_buffer)['_marks_dict']
    if !has_key(l:marks_dict, a:mark_char)
        throw '(markbar#MarkbarModel) Could not find mark ' . a:mark_char
            \ . ' for buffer ' . l:mark_buffer
    endif
    let l:mark = l:marks_dict[a:mark_char]
    return l:mark
endfunction

" RETURNS:  (markbar#BufferCache)   The buffer cache for the requested buffer.
" DETAILS:  Add a new BufferCache for the requested buffer, if one does not
"           yet exist.
function! markbar#MarkbarModel#getBufferCache(buffer_no) abort dict
    call markbar#MarkbarModel#AssertIsMarkbarModel(self)
    if !has_key(self['_buffer_caches'], a:buffer_no)
        let self['_buffer_caches'][a:buffer_no] =
            \ markbar#BufferCache#new(a:buffer_no)
    endif
    return self['_buffer_caches'][a:buffer_no]
endfunction

" RETURNS:  (v:t_bool)      `v:true` if a cache was successfully removed,
"                           `v:false` otherwise.
function! markbar#MarkbarModel#evictBufferCache(buffer_no) abort dict
    call markbar#MarkbarModel#AssertIsMarkbarModel(self)
    if !has_key(self['_buffer_caches'], a:buffer_no)
        return v:false
    endif
    call remove(self['_buffer_caches'], a:buffer_no)
    return v:true
endfunction

" EFFECTS:  - Update the BufferCache for the currently focused buffer.
"           - Update the BufferCache for global marks (filemarks, etc.)
function! markbar#MarkbarModel#updateCurrentAndGlobal() abort dict
    call markbar#MarkbarModel#AssertIsMarkbarModel(self)
    let l:cur_buffer_cache    = self.getBufferCache(bufnr('%'))
    let l:global_buffer_cache = self.getBufferCache(markbar#constants#GLOBAL_MARKS())
    call    l:cur_buffer_cache.updateCache(markbar#helpers#GetLocalMarks())
    call l:global_buffer_cache.updateCache(markbar#helpers#GetGlobalMarks())
    call    l:cur_buffer_cache.updateContexts(markbar#settings#NumLinesContext())
    call l:global_buffer_cache.updateContexts(markbar#settings#NumLinesContext())

    " TODO: grab the maximum possible numbers of lines of context, for
    " compact/normal?
endfunction
