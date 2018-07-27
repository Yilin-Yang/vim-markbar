" RETURNS:  (v:t_string)    All buffer-local marks active within the current
"                           file as a 'raw' string.
function! markbar#helpers#GetLocalMarks() abort
    redir => l:to_return
    silent marks abcdefghijklmnopqrstuvwxyz<>'"^.(){}
    redir end
    return l:to_return
endfunction

" RETURNS:  (v:t_string)    All global marks as a 'raw' string.
function! markbar#helpers#GetGlobalMarks() abort
    redir => l:to_return
    silent marks ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
    redir end
    return l:to_return
endfunction

" RETURNS:  (v:t_bool)              `v:true` if the given mark *is global* and
"                                   is located within the current buffer.
" PARAM:    mark    (v:t_string)    The single character identifying the mark.
function! markbar#helpers#InCurrentBuffer(mark) abort
    if (len(a:mark) !=# 1)
        throw 'Invalid mark: ' . a:mark
    endif
    return getpos("'" . a:mark)[0] ==# bufnr('%') ? v:true : v:false
endfunction

" RETURNS:  (v:t_string)    The name of the file in which the requested mark
"                           can be found. May be an empty string, if the given
"                           mark exists in a scratch buffer.
function! markbar#helpers#ParentFilename(mark) abort
    let l:buf_no = getpos("'" . a:mark)[0]
    if !l:buf_no
        throw 'Mark not found: ' . a:mark
    endif
    return bufname(l:buf_no)
endfunction

" EFFECTS:  Retrieve the given line range (inclusive) from the requested
"           buffer.
" RETURNS:  (v:t_string)    The entire requested line range from the requested
"                           buffer, including all newline characters.
function! markbar#helpers#FetchBufferLineRange(buffer_no, start, end) abort
    return system('sed -n ' .a:start.','.a:end.'p '. bufname(a:buffer_no))
endfunction
