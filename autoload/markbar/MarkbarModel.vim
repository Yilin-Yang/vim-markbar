let s:MarkbarModel = {
    \ '_buffer_caches': {},
    \ '_active_buffer_stack':
        \ markbar#ConditionalStack#New(
            \ function('markbar#helpers#IsRealBuffer'),
            \ markbar#settings#MaximumActiveBufferHistory()
        \ ),
\ }

" BRIEF:    vim-markbar's accumulated data. Info for MarkbarView to display.
" DETAILS:  The 'model' in Model-View-Controller. Stores BufferCache objects
"           for each open buffer and automatically updates them using
"           autocmds. Exposes the current model state.
"
"           MarkbarModel is a singleton. Successive calls to `Get` will return
"           a reference to the MarkbarModel already constructed (if one
"           exists).
function! markbar#MarkbarModel#Get() abort
    try
        call markbar#ensure#IsClass(s:MarkbarModel, 'MarkbarModel')
        " there exists a preexisting markbar_model, don't reinitialize
        return s:MarkbarModel
    catch /Object is not of type/
        " invalid object, okay to overwrite
    endtry

    let s:MarkbarModel.TYPE = 'MarkbarModel'

    " bottom of the active buffer stack will *always* be zero, to prevent
    " errors when the entire stack is cleared
    call s:MarkbarModel.pushNewBuffer(0)

    if v:vim_did_enter
        call s:MarkbarModel.pushNewBuffer(markbar#helpers#GetOpenBuffers())
    endif

    augroup markbar_model_update
        au!
        autocmd VimEnter * call s:MarkbarModel.pushNewBuffer(markbar#helpers#GetOpenBuffers())
        autocmd BufEnter * call s:MarkbarModel.pushNewBuffer(expand('<abuf>') + 0)
        autocmd BufDelete,BufWipeout *
            \ call s:MarkbarModel.evictBufferCache(expand('<abuf>') + 0)
    augroup end

    return s:MarkbarModel
endfunction

" BRIEF:    Prompt the user to assign an explicit name to the selected mark.
" DETAILS:  Requires that the markbar be open and focused.
"           Changes won't appear until the markbar has been repopulated.
" PARAM:    mark    (v:t_string)    Single character representing the mark.
function! s:MarkbarModel.renameMark(mark) abort dict
    call markbar#ensure#IsMarkChar(a:mark)

    let l:mark_data = l:self.getMarkData(a:mark)

    call inputsave()
    let l:new_name = input(printf('New name for mark [''%s]: ', a:mark),
        \ l:mark_data.getName(), markbar#settings#RenameMarkCompletion())
    call inputrestore()

    call l:mark_data.setName(l:new_name)
endfunction

" BRIEF:    Reset the the selected mark's name to the default.
" DETAILS:  Changes won't appear until the markbar has been repopulated.
" PARAM:    mark    (v:t_string)    Single character representing the mark.
function! s:MarkbarModel.resetMark(mark) abort dict
    call markbar#ensure#IsMarkChar(a:mark)
    let l:mark_data = l:self.getMarkData(a:mark)
    call l:mark_data.setName('')
endfunction

" BRIEF:    Delete the given mark, and remove it from the cache.
" DETAILS:  Changes won't appear until the markbar has been repopulated.
"           Must be invoked while the cursor is inside a markbar.
" PARAM:    mark    (v:t_string)    The single character representing the
"                                   mark.
function! s:MarkbarModel.deleteMark(mark) abort dict
    call markbar#ensure#IsMarkChar(a:mark)

    let l:is_global = markbar#helpers#IsGlobalMark(a:mark)

    " delete actual mark itself
    let l:markbar_buffer = bufnr('%')
    let l:cur_pos = getcurpos()
    if !l:is_global
        let l:active_buffer = l:self.getActiveBuffer()
        execute win_gotoid(bufwinid(l:active_buffer))
    endif
    try
        execute 'delmarks ' . a:mark
    catch /E475/  " Bad argument
        " do nothing; it'll disappear from the markbar, and be repopulated
        " when it's next opened.
    catch /E471/  " Argument required
        " user tried deleting the double quote
    endtry
    execute win_gotoid(bufwinid(l:markbar_buffer))
    call setpos('.', l:cur_pos)

    " update the cache
    let l:cache = l:self.getBufferCache(
        \ l:is_global ? markbar#constants#GLOBAL_MARKS_BUFNR() : l:active_buffer)
    try
        unlet l:cache.marks_dict[a:mark]
    catch /E716/  " Key not present in dictionary
    endtry
endfunction

" RETURNS:  (v:t_number)    The most recently accessed 'real' buffer.
function! s:MarkbarModel.getActiveBuffer() abort dict
    return l:self._active_buffer_stack.top()
endfunction

" EFFECTS:  Push the given buffer number onto the active buffer
"           ConditionalStack.
function! s:MarkbarModel.pushNewBuffer(buffer_no) abort dict
    if type(a:buffer_no) ==# v:t_list
        for l:no in a:buffer_no
            call l:self.pushNewBuffer(l:no)
        endfor
        return
    endif
    call markbar#ensure#IsNumber(a:buffer_no)
    call l:self._active_buffer_stack.push(a:buffer_no)
endfunction

" RETURNS:  (markbar#MarkData)  The MarkData object corresponding to the given
"                               mark character.
" DETAILS:  - If the requested mark is a local mark, then the MarkbarModel
"           object will search the BufferCache for the currently active
"           buffer.
"           - If the requested mark is a global (file or numbered) mark, then
"           the MarkbarModel object will search the global BufferCache.
"           - If the requested mark cannot be found, throw an exception.
function! s:MarkbarModel.getMarkData(mark_char) abort dict
    let l:is_global = markbar#helpers#IsGlobalMark(a:mark_char)
    let l:mark_buffer =
            \ l:is_global ?
                \ markbar#constants#GLOBAL_MARKS_BUFNR()
                \ :
                \ l:self.getActiveBuffer()
    let l:marks_dict =
        \ l:self.getBufferCache(l:mark_buffer).marks_dict
    if !has_key(l:marks_dict, a:mark_char)
        throw '(markbar#MarkbarModel) Could not find mark ' . a:mark_char
            \ . ' for buffer ' . l:mark_buffer
    endif
    let l:mark = l:marks_dict[a:mark_char]
    return l:mark
endfunction

" RETURNS:  (markbar#BufferCache)   BufferCache for the requested buffer.
" DETAILS:  Initializes a BufferCache for the buffer if one doesn't exist.
" PARAM:    buffer_no   (v:t_number)    The bufnr() of the requested buffer.
function! s:MarkbarModel._getOrInitBufferCache(buffer_no) abort dict
    call markbar#ensure#IsNumber(a:buffer_no)
    let l:cache = get(l:self._buffer_caches, a:buffer_no, 0)
    if empty(l:cache)
        let l:cache = markbar#BufferCache#New(a:buffer_no)
        let l:self._buffer_caches[a:buffer_no] = l:cache
    endif
    return l:cache
endfunction

" RETURNS:  (markbar#BufferCache)   BufferCache for the requested buffer.
" DETAILS:  Throws an exception if a matching BufferCache isn't found.
" PARAM:    buffer_no   (v:t_number)    The bufnr() of the requested buffer.
function! s:MarkbarModel.getBufferCache(buffer_no) abort dict
    call markbar#ensure#IsNumber(a:buffer_no)
    let l:cache = get(l:self._buffer_caches, a:buffer_no, 0)
    if empty(l:cache)
        throw printf('Buffer not cached: %s', a:buffer_no)
    endif
    return l:cache
endfunction

" RETURNS:  (v:t_bool)  `v:true` if a cache was removed, `v:false` otherwise.
function! s:MarkbarModel.evictBufferCache(buffer_no) abort dict
    if !has_key(l:self._buffer_caches, a:buffer_no)
        return v:false
    endif
    call remove(l:self._buffer_caches, a:buffer_no)
    return v:true
endfunction

" DETAILS:  Update BufferCaches for the current buffer and for global marks.
"           Creates BufferCaches for the current buffer and global marks if
"           they don't yet exist.
function! s:MarkbarModel.updateCurrentAndGlobal() abort dict
    let l:cur_buffer_cache = l:self._getOrInitBufferCache(bufnr('%'))
    "                                                     ^ This is bufnr('%')
    " and not getActiveBuffer() because helpers#GetLocalMarks() pulls |:marks|
    " output for the currently focused window, which might e.g.  be the
    " markbar window, which _active_buffer_stack.top() wouldn't return as a
    " 'real buffer'.
    "
    " If getActiveBuffer() and bufnr('%') were different, then
    " cur_buffer_cache.updateCache might e.g. clobber the last active buffer's
    " BufferCache with the (probably nonexistent) marks for the markbar window.
    let l:global_buffer_cache = l:self._getOrInitBufferCache(
        \ markbar#constants#GLOBAL_MARKS_BUFNR())

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
