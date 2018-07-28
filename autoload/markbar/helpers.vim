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
" RETURNS:  (v:t_list)      The requested line range from the requested
"                           buffer as a list, one line per list element,
"                           without trailing linebreaks.
function! markbar#helpers#FetchBufferLineRange(buffer_no, start, end) abort
    " if buffer is loaded,
    let l:lines = getbufline(a:buffer_no, a:start, a:end)
    if len(l:lines) | return l:lines | endif

    " buffer isn't loaded, and/or file doesn't exist.
    let l:filename = bufname(a:buffer_no)
    if empty(l:filename) | return [] | endif

    if !has('win32')
        let l:text  = system('sed -n ' .a:start.','.a:end.'p '. l:filename),
        " keep leading blank lines, remove always-spurious empty last line
        let l:lines = split(l:text, '\r\{0,1}\n', 1)
        call remove(l:lines, -1)
    else
        " assume that `sed` is unavailable on windows
        " readfile() loads entire file into memory, making it more expensive
        " than printing line range with `sed`
        let l:lines = readfile(l:filename)[a:start : a:end]
    endif

    return l:lines
endfunction

" EFFECTS:  Retrieve the lines surrounding the requested line.
" RETURNS:  (v:t_list)      The requested context from the requested
"                           buffer as a list, one line per list element,
"                           without trailing linebreaks.
" PARAM:    around_line (v:t_number)    Fetch context from around this
"                                       'target' line number.
" PARAM:    num_lines   (v:t_number)    The total number of lines of context
"                                       to grab, *including* the target line.
"                                       Must be greater than or equal to 1.
function! markbar#helpers#FetchContext(buffer_no, around_line, num_lines) abort
    if type(a:num_lines) !=# v:t_number
        throw '`a:num_lines` must be an integer. Gave value: ' . a:num_lines
    elseif a:num_lines <# 1
        throw 'Required that `a:num_lines >= 1`. Gave value: ' . a:num_lines
    endif

    if type(a:around_line) !=# v:t_number
        throw '`a:around_line` must be an integer. Gave value: ' . a:around_line
    elseif a:around_line <# 1
        throw 'Required that target line no. be positive. Gave value: '
            \ . a:around_line
    endif

    let l:half_context = a:num_lines / 2
    let l:end = a:around_line + l:half_context
    let l:start = max( [ a:around_line - l:half_context, 1 ] )

    " if resulting range is one line too large (i.e. caller gave
    " even a:num_lines), scooch l:start down by one
    if l:end - l:start >=# a:num_lines
        let l:start += 1
    endif

    return markbar#helpers#FetchBufferLineRange(a:buffer_no, l:start, l:end)
endfunction
