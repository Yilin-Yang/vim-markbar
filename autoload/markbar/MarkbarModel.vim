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
        \ 'renameMark':
            \ function('markbar#MarkbarModel#renameMark'),
        \ 'resetMark':
            \ function('markbar#MarkbarModel#resetMark'),
        \ 'deleteMark':
            \ function('markbar#MarkbarModel#deleteMark'),
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

    " bottom of the active buffer stack will *always* be zero, to prevent
    " errors when the entire stack is cleared
    call g:markbar_model.pushNewBuffer(0)

    if v:vim_did_enter
        call g:markbar_model.pushNewBuffer(markbar#helpers#GetOpenBuffers())
    endif

    augroup markbar_model_update
        au!
        autocmd VimEnter * call g:markbar_model.pushNewBuffer(markbar#helpers#GetOpenBuffers())
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

" BRIEF:    Prompt the user to assign an explicit name to the selected mark.
" DETAILS:  Requires that the markbar be open and focused.
"           Changes won't appear until the markbar has been repopulated.
" PARAM:    mark    (v:t_string)    The single character representing the
"                                   mark.
function! markbar#MarkbarModel#renameMark(mark) abort dict
    call markbar#MarkbarModel#AssertIsMarkbarModel(l:self)
    if type(a:mark) !=# v:t_string || len(a:mark) !=# 1
        throw '(markbar#MarkbarModel) Bad argument to renameMark: ' . a:mark
    endif

    let l:mark_data = l:self.getMarkData(a:mark)

    call inputsave()
    let l:new_name = input('New name for mark [''' . a:mark . ']: ',
        \ l:mark_data.getName(),
        \ markbar#settings#RenameMarkCompletion()
    \ )
    call inputrestore()

    call l:mark_data.setName(l:new_name)
endfunction

" BRIEF:    Reset the name of the selected mark to the default.
" DETAILS:  Changes won't appear until the markbar has been repopulated.
" PARAM:    mark    (v:t_string)    The single character representing the
"                                   mark.
function! markbar#MarkbarModel#resetMark(mark) abort dict
    call markbar#MarkbarModel#AssertIsMarkbarModel(l:self)
    if type(a:mark) !=# v:t_string || len(a:mark) !=# 1
        throw '(markbar#MarkbarModel) Bad argument to resetMark: ' . a:mark
    endif
    let l:mark_data = l:self.getMarkData(a:mark)
    call l:mark_data.setName('')
endfunction

" BRIEF:    Delete the given mark, and remove it from the cache.
" DETAILS:  Changes won't appear until the markbar has been repopulated.
"           Must be invoked while the cursor is inside a markbar.
" PARAM:    mark    (v:t_string)    The single character representing the
"                                   mark.
function! markbar#MarkbarModel#deleteMark(mark) abort dict
    call markbar#MarkbarModel#AssertIsMarkbarModel(l:self)
    if type(a:mark) !=# v:t_string || len(a:mark) !=# 1
        throw '(markbar#MarkbarModel) Bad argument to deleteMark: ' . a:mark
    endif

    let l:is_global = markbar#helpers#IsGlobalMark(a:mark)

    " delete actual mark itself
    let l:markbar_buffer = bufnr('%')
    let l:cur_pos = getcurpos()
    if !l:is_global
        let l:active_buffer = l:self.getActiveBuffer()
        execute bufwinnr(l:active_buffer) . 'wincmd w'
    endif
    try
        execute 'delmarks ' . a:mark
    catch /E475/  " Bad argument
        " do nothing; it'll disappear from the markbar, and be repopulated
        " when it's next opened.
    catch /E471/  " Argument required
        " user tried deleting the double quote
    endtry
    execute bufwinnr(l:markbar_buffer) . 'wincmd w'
    call setpos('.', l:cur_pos)

    " update the cache
    let l:cache = l:self.getBufferCache(
        \ l:is_global ? markbar#constants#GLOBAL_MARKS() : l:active_buffer)
    try
        unlet l:cache['marks_dict'][a:mark]
    catch /E716/  " Key not present in dictionary
    endtry
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
    if type(a:buffer_no) ==# v:t_list
        for l:no in a:buffer_no | call l:self.pushNewBuffer(l:no) | endfor
        return
    endif
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
        \ l:self.getBufferCache(l:mark_buffer)['marks_dict']
    if !has_key(l:marks_dict, a:mark_char)
        throw '(markbar#MarkbarModel) Could not find mark ' . a:mark_char
            \ . ' for buffer ' . l:mark_buffer
    endif
    let l:mark = l:marks_dict[a:mark_char]
    return l:mark
endfunction

" RETURNS:  (markbar#BufferCache)   The buffer cache for the requested buffer.
" DETAILS:  Add a new BufferCache for the requested buffer, if one does not
"           yet exist and `a:no_init` is false. If `a:no_init` is true, throw
"           an exception.
" PARAM:    buffer_no   (v:t_number)    The bufnr() of the requested buffer.
" PARAM:    no_init     (v:t_bool?)     Whether to create a new BufferCache if
"                                       the requested cache is not found.
"                                       Defaults to `v:false`.
function! markbar#MarkbarModel#getBufferCache(buffer_no, ...) abort dict
    call markbar#MarkbarModel#AssertIsMarkbarModel(l:self)
    let l:no_init = get(a:000, 0, v:false)
    if !has_key(l:self['_buffer_caches'], a:buffer_no)
        if l:no_init
            throw '(markbar#MarkbarModel) Buffer not cached: '.a:buffer_no
        endif
        let l:self['_buffer_caches'][a:buffer_no] =
            \ markbar#BufferCache#new(a:buffer_no)
    endif
    " will throw E716 if not found and a:no_init == v:true
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

    " retrieve the greatest number of lines of context that we may need
    " for all marks, for simplicity
    let l:max_num_context = 0
    let l:num_lines_config = markbar#settings#NumLinesContext()
    for l:num_lines in values(l:num_lines_config)
        if l:num_lines ># l:max_num_context
            let l:max_num_context = l:num_lines
        endif
    endfor

    call    l:cur_buffer_cache.updateCache(markbar#helpers#GetLocalMarks())
    call l:global_buffer_cache.updateCache(markbar#helpers#GetGlobalMarks())
    call    l:cur_buffer_cache.updateContexts(l:max_num_context)
    call l:global_buffer_cache.updateContexts(l:max_num_context)
endfunction
