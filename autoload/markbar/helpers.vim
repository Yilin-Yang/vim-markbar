" RETURNS:  (v:t_string)    Output of executing the given command.
" DETAILS:  We wrap the redir in try-catch to catch erroneous `E121:
"           Undefined variable` messages that appear when (neo)vim tries to
"           look up a local variable from a previous stack frame's `redir =>`
"           invocation.
"
"           See: https://github.com/Yilin-Yang/vim-markbar/issues/33
function! markbar#helpers#Redir(command) abort
    let l:redir_output = ''
    try
        redir => l:redir_output
        execute a:command
        redir end
    catch /E121/
        redir => l:redir_output
        execute a:command
        redir end
    endtry
    return l:redir_output
endfunction


" RETURNS:  (v:t_list)      A list populated with the numbers of every
"                           buffer, listed or unlisted.
function! markbar#helpers#GetOpenBuffers() abort
    let l:buffers_str = markbar#helpers#Redir('silent ls!')
    let l:buffers_str_list = split(l:buffers_str, '\r\{0,1}\n')
    let l:buffers_list = []
    for l:str in l:buffers_str_list
        call add(l:buffers_list, matchstr(l:str, '[0-9]\+') + 0)
    endfor
    return l:buffers_list
endfunction

" RETURNS:  (v:t_string)    A 'synthetic' markstring, mimicking the output of
"                           `:marks`, for the given mark (in the active buffer.)
" PARAM:    mark    (v:t_string)    The mark to retrieve (single character.)
function! markbar#helpers#MakeMarkString(mark) abort
    " currently doesn't handle edge case where mark is `"`
    let l:markpos = getpos("'".a:mark)
    let l:fmt_str = ' %s %d %d %s'
    let l:file_text = getline(l:markpos[1])
    return printf(l:fmt_str, a:mark, l:markpos[1], l:markpos[2], l:file_text)
endfunction

" RETURNS:  (v:t_dict)  Keys are mark chars; values are |getpos()| output for
"                       the given marks.
function! markbar#helpers#GetRawMarkData(for_mark_chars) abort
    call markbar#ensure#IsString(a:for_mark_chars)
    let l:to_return = {}
    " iterate by index for compatibility with v8.1.0039
    let l:i = 0
    while l:i <# len(a:for_mark_chars)
        let l:mark_char = a:for_mark_chars[l:i]
        let l:i += 1

        let l:getpos = getpos("'".l:mark_char)
        if l:getpos[1] ==# 0 && l:getpos[2] ==# 0
            " Don't compare to [0, 0, 0, 0]; in vim v8.1.0039, getpos() might
            " return e.g. [5, 0, 0, 0] for a file mark that was just deleted.
            continue
        endif
        let l:to_return[l:mark_char] = l:getpos
    endwhile
    return l:to_return
endfunction

" RETURNS:  (v:t_dict)  Dict between mark chars and |getpos()| lists for all
"                       buffer-local marks set in the current buffer.
function! markbar#helpers#GetLocalMarks() abort
    return markbar#helpers#GetRawMarkData(
            \ "abcdefghijklmnopqrstuvwxyz[]<>'`\"^.(){}")
endfunction

" RETURNS:  (v:t_dict)  Dict between mark chars and |getpos()| lists for all
"                       global marks.
function! markbar#helpers#GetGlobalMarks() abort
    return markbar#helpers#GetRawMarkData('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')
endfunction

