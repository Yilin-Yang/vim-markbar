let s:BufferCache = {
    \ 'TYPE': 'BufferCache',
    \ 'marks_dict': {},
    \ '_buffer_no': 0,
    \ '_rosters': v:null,
\ }

" EFFECTS:  Construct and return a BufferCache.
" DETAILS:  BufferCache stores marks and contexts for a particular buffer in
"           a dictionary `marks_dict`. `a_buf_cache['a']` returns a
"           (markbar#MarkData) for mark `a`. The dictionary is exposed
"           directly because encapsulating it with getters and setters is
"           more trouble than it's worth.
" PARAM:    buffer_no   (v:t_number)    This BufferCache's buffer's |bufnr()|.
" PARAM:    rosters     (ShaDaRosters)  Mark names from/for the ShaDa file.
function! markbar#BufferCache#New(buffer_no, rosters) abort
    call markbar#ensure#IsNumber(a:buffer_no)
    let l:new = deepcopy(s:BufferCache)
    let l:new._buffer_no = a:buffer_no
    let l:new._rosters = a:rosters
    return l:new
endfunction

" RETURNS:  (markbar#MarkData)  MarkData of the requested mark.
function! markbar#BufferCache#getMark(mark) abort dict
    let l:is_quote = a:mark ==# "'" || a:mark ==# '`'
    let l:mark = (l:is_quote) ? "'" : a:mark
    try
        let l:md = l:self.marks_dict[l:mark]
    catch /E716/ " Key not present in dictionary
        throw 'Requested mark not in cache: ' . a:mark
    endtry
    return l:md
endfunction
let s:BufferCache.getMark = function('markbar#BufferCache#getMark')

" EFFECTS:  Repopulate BufferCache's `marks_dict`. Will retrieve marks data
"           for the currently active buffer.
" PARAM:    marks_and_getpos    (v:t_dict)      Keys are mark chars; values
"                                               are |getpos()| output for that
"                                               mark.
" PARAM:    bufname             (v:t_string)    Bufname of the buffer being
"                                               queried by |:marks|. Ignored
"                                               for global marks.
" PARAM:    filepath            (v:t_string)    Full filepath for the buffer
"                                               being queried by |:marks|.
"                                               Ignored for global marks.
function! markbar#BufferCache#updateCache(marks_and_getpos, bufname,
                                        \ filepath) abort dict
    call markbar#ensure#IsDictionary(a:marks_and_getpos)
    call markbar#ensure#IsString(a:bufname)
    call markbar#ensure#IsString(a:filepath)
    let l:roster_key = l:self.isGlobal() ? 0 : a:filepath

    let l:new_marks_dict = {}
    for [l:mark_char, l:getpos] in items(a:marks_and_getpos)
        let l:markdata = markbar#MarkData#New(l:mark_char, l:getpos, a:bufname,
                                            \ a:filepath)
        let l:new_marks_dict[l:mark_char] = l:markdata
    endfor

    " copy over existing mark names
    let l:old_dict = l:self.marks_dict
    for l:mark in keys(l:old_dict)
        if !has_key(l:new_marks_dict, l:mark)
            " mark was deleted since the last update, so clear it from
            " the roster
            call l:self._rosters.setName(l:roster_key, l:mark, '')
            continue
        endif
        let l:old_name = l:old_dict[l:mark].getUserName()

        call l:new_marks_dict[l:mark].setUserName(l:old_name)
    endfor

    " We assert that the names in l:self._rosters at this point are not
    " 'stale': they've either been cleared while iterating over l:old_dict,
    " or cleared/renamed by a call to g:markbar_model.delete/reset/renameMark()

    " iterate over current marks, set names from rosters
    for [l:mark, l:mark_data] in items(l:new_marks_dict)
        if empty(l:mark_data.getUserName())
            let l:old_name = l:self._rosters.getName(l:roster_key, l:mark)
            call l:mark_data.setUserName(l:old_name)
        endif
    endfor

    let l:self.marks_dict = l:new_marks_dict
endfunction
let s:BufferCache.updateCache = function('markbar#BufferCache#updateCache')

" EFFECTS:  - Retrieve new contexts for this BufferCache's marks.
"           - Clear cached mark contexts for marks that shouldn't exist anymore.
"           - Fetch updated contexts for all marks.
" PARAM:    num_lines   (v:t_number)    Number of lines of context to retrieve.
function! markbar#BufferCache#updateContexts(num_lines) abort dict
    let l:using_global_marks = l:self.isGlobal()
    let l:buffer_no = l:self._buffer_no
    for l:mark in keys(l:self.marks_dict)
        let l:mark_data = l:self.marks_dict[l:mark]
        let l:line_no = l:mark_data.getLineNo()

        " if these are global marks, perform file lookup for each mark
        if l:using_global_marks
            let l:buffer_no = markbar#helpers#BufferNo(l:mark)
        endif

        let l:context = markbar#helpers#FetchContext(
            \ l:buffer_no,
            \ l:line_no,
            \ a:num_lines
        \ )
        call l:mark_data.setContext(l:context)
    endfor
endfunction
let s:BufferCache.updateContexts = function('markbar#BufferCache#updateContexts')

function! markbar#BufferCache#isGlobal() abort dict
    return l:self._buffer_no ==# 0
endfunction
let s:BufferCache.isGlobal = function('markbar#BufferCache#isGlobal')
