" EFFECTS:  Strips leading whitespace and the columns header (i.e. the line
"           that starts with 'mark line  col [...]') from the given string.
" PARAM:    raw_marks   (v:t_string)    The raw `marks` command output to
"                                       process.
function! markbar#textmanip#TrimMarksHeader(raw_marks) abort
    if type(a:raw_marks) !=# v:t_string
        throw 'a:raw_marks must be a string! Received value: ' . a:raw_marks
    endif
    let l:trimmed = substitute(
        \ a:raw_marks,
        \ markbar#constants#MARKS_COLUMNS_HEADER_SEARCH_PATTERN(),
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
function! markbar#textmanip#MarksStringToNestedList(trimmed_marks) abort
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
