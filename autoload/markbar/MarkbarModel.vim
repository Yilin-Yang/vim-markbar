let s:MarkbarModel = {
    \ 'TYPE': 'MarkbarModel',
    \ '_rosters': v:null,
    \ '_buffer_caches': {},
    \ '_active_buffer_stack':
        \ markbar#ConditionalStack#New(
            \ function('markbar#helpers#IsRealBuffer'),
            \ markbar#settings#MaximumActiveBufferHistory()
        \ ),
\ }

" BRIEF:    vim-markbar's accumulated data. Info for MarkbarView to display.
" DETAILS:  The 'model' in Model-View-Controller. Stores BufferCache objects
"           for each open buffer. Tracks the user's most recent active buffer.
"           Exposes the current model state.
"
"           To track the most recent active buffer: pushNewBuffer()
"           pushes new |bufnr|s onto an internal stack, which is accessed
"           through getActiveBuffer().
"
"           updateCurrentAndGlobal() actually updates stored BufferCache
"           objects. This is done by parsing the output of the |:marks|
"           command, which returns local marks for the currently open buffer,
"           as well as 'global' marks, like uppercase marks.
"
"           Mark names are also tracked in/with a ShaDaRosters object, which
"           helps to persist mark names across editing sessions.
" PARAM:    rosters (ShaDaRosters)      Mark names from/for the ShaDa file.
function! markbar#MarkbarModel#New(rosters) abort
    call markbar#ensure#IsClass(a:rosters, 'ShaDaRosters')

    let l:new = deepcopy(s:MarkbarModel)
    let l:new._rosters = a:rosters

    " bottom of the active buffer stack will *always* be zero, to prevent
    " errors when the entire stack is cleared
    call l:new.pushNewBuffer(0)

    return l:new
endfunction

