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

" RETURNS:  (v:t_bool)      `v:true` if the given mark corresponds to a global
"                           mark (i.e. a file mark, or a ShaDa numerical mark),
"                           and `false` otherwise.
function! markbar#helpers#IsGlobalMark(mark) abort
    if len(a:mark) !=# 1 | return v:false | endif
    let l:idx = match('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', a:mark)
    return l:idx !=# -1
endfunction

" RETURNS:  (v:t_bool)              `v:true` if the given mark *is global* and
"                                   is located within the current buffer.
" PARAM:    mark    (v:t_string)    The single character identifying the mark.
function! markbar#helpers#InCurrentBuffer(mark) abort
    if len(a:mark) !=# 1
        throw 'Invalid mark: ' . a:mark
    endif
    return getpos("'" . a:mark)[0] ==# bufnr('%') ? v:true : v:false
endfunction

" RETURNS:  (v:t_number)    The buffer number of the buffer that contains the
"                           requested mark.
" PARAM:    mark    (v:t_string)    The single character identifying the mark,
"                                   not including the leading single quote.
function! markbar#helpers#BufferNo(mark) abort
    if len(a:mark) !=# 1
        throw 'Invalid mark: ' . a:mark
    endif
    return getpos("'" . a:mark)[0]
endfunction

" RETURNS:  (v:t_string)    The name of the file in which the requested mark
"                           can be found. May be an empty string, if the given
"                           mark exists in a scratch buffer.
function! markbar#helpers#ParentFilename(mark) abort
    let l:buf_no = markbar#helpers#BufferNo(a:mark)
    if !l:buf_no
        throw 'Mark not found: ' . a:mark
    endif
    return bufname(l:buf_no)
endfunction

" EFFECTS:  - Replace the line range in the given buffer with the given lines.
"           - If the number of elements in the list is different from the
"           number of lines in the given range, add/remove lines as needed.
" DETAILS:  - See `:help nvim_buf_set_lines` (in neovim) or `:help setbufline`
"           (in vim).
"           - To insert a line at a given line number (pushing the original
"           line down without removing it), set both `a:start` and `a:end` to
"           the target line number.
"           - To replace a line at a given line number `line`, let
"           `a:start = line` and `a:end = line + 1`.
"           - To append lines at the end of the buffer, either manually
"           specify the 'line-past-the-end', or set both `a:start` and `a:end`
"           to 0.
"           - To insert lines before the last line of the buffer, use negative
"           indexing (e.g. `a:start = a:end = -1` inserts a line above the
"           last line in the buffer).
" PARAM:    start   (v:t_number)    The first line to replace, inclusive.
" PARAM:    end     (v:t_number)    The last line to replace, exclusive.
" PARAM:    lines   (v:t_list)      The 'new' lines to insert.
function! markbar#helpers#SetBufferLineRange(buffer_expr, start, end, lines) abort
    call assert_true(exists('*nvim_buf_set_lines') || exists('*setbufline'),
        \ '(vim-markbar) vim version is too old! '
        \ . '(Need nvim with `nvim_buf_set_lines`, or vim with `setbufline`.)')
    let l:target_buf = bufnr(a:buffer_expr)
    if has('nvim')
        call nvim_buf_set_lines(l:target_buf, a:start - 1, a:end - 1, 0, a:lines)
    else
        let l:cur_buffer = bufnr('%')
        let l:hidden = &hidden
        set hidden

        execute 'buffer ' . l:target_buf
        let l:num_lines = line('$')
        if    !a:start      | let l:start = l:num_lines + 1
        elseif a:start <# 0 | let l:start = a:start + l:num_lines + 1
        else                | let l:start = a:start
        endif

        if    !a:end        | let l:end = l:num_lines + 1
        elseif a:end   <# 0 | let l:end = a:end + l:num_lines + 1
        else                | let l:end = a:end
        endif

        if !(l:start ==# l:end)
            execute l:target_buf . 'bufdo normal! '.l:start.'GV'.(l:end - 1).'G"_x'
        endif
        call append(l:start - 1, a:lines)
        execute 'buffer ' . l:cur_buffer

        let &hidden = l:hidden
    endif
endfunction

" EFFECTS:  Retrieve the given line range (inclusive) from the requested
"           buffer.
" RETURNS:  (v:t_list)      The requested line range from the requested
"                           buffer as a list, one line per list element,
"                           without trailing linebreaks.
" PARAM:    buffer_expr (expr)          See `:h bufname()`.
function! markbar#helpers#FetchBufferLineRange(buffer_expr, start, end) abort
    " if buffer is loaded,
    let l:lines = getbufline(a:buffer_expr, a:start, a:end)
    if len(l:lines) | return l:lines | endif

    " buffer isn't loaded, and/or file doesn't exist.
    let l:filename = bufname(a:buffer_expr)
    if empty(l:filename) | return [] | endif

    if !has('win32')
        let l:text  = system('sed -n ' .a:start.','.a:end.'p '. l:filename)
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
" PARAM:    buffer_expr (expr)          See `:help bufname()`.
" PARAM:    around_line (v:t_number)    Fetch context from around this
"                                       'target' line number.
" PARAM:    num_lines   (v:t_number)    The total number of lines of context
"                                       to grab, *including* the target line.
"                                       Must be greater than or equal to 1.
function! markbar#helpers#FetchContext(buffer_expr, around_line, num_lines) abort
    if type(a:num_lines) !=# v:t_number
        throw '`a:num_lines` must be an integer. Gave value: ' . a:num_lines
    elseif a:num_lines <# 1
        throw 'Required that `a:num_lines >= 1`. Gave value: ' . a:num_lines
    endif

    if a:around_line <# 1
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

    if l:start <# 1
        let l:start = 1
    endif

    return markbar#helpers#FetchBufferLineRange(a:buffer_expr, l:start, l:end)
endfunction
