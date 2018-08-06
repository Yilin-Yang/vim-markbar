" EFFECTS:  Strip leading whitespace and the columns header (i.e. the line
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