" RETURNS:  (v:t_bool)      `v:true` if the given mark corresponds to a
"                           'special' mark, like `']`, `'(`, or `'^`.
" PARAM:    mark    (v:t_string)    The single character identifying the mark,
"                                   not including the leading single quote.
function! markbar#helpers#IsSpecialMark(mark) abort
    if len(a:mark) !=# 1
        throw '(markbar#helpers#IsSpecialMark) Invalid mark char: ' . a:mark
    endif

    let l:old_ignore_case = &ignorecase
    set noignorecase
    let l:idx = match('''"(){}.[]<>^', '\V' . a:mark)
    let &ignorecase = l:old_ignore_case

    return l:idx !=# -1
endfunction

" RETURNS:  (v:t_bool)      `v:true` if the given mark corresponds to a global
"                           mark (i.e. a file mark, or a ShaDa numerical mark),
"                           and `false` otherwise.
" PARAM:    mark    (v:t_string)    The single character identifying the mark,
"                                   not including the leading single quote.
function! markbar#helpers#IsGlobalMark(mark) abort
    if len(a:mark) !=# 1
        throw '(markbar#helpers#IsGlobalMark) Invalid mark char: ' . a:mark
    endif

    let l:old_ignore_case = &ignorecase
    set noignorecase
    let l:idx = match('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', '\V' . a:mark)
    let &ignorecase = l:old_ignore_case

    return l:idx !=# -1
endfunction

" RETURNS:  (v:t_bool)      `v:true` if the given mark corresponds to an
"                           uppercase file mark.
" PARAM:    mark    (v:t_string)    The single character identifying the mark,
"                                   not including the leading single quote.
function! markbar#helpers#IsUppercaseMark(mark) abort
    if len(a:mark) !=# 1
        throw '(markbar#helpers#IsUppercaseMark) Invalid mark char: ' . a:mark
    endif

    let l:old_ignore_case = &ignorecase
    set noignorecase
    let l:idx = match('ABCDEFGHIJKLMNOPQRSTUVWXYZ', '\V' . a:mark)
    let &ignorecase = l:old_ignore_case

    return l:idx !=# -1
endfunction

" RETURNS:  (v:t_bool)      `v:true` if the given mark corresponds to a
"                           numbered mark.
" PARAM:    mark    (v:t_string)    The single character identifying the mark,
"                                   not including the leading single quote.
function! markbar#helpers#IsNumberedMark(mark) abort
    if len(a:mark) !=# 1
        throw '(markbar#helpers#IsNumberedMark) Invalid mark char: ' . a:mark
    endif
    let l:idx = match('0123456789', '\V' . a:mark)
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

" RETURNS:  (v:t_bool)      `v:true` if the given buffer is a 'real' buffer,
"                           i.e. a buffer in which vim-markbar should track
"                           marks.
" DETAILS:  - Buffer number `0`, despite not being a 'real' buffer, is always
"           treated as 'real' since it corresponds to the global buffer cache.
function! markbar#helpers#IsRealBuffer(buffer_expr) abort
    if a:buffer_expr ==# '0' | return v:true | endif
    return bufexists(bufnr(a:buffer_expr))
        \  && !getbufvar(a:buffer_expr, 'is_markbar')
        \  && !has_key(
                \ markbar#settings#IgnoreBufferCriteria(),
                \ getbufvar(a:buffer_expr, '&bufhidden'))
endfunction

" RETURNS:  (v:t_number)    The buffer number of the buffer that contains the
"                           requested mark.
" PARAM:    mark    (v:t_string)    The single character identifying the mark,
"                                   not including the leading single quote.
function! markbar#helpers#BufferNo(mark) abort
    if len(a:mark) !=# 1
        throw 'Invalid mark: ' . a:mark
    endif
    let l:mark_pos = getpos("'" . a:mark)
    if l:mark_pos ==# [0, 0, 0, 0]
        throw 'Mark not found: ' . a:mark
    elseif l:mark_pos[0] ==# 0
        " current buffer
        return bufnr('%')
    endif
    return l:mark_pos[0]
endfunction

" RETURNS:  (v:t_list)      A two-element list, containing:
"                               0. All characters in `a:string` up to, but not
"                               including, the given index.
"                               1. All characters from the given index
"                               (inclusive) till the end of the string.
"
"                           If no characters would fall in one substring or
"                           the other, then that element will be the empty
"                           string.
function! markbar#helpers#SplitString(string, idx) abort
    call markbar#ensure#IsString(a:string)
    call markbar#ensure#IsNumber(a:idx)
    if a:idx <=# 0
        return [ '', a:string ]
    endif
    return [ a:string[0:a:idx-1], a:string[a:idx :] ]
endfunction

" EFFECTS:  Totally replace the contents of the given buffer with the given
"           lines.
function! markbar#helpers#ReplaceBuffer(buffer_expr, lines) abort
    if has('nvim')
        call nvim_buf_set_lines(a:buffer_expr, 0, -1, 0, a:lines)
    else
        silent call deletebufline(a:buffer_expr, 1, '$')
        silent call setbufline(a:buffer_expr, 1, a:lines)
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
    let l:lines = getbufline(bufnr(a:buffer_expr), a:start, a:end)
    if len(l:lines) | return l:lines | endif

    " buffer isn't loaded, and/or file doesn't exist.
    let l:filename = bufname(a:buffer_expr)
    if empty(l:filename) | return [] | endif

    " readfile is several times faster than `sed`, at least on WSL
    try
        let l:lines = readfile(l:filename)[a:start - 1 : a:end - 1]
    catch
        let l:lines = ['[buffer line read failed]']
    endtry

    return l:lines
endfunction

" EFFECTS:  Retrieve the lines surrounding the requested line.
" RETURNS:  (v:t_list)  Context from the requested buffer as a list of strings,
"                       one line per string, without trailing linebreaks.
" PARAM:    buffer_expr (expr)          See `:help bufname()`.
" PARAM:    around_line (v:t_number)    Fetch context from around this
"                                       'target' line number.
" PARAM:    num_lines   (v:t_number)    The total number of lines of context
"                                       to grab, *including* the target line.
"                                       Must be greater than or equal to 1.
function! markbar#helpers#FetchContext(buffer_expr, around_line, num_lines) abort
    if type(a:num_lines) !=# v:t_number
        throw '`a:num_lines` must be an integer. Gave value: ' . a:num_lines
    elseif a:num_lines ==# 0
        return []
    elseif a:num_lines <# 0
        throw 'Required that `a:num_lines >= 0`. Gave value: ' . a:num_lines
    endif

    if a:around_line <# 1
        throw 'Required that target line no. be positive. Gave value: '
            \ . a:around_line
    endif

    let l:half_context = a:num_lines / 2
    let l:end = a:around_line + l:half_context
    let l:start = a:around_line - l:half_context

    " if resulting range is one line too large (i.e. caller gave
    " even a:num_lines), scooch l:start down by one
    if l:end - l:start >=# a:num_lines
        let l:start += 1
    endif

    let l:context_prefix = []
    while l:start <# 1
        call add(l:context_prefix, '~')
        let l:start += 1
    endwhile

    let l:context =
        \ l:context_prefix
        \ + markbar#helpers#FetchBufferLineRange(a:buffer_expr, l:start, l:end)

    while len(l:context) <# a:num_lines
        call add(l:context, '~')
    endwhile

    return l:context
endfunction

" RETURNS: The mark's line index in the given context.
function! markbar#helpers#MarkLineIdxInContext(context) abort
    call markbar#ensure#IsList(a:context)
    let l:context_len = len(a:context)
    if !l:context_len
        return l:context_len
    endif

    let l:odd_num_lines = l:context_len % 2
    " bump up by one if the context has even length
    return l:context_len / 2 - ((l:odd_num_lines) ? 0 : 1)
endfunction

" RETURNS:  A list of two values, [start_idx, end_idx] (end-exclusive).
"           Printing this range from a context list of original length
"           `context_len` will produce `length` lines of context, with the
"           mark's line being at the proper location in that printed context.
function! markbar#helpers#TrimmedContextRange(context_len, length) abort
    call markbar#ensure#IsNumber(a:context_len)
    call markbar#ensure#IsNumber(a:length)

    if a:length <# 0
        throw 'Cannot give negative target length for trimmed context.'
    endif

    if a:context_len <=# a:length
        return [0, a:context_len]
    endif

    let l:to_remove = a:context_len - a:length
    let l:from_front = l:to_remove / 2
    let l:from_back = l:to_remove - l:from_front

    return [l:from_front, a:context_len - l:from_back]
endfunction

" RETURNS:  A functor that takes a MarkData and returns the number of lines of
"           context to print for that MarkData.
" PARAM:    config          (v:t_dict)  A markbar#settings#NumLinesContext dict.
" PARAM:    is_peekaboo     (v:t_bool)  True if this is for the peekaboo
"                                       markbar, false otherwise.
function! markbar#helpers#NumContextFunctor(config, is_peekaboo) abort
    return a:is_peekaboo ? function('s:NumContextPeekaboo', [a:config])
                       \ : function('s:NumContextNormal',   [a:config])
endfunction

function! s:NumContextNormal(config, mark_data) abort
    return a:mark_data.isGlobal() ? a:config.around_file : a:config.around_local
endfunction

function! s:NumContextPeekaboo(config, mark_data) abort
    return a:mark_data.isGlobal() ? a:config.peekaboo_around_file
                                \ : a:config.peekaboo_around_local
endfunction


let s:viml_type_to_string = {
    \ 0: 'v:t_number',
    \ 1: 'v:t_string',
    \ 2: 'v:t_func',
    \ 3: 'v:t_list',
    \ 4: 'v:t_dict',
    \ 5: 'v:t_float',
    \ 6: 'v:t_bool',
    \ 7: 'v:null',
\ }

" RETURNS:  String like 'v:t_number' corresponding to the given |type()| value.
function! markbar#helpers#VimLTypeToString(type_val) abort
    call markbar#ensure#IsNumber(a:type_val)
    let l:string = get(s:viml_type_to_string, a:type_val, v:null)
    if l:string is v:null
        throw printf('Nonexistent variable |type()| with val: %d', a:type_val)
    endif
    return l:string
endfunction
