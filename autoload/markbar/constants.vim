" BRIEF:    The search pattern to use when matching the columns header and
"           leading whitespace.
fu! markbar#constants#MARKS_COLUMNS_HEADER_SEARCH_PATTERN()
    return '\%(\s\|\n\|\r\)\{-}\<\S\+\>\s\{-}\<\S\+\>\s\{-}\<\S\+\>\s\{-}\<\S\+\>\r\{0,1}\n\{0,1}'
endf

" BRIEF:    The search pattern to use when trying to find the line number of a
"           mark heading.
fu! markbar#constants#MARK_HEADING_SEARCH_PATTERN()
    return '^\[''.\]'
endf

" BRIEF:    The search pattern to use when trying to find the line number of a
"           specific mark heading.
fu! markbar#constants#MARK_SPECIFIC_HEADING_SEARCH_PATTERN(mark)
    return '^\[''' . a:mark . '\]'
endf

" BFIEF:    String containing all possible mark characters.
fu! markbar#constants#ALL_MARKS_STRING()
    return 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789[]<>''`"^.(){}'
endf

" BRIEF:    Same as ALL_MARKS_STRING but each character is a key in a dict.
fu! markbar#constants#ALL_MARKS_DICT()
    if !exists('s:all_marks_dict')
        let s:all_marks_dict = {}
        let s:all_marks_list = split(markbar#constants#ALL_MARKS_STRING(), '\zs')
        for l:c in s:all_marks_list
            let s:all_marks_dict[l:c] = v:null
        endfor
        lockvar! s:all_marks_dict
    endif
    return s:all_marks_dict
endf
