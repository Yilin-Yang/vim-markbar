" BRIEF:    Controller for the 'vim-peekaboo' markbar.
" DETAILS:  Handles creation and population of the 'compact' markbar opened
"           when the user hits the apostrophe or backtick keys.

" BRIEF:    Construct a PeekabooMarkbarController object.
function! markbar#PeekabooMarkbarController#new(model, view) abort
    let l:new = markbar#MarkbarController#new(a:model, a:view)
    let l:new['DYNAMIC_TYPE'] += ['PeekabooMarkbarController']

    let l:new['_getHelpText'] =
        \ function('markbar#PeekabooMarkbarController#_getHelpText')
    let l:new['_getDefaultNameFormat'] =
        \ function('markbar#PeekabooMarkbarController#_getDefaultNameFormat')
    let l:new['_getMarkbarContents'] =
        \ function('markbar#PeekabooMarkbarController#_getMarkbarContents')

    let l:new['_openMarkbarSplit'] =
        \ function('markbar#PeekabooMarkbarController#_openMarkbarSplit')
    let l:new['_setMarkbarMappings'] =
        \ function('markbar#PeekabooMarkbarController#_setMarkbarMappings')

    return l:new
endfunction

function! markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(object) abort
    if type(a:object) !=# v:t_dict || index(a:object['DYNAMIC_TYPE'], 'PeekabooMarkbarController') ==# -1
        throw '(markbar#PeekabooMarkbarController) Object is not of type PeekabooMarkbarController: ' . a:object
    endif
endfunction

" RETURNS:  (v:t_list)      Lines of helptext to display at the top of the
"                           markbar.
function! markbar#PeekabooMarkbarController#_getHelpText(...) abort dict
    call markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(l:self)
    return [ '" Press a key to jump to that mark.' ]
endfunction

" RETURNS:  (v:t_list)  The name format string for the given mark, and the
"                       list of naming arguments for that mark, in that order.
" DETAILS:  See `:h vim-markbar-funcref`.
function! markbar#PeekabooMarkbarController#_getDefaultNameFormat(mark) abort dict
    call markbar#PeekabooMarkbarController#AssertIsStandardMarkbarController(l:self)
    call markbar#MarkData#AssertIsMarkData(a:mark)

    let l:mark_char = a:mark.getMark()
    if !markbar#helpers#IsGlobalMark(l:mark_char)
        let l:format_str = markbar#settings#PeekabooMarkNameFormatString()
        let l:format_arg = markbar#settings#PeekabooMarkNameArguments()
    elseif markbar#helpers#IsUppercaseMark(l:mark_char)
        let l:format_str = markbar#settings#PeekabooFileMarkFormatString()
        let l:format_arg = markbar#settings#PeekabooFileMarkArguments()
    else " IsNumberedMark
        let l:format_str = markbar#settings#PeekabooNumberedMarkFormatString()
        let l:format_arg = markbar#settings#PeekabooNumberedMarkArguments()
    endif

    return [ l:format_str, l:format_arg ]
endfunction

" REQUIRES: - `a:buffer_no` is not a markbar buffer.
"           - `a:buffer_no` is not the global buffer.
"           - `a:buffer_no` is a buffer *number.*
" EFFECTS:  - Return a list populated linewise with the requested marks
"           and those marks' contexts.
" PARAM:    marks   (v:t_string)    Every mark that the user wishes to
"                                   display, in order from left to right (i.e.
"                                   first character is the mark that should
"                                   appear at the top of the markbar.)
function! markbar#PeekabooMarkbarController#_getMarkbarContents(buffer_no, marks) abort dict
    call markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(l:self)
    return l:self._generateMarkbarContents(
        \ a:buffer_no,
        \ a:marks,
        \ markbar#settings#PeekabooMarkbarSectionSeparator(),
        \ markbar#settings#PeekabooContextIndentBlock()
    \ )
endfunction

function! markbar#PeekabooMarkbarController#_openMarkbarSplit() abort dict
    call markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(l:self)
    let l:open_vertical = markbar#settings#PeekabooMarkbarOpenVertical()
    call l:self['_markbar_view'].openMarkbar(
        \ markbar#settings#PeekabooOpenPosition(),
        \ l:open_vertical,
        \ l:open_vertical ?
            \ markbar#settings#PeekabooMarkbarWidth()
            \ :
            \ markbar#settings#PeekabooMarkbarHeight()
    \ )
endfunction

function! markbar#PeekabooMarkbarController#_setMarkbarMappings() abort dict
    call markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(l:self)
endfunction
