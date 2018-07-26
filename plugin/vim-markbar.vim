if exists('g:vim_markbar_autoloaded')
    finish
endif
let g:vim_markbar_autoloaded = 1

"==============================================================================
" GLOBAL VARIABLES: ==========================================================
"==============================================================================

" BRIEF:    The search pattern to use when matching the columns header and
"           leading whitespace.
fu! g:MARKS_COLUMNS_HEADER_SEARCH_PATTERN()
    return '.\{-}mark line  col file/text.\{-}\n*\r*'
endf

" BRIEF:    The null 'buffer number' used to index the global mark database.
fu! g:GLOBAL_MARKS()
    return 0
endf

" BRIEF:    Association between buffer numbers and their local mark databases.
" DETAILS:  The buffer with number '0' holds 'global' marks, such as file marks.
let g:buffersToDatabases = { GLOBAL_MARKS() : [] }


"==============================================================================
" FUNCTIONS: =================================================================
"==============================================================================

" RETURNS:  (v:t_string)    All buffer-local marks active within the current
"                           file as a 'raw' string.
function! g:GetLocalMarks()
    redir => l:to_return
    silent marks abcdefghijklmnopqrstuvwxyz<>'"^.(){}
    redir end
    return l:to_return
endfunction

" RETURNS:  (v:t_string)    All global marks as a 'raw' string.
function! g:GetGlobalMarks()
    redir => l:to_return
    silent marks ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
    redir end
    return l:to_return
endfunction

" EFFECTS:  Strips leading whitespace and the columns header (i.e. the line
"           that starts with 'mark line  col [...]') from the given string.
" PARAM:    raw_marks   (v:t_string)    The raw `marks` command output to
"                                       process.
function! g:TrimMarksHeader(raw_marks) abort
    if type(a:raw_marks) !=# v:t_string
        throw 'a:raw_marks must be a string! Received value: ' . a:raw_marks
    endif
    let l:trimmed = substitute(
        \ a:raw_marks,
        \ MARKS_COLUMNS_HEADER_SEARCH_PATTERN(),
        \ '',
        \ ''
    \ )
    " NOTE: this does not catch the edge case in which the column header
    " string is, itself, contained in a valid 'file/text' cell.
    if l:trimmed ==# a:raw_marks
        throw 'Failed to trim leading whitespace and/or column header from '
            \ . 'input string: ' . a:raw_marks
    endif
    return l:trimmed
endfunction

" RETURNS:  (v:t_list)      The given `marks` string, converted into a
"                           two-dimensional list-of-lists.
" DETAILS:  The following is written assuming row-major indexing conventions.
"           - Each 'row' corresponds to a single mark.
"           - Each 'column' in that row is one of that mark's fields, in the
"           following order (by index):
"               0.  the mark itself
"               1.  the mark's line number
"               2.  the mark's column number
"               3.  the mark's 'file/text'
" PARAM:    trimmed_marks   (v:t_string)    A `marks` string, without its
"                                           column header.
function! g:MarksStringToNestedList(trimmed_marks)
    let l:marks = split(a:trimmed_marks, '\n\|\r') " split on linebreaks
    let l:i = 0
    while l:i <# len(l:marks)
        let l:marks[l:i] = matchlist(
            \ l:marks[l:i],
            \ '\(\S\+\)\s\+\(\S\+\)\s\+\(\S\+\)\s\+\(.*\)'
        \ )[1:4]
        let l:i += 1
    endwhile
    return l:marks
endfunction

" RETURNS:  (v:t_bool)      `v:true` if the given line number, in the *current
"                           buffer*, has a mark. `v:false` otherwise.
function! g:LineHasMark(line_no)
    let l:cur_buffer = bufnr('%')
    let l:marks_ptr = g:buffersToDatabases[l:cur_buffer] " alias
    let l:i = 0
    while l:i <# len(l:marks_ptr)
        if l:marks_ptr[l:i][1] ==# a:line_no
            return v:true
        endif
    endwhile

    let l:marks_ptr = g:buffersToDatabases[0] " alias
    let l:cur_file_abs = expand('%:p')
    let l:i = 0
    while l:i <# len(l:marks_ptr)
        let l:mark_ptr = l:marks_ptr[l:i]
        if l:cur_file_abs ==# l:mark_ptr[3] && l:mark_ptr[1] ==# a:line_no
            return v:true
        endif
    endwhile

endfunction

" EFFECTS:  Totally reconstruct the local marks database for the current
"           buffer.
function! g:PopulateBufferDatabase()
    let l:cur_buffer = bufnr('%')
    let l:raw_local_marks = TrimMarksHeader(GetLocalMarks())
    let g:buffersToDatabases[l:cur_buffer] =
        \ MarksStringToNestedList(l:raw_local_marks)
endfunction

" EFFECTS:  Totally reconstruct the global marks database.
function! g:PopulateGlobalDatabase()
    let l:raw_global_marks = TrimMarksHeader(GetGlobalMarks())
    let g:buffersToDatabases[0] =
        \ MarksStringToNestedList(l:raw_global_marks)
endfunction

"==============================================================================
" AUTOCMDS: ==================================================================
"==============================================================================

" TODO: only trigger when performing actions that affect lines with marks
"
" augroup vim_markbar_database_populators
"     au!
"     autocmd BufEnter,InsertLeave,TextYankPost,TextChanged,TextChangedI
"         \ *
"         \ g:PopulateBufferDatabase() | g:PopulateGlobalDatabase()
" augroup end
