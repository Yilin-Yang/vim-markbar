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

" RETURNS:  (v:t_dict)      The given `marks` string, converted into a
"                           dictionary of lists.
" DETAILS:  - Each dictionary entry corresponds to a single mark.
"           - Each element in an entry is one of that mark's fields, in the
"           following order (by index):
"               0.  the mark itself
"               1.  the mark's line number
"               2.  the mark's column number
"               3.  the mark's 'file/text'
" PARAM:    trimmed_marks   (v:t_string)    A `marks` string, without its
"                                           column header.
function! markbar#textmanip#MarksStringToDictionary(trimmed_marks) abort
    let l:marks = split(a:trimmed_marks, '\r\{0,1}\n') " split on linebreaks
    let l:dict = {}
    let l:i = 0
    while l:i <# len(l:marks)
        let l:marklist = matchlist(
            \ l:marks[l:i],
            \ '\(\S\+\)\s\+\(\S\+\)\s\+\(\S\+\)\s*\(.*\)'
        \ )[1:4]
        if !empty(l:marklist)
            let l:dict[l:marklist[0]] = l:marklist
        endif
        let l:i += 1
    endwhile
    return l:dict
endfunction