function! s:WarnIfValidMarkCharIsEmpty(Object, operation) abort
    call markbar#ensure#IsString(a:Object)
    if a:Object ==# ''
        echohl WarningMsg
        echomsg printf('No mark selected for %s.', a:operation)
        echohl None
        return v:true
    endif
    if !has_key(markbar#constants#ALL_MARKS_DICT(), a:Object)
        throw printf('Invalid mark name: %s', a:Object)
    endif
    return v:false
endfunction

" DETAILS:  Update the {roster} entry for the given {mark_data} with {new_name}.
function! s:UpdateNameAndRosterEntry(rosters, mark_data, new_name) abort
    call markbar#ensure#IsClass(a:rosters, 'ShaDaRosters')
    call markbar#ensure#IsClass(a:mark_data, 'MarkData')
    call markbar#ensure#IsString(a:new_name)

    call a:mark_data.setUserName(a:new_name)
    call a:rosters.setName(
            \ a:mark_data.isGlobal() ? 0 : a:mark_data.getFilename(),
            \ a:mark_data.getMarkChar(), a:new_name)
endfunction

" BRIEF:    Prompt the user to assign an explicit name to the selected mark.
" DETAILS:  Requires that the markbar be open and focused.
"           Changes won't appear until the markbar has been repopulated.
" PARAM:    mark    (v:t_string)    Single character representing the mark.
" PARAM:    new_name?   (v:t_string)    New name for the mark. If not present
"                                       or empty, prompt the user to enter a
"                                       new name.
function! markbar#MarkbarModel#renameMark(mark, ...) abort dict
    if s:WarnIfValidMarkCharIsEmpty(a:mark, 'renaming')
        return
    endif

    let l:mark_data = l:self.getMarkData(a:mark)

    let l:new_name = get(a:000, 0, '')
    if empty(l:new_name)
        call inputsave()
        let l:new_name = input(printf('New name for mark [''%s]: ', a:mark),
            \ l:mark_data.getUserName(), markbar#settings#RenameMarkCompletion())
        call inputrestore()
    endif

    call s:UpdateNameAndRosterEntry(l:self._rosters, l:mark_data, l:new_name)
endfunction
let s:MarkbarModel.renameMark = function('markbar#MarkbarModel#renameMark')

" BRIEF:    Reset the the selected mark's name to the default.
" DETAILS:  Changes won't appear until the markbar has been repopulated.
" PARAM:    mark    (v:t_string)    Single character representing the mark.
function! markbar#MarkbarModel#resetMark(mark) abort dict
    if s:WarnIfValidMarkCharIsEmpty(a:mark, 'name-clearing')
        return
    endif
    let l:mark_data = l:self.getMarkData(a:mark)
    call s:UpdateNameAndRosterEntry(l:self._rosters, l:mark_data, '')
endfunction
let s:MarkbarModel.resetMark = function('markbar#MarkbarModel#resetMark')

" BRIEF:    Delete the given mark, and remove it from the cache.
" DETAILS:  Changes won't appear until the markbar has been repopulated.
"           Must be invoked while the cursor is inside a markbar.
" PARAM:    mark    (v:t_string)    The single character representing the mark.
function! markbar#MarkbarModel#deleteMark(mark) abort dict
    if s:WarnIfValidMarkCharIsEmpty(a:mark, 'deletion')
        return
    endif
    if a:mark ==# "'" || a:mark ==# '"'
        " '' explicitly cannot be deleted; '" is reset by wshada,
        " which effectively 'undeletes' it right after delmarks
        echohl WarningMsg
        echomsg printf('Cannot delete the %s mark.', a:mark)
        echohl None
        return
    endif

    let l:is_global = markbar#helpers#IsGlobalMark(a:mark)

    " delete actual mark itself
    let l:markbar_buffer = bufnr('%')
    let l:cur_pos = getcurpos()
    if !l:is_global
        let l:active_buffer = l:self.getActiveBuffer()
        execute win_gotoid(bufwinid(l:active_buffer))
    endif
    execute 'delmarks ' . a:mark
    execute win_gotoid(bufwinid(l:markbar_buffer))
    call setpos('.', l:cur_pos)

    " remove MarkData from the cache; clear its name
    let l:cache = l:self.getBufferCache(l:is_global ? 0 : l:active_buffer)
    try
        let l:mark_data = l:cache.marks_dict[a:mark]
        unlet l:cache.marks_dict[a:mark]
        call s:UpdateNameAndRosterEntry(l:self._rosters, l:mark_data, '')
    catch /E716/  " Key not present in dictionary
    endtry

    if markbar#settings#ForceClearSharedDataOnDelmark()
        if has('nvim')
            wshada!
        else
            wviminfo!
        endif
    endif
endfunction
let s:MarkbarModel.deleteMark = function('markbar#MarkbarModel#deleteMark')

" RETURNS:  (v:t_number)    The most recently accessed 'real' buffer.
function! markbar#MarkbarModel#getActiveBuffer() abort dict
    return l:self._active_buffer_stack.top()
endfunction
let s:MarkbarModel.getActiveBuffer = function('markbar#MarkbarModel#getActiveBuffer')

" EFFECTS:  Push the given buffer number onto the active buffer
"           ConditionalStack.
function! markbar#MarkbarModel#pushNewBuffer(buffer_no) abort dict
    if type(a:buffer_no) ==# v:t_list
        for l:no in a:buffer_no
            call l:self.pushNewBuffer(l:no)
        endfor
        return
    endif
    call markbar#ensure#IsNumber(a:buffer_no)
    call l:self._active_buffer_stack.push(a:buffer_no)
endfunction
let s:MarkbarModel.pushNewBuffer = function('markbar#MarkbarModel#pushNewBuffer')

" DETAILS:  Update model state to reflect a file being renamed.
function! markbar#MarkbarModel#changeFilename(old_filepath, new_filepath) abort dict
    call markbar#ensure#IsString(a:old_filepath)
    call markbar#ensure#IsString(a:new_filepath)
    call l:self._rosters.cloneRosterToNewName(a:old_filepath, a:new_filepath)
endfunction
let s:MarkbarModel.changeFilename = function('markbar#MarkbarModel#changeFilename')

" RETURNS:  (markbar#MarkData)  The MarkData object corresponding to the given
"                               mark character.
" DETAILS:  - If the requested mark is a local mark, then the MarkbarModel
"           object will search the BufferCache for the currently active
"           buffer.
"           - If the requested mark is a global (file or numbered) mark, then
"           the MarkbarModel object will search the global BufferCache.
"           - If the requested mark cannot be found, throw an exception.
function! markbar#MarkbarModel#getMarkData(mark_char) abort dict
    let l:is_global = markbar#helpers#IsGlobalMark(a:mark_char)
    let l:mark_buffer =
            \ l:is_global ? 0 : l:self.getActiveBuffer()
    let l:marks_dict =
        \ l:self.getBufferCache(l:mark_buffer).marks_dict
    if !has_key(l:marks_dict, a:mark_char)
        throw '(markbar#MarkbarModel) Could not find mark ' . a:mark_char
            \ . ' for buffer ' . l:mark_buffer
    endif
    let l:mark = l:marks_dict[a:mark_char]
    return l:mark
endfunction
let s:MarkbarModel.getMarkData = function('markbar#MarkbarModel#getMarkData')

" RETURNS:  (markbar#BufferCache)   BufferCache for the requested buffer.
" DETAILS:  Initializes a BufferCache for the buffer if one doesn't exist.
" PARAM:    buffer_no   (v:t_number)    The bufnr() of the requested buffer.
function! markbar#MarkbarModel#_getOrInitBufferCache(buffer_no) abort dict
    call markbar#ensure#IsNumber(a:buffer_no)
    let l:cache = get(l:self._buffer_caches, a:buffer_no, 0)
    if empty(l:cache)
        let l:cache = markbar#BufferCache#New(a:buffer_no, l:self._rosters)
        let l:self._buffer_caches[a:buffer_no] = l:cache
    endif
    return l:cache
endfunction
let s:MarkbarModel._getOrInitBufferCache = function('markbar#MarkbarModel#_getOrInitBufferCache')

" RETURNS:  (markbar#BufferCache)   BufferCache for the requested buffer.
" DETAILS:  Throws an exception if a matching BufferCache isn't found.
" PARAM:    buffer_no   (v:t_number)    The bufnr() of the requested buffer.
function! markbar#MarkbarModel#getBufferCache(buffer_no) abort dict
    call markbar#ensure#IsNumber(a:buffer_no)
    let l:cache = get(l:self._buffer_caches, a:buffer_no, 0)
    if empty(l:cache)
        throw printf('Buffer not cached: %s', a:buffer_no)
    endif
    return l:cache
endfunction
let s:MarkbarModel.getBufferCache = function('markbar#MarkbarModel#getBufferCache')

" RETURNS:  (v:t_bool)  `v:true` if a cache was removed, `v:false` otherwise.
function! markbar#MarkbarModel#evictBufferCache(buffer_no) abort dict
    if !has_key(l:self._buffer_caches, a:buffer_no)
        return v:false
    endif
    call remove(l:self._buffer_caches, a:buffer_no)
    return v:true
endfunction
let s:MarkbarModel.evictBufferCache = function('markbar#MarkbarModel#evictBufferCache')

" DETAILS:  Update BufferCaches for the current buffer and for global marks.
"           Creates BufferCaches for the current buffer and global marks if
"           they don't yet exist.
function! markbar#MarkbarModel#updateCurrentAndGlobal() abort dict
    let l:bufnr = bufnr('%')
    let l:cur_buffer_cache = l:self._getOrInitBufferCache(l:bufnr)
    "                                                     ^ This is bufnr('%')
    " and not getActiveBuffer() because helpers#GetLocalMarks() pulls |:marks|
    " output for the currently focused window, which might e.g.  be the
    " markbar window, which _active_buffer_stack.top() wouldn't return as a
    " 'real buffer'.
    "
    " If getActiveBuffer() and bufnr('%') were different, then
    " cur_buffer_cache.updateCache might e.g. clobber the last active buffer's
    " BufferCache with the (probably nonexistent) marks for the markbar window.
    let l:global_buffer_cache = l:self._getOrInitBufferCache(0)

    " retrieve the greatest number of lines of context that we may need
    " for all marks, for simplicity
    let l:max_num_context = max(markbar#settings#NumLinesContext())

    let l:bufname = bufname(l:bufnr)
    let l:filename = expand('%:p')
    call l:cur_buffer_cache.updateCache(markbar#helpers#GetLocalMarks(),
                                      \ l:bufname, l:filename)
    call l:global_buffer_cache.updateCache(markbar#helpers#GetGlobalMarks(),
                                         \ '', '')
    call l:cur_buffer_cache.updateContexts(l:max_num_context)
    call l:global_buffer_cache.updateContexts(l:max_num_context)
endfunction
let s:MarkbarModel.updateCurrentAndGlobal = function('markbar#MarkbarModel#updateCurrentAndGlobal')
