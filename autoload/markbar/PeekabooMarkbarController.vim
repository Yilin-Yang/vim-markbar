" BRIEF:    Controller for the 'vim-peekaboo' markbar.
" DETAILS:  Handles creation and population of the 'compact' markbar opened
"           when the user hits the apostrophe or backtick keys.

" BRIEF:    Construct a PeekabooMarkbarController object.
function! markbar#PeekabooMarkbarController#new(model, view) abort
    let l:new = markbar#MarkbarController#new(a:model, a:view)
    let l:new['DYNAMIC_TYPE'] += ['PeekabooMarkbarController']

    let l:new['_getHelpText'] =
        \ function('markbar#PeekabooMarkbarController#_getHelpText')
    let l:new['_getMarkbarContents'] =
        \ function('markbar#PeekabooMarkbarController#_getMarkbarContents')

    let l:new['_setMarkbarMappings'] = {-> v:true}

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
    if a:buffer_no ==# markbar#constants#GLOBAL_MARKS()
        throw '(markbar#StandardMarkbarController) Bad argument value: ' . a:buffer_no
    endif
    " let l:buffer_caches = l:self['_markbar_model']['_buffer_caches']
    " let l:marks   = l:buffer_caches[a:buffer_no]['_marks_dict']
    " let l:globals = l:buffer_caches[markbar#constants#GLOBAL_MARKS()]['_marks_dict']

    " let l:lines = [] " to return
    " let l:section_separator = markbar#settings#MarkbarSectionSeparator()
    " let l:i = -1
    " while l:i <# len(a:marks)
    "     let l:i += 1
    "     let l:mark_char = a:marks[l:i]

    "     if !has_key(l:marks, l:mark_char) && !has_key(l:globals, l:mark_char)
    "         continue
    "     endif

    "     let l:mark =
    "         \ markbar#helpers#IsGlobalMark(l:mark_char) ?
    "             \ l:globals[l:mark_char] : l:marks[l:mark_char]
    "     let l:lines += [ l:self._getMarkHeading(l:mark) ]

    "     let l:indent_block = markbar#settings#ContextIndentBlock()
    "     for l:line in l:mark['_context']
    "         let l:lines += [l:indent_block . l:line]
    "     endfor

    "     let l:lines += l:section_separator
    " endwhile

    " return l:lines
endfunction
