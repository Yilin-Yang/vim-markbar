" BRIEF:    vim-markbar's accumulated data. Info for MarkbarView to display.
" DETAILS:  The 'model' in Model-View-Controller. Stores BufferCache objects
"           for each of the user's open buffers, and automatically updates
"           them using autocmds. Provides an interface for retrieving
"           information about the current model state.
"
"           MarkbarModel is a singleton. Successive calls to `new` will return
"           a reference to the MarkbarModel already constructed (if one
"           exists).

" BRIEF:    Construct a MarkbarModel object, with associated autocmds.
" DETAILS:  Orphans any preexisting MarkbarModel objects (i.e. they will no
"           longer be updated by autocmds.)
function! markbar#MarkbarModel#get() abort
    if exists('g:markbar_model')
        try
            call markbar#MarkbarModel#AssertIsMarkbarModel(g:markbar_model)
            " there exists a preexisting markbar_model
            return g:markbar_model
        catch
            " invalid object, okay to overwrite
        endtry
    endif

    let g:markbar_model = {
        \ 'TYPE': 'MarkbarModel',
        \ '_buffer_caches': {},
        \ '_active_buffer_stack':
            \ markbar#ConditionalStack#new(
                \ function('markbar#helpers#IsRealBuffer'),
                \ markbar#settings#MaximumActiveBufferHistory()
            \ ),
        \ 'getActiveBuffer':
            \ function('markbar#MarkbarModel#getActiveBuffer'),
        \ 'pushNewBuffer':
            \ function('markbar#MarkbarModel#pushNewBuffer'),
        \ 'getMarkData':
            \ function('markbar#MarkbarModel#getMarkData'),
        \ 'getBufferCache':
            \ function('markbar#MarkbarModel#getBufferCache'),
        \ 'evictBufferCache':
            \ function('markbar#MarkbarModel#evictBufferCache'),
        \ 'updateCurrentAndGlobal':
            \ function('markbar#MarkbarModel#updateCurrentAndGlobal'),
    \ }

    augroup markbar_model_update
        au!
        autocmd BufEnter * call g:markbar_model.pushNewBuffer(expand('<abuf>') + 0)
        autocmd BufDelete,BufWipeout *
            \ call g:markbar_model.evictBufferCache(expand('<abuf>') + 0)
    augroup end

    return g:markbar_model
endfunction

function! markbar#MarkbarModel#AssertIsMarkbarModel(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'MarkbarModel'
        throw '(markbar#MarkbarModel) Object is not of type MarkbarModel: ' . a:object
    endif
endfunction

" RETURNS:  (v:t_number)    The most recently accessed 'real' buffer.
function! markbar#MarkbarModel#getActiveBuffer() abort dict
    call markbar#MarkbarModel#AssertIsMarkbarModel(l:self)
    return l:self['_active_buffer_stack'].top()
endfunction

" EFFECTS:  Push the given buffer number onto the active buffer
"           ConditionalStack.
function! markbar#MarkbarModel#pushNewBuffer(buffer_no) abort dict
    call markbar#MarkbarModel#AssertIsMarkbarModel(l:self)
    call l:self['_active_buffer_stack'].push(a:buffer_no)
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
    call markbar#MarkbarModel#AssertIsMarkbarModel(l:self)
    let l:is_global = markbar#helpers#IsGlobalMark(a:mark_char)
    let l:mark_buffer =
            \ l:is_global ?
                \ markbar#constants#GLOBAL_MARKS()
                \ :
                \ l:self.getActiveBuffer()
    let l:marks_dict =
        \ l:self.getBufferCache(l:mark_buffer)['_marks_dict']
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
    call markbar#MarkbarModel#AssertIsMarkbarModel(l:self)
    if !has_key(l:self['_buffer_caches'], a:buffer_no)
        let l:self['_buffer_caches'][a:buffer_no] =
            \ markbar#BufferCache#new(a:buffer_no)
    endif
    return l:self['_buffer_caches'][a:buffer_no]
endfunction

" RETURNS:  (v:t_bool)      `v:true` if a cache was successfully removed,
"                           `v:false` otherwise.
function! markbar#MarkbarModel#evictBufferCache(buffer_no) abort dict
    call markbar#MarkbarModel#AssertIsMarkbarModel(l:self)
    if !has_key(l:self['_buffer_caches'], a:buffer_no)
        return v:false
    endif
    call remove(l:self['_buffer_caches'], a:buffer_no)
    return v:true
endfunction

" EFFECTS:  - Update the BufferCache for the currently focused buffer.
"           - Update the BufferCache for global marks (filemarks, etc.)
function! markbar#MarkbarModel#updateCurrentAndGlobal() abort dict
    call markbar#MarkbarModel#AssertIsMarkbarModel(l:self)
    let l:cur_buffer_cache    = l:self.getBufferCache(bufnr('%'))
    let l:global_buffer_cache = l:self.getBufferCache(markbar#constants#GLOBAL_MARKS())
    call    l:cur_buffer_cache.updateCache(markbar#helpers#GetLocalMarks())
    call l:global_buffer_cache.updateCache(markbar#helpers#GetGlobalMarks())
    call    l:cur_buffer_cache.updateContexts(markbar#settings#NumLinesContext())
    call l:global_buffer_cache.updateContexts(markbar#settings#NumLinesContext())

    " TODO: grab the maximum possible numbers of lines of context, for
    " compact/normal?
endfunction
