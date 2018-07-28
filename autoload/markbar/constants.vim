" BRIEF:    The search pattern to use when matching the columns header and
"           leading whitespace.
fu! markbar#constants#MARKS_COLUMNS_HEADER_SEARCH_PATTERN()
    return '\%(\s\|\n\|\r\)\{-}mark line  col file/text\r\{0,1}\n\{0,1}'
endf

" BRIEF:    The null 'buffer number' used to index the global mark database.
fu! markbar#constants#GLOBAL_MARKS()
    return 0
endf
