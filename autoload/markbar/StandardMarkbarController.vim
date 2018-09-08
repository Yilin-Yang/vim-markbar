" BRIEF:    Controller for the 'ordinary' markbar.
" DETAILS:  Handles creation and population of the 'standard' markbar opened
"           through explicit invocations of, e.g. `<Plug>ToggleMarkbar`.

" BRIEF:    Construct a StandardMarkbarController object.
function! markbar#StandardMarkbarController#new(model, view) abort
    let l:new = markbar#MarkbarController#new(a:model, a:view)
    let l:new['DYNAMIC_TYPE'] += ['StandardMarkbarController']

    let l:new['_getHelpText'] =
        \ function('markbar#StandardMarkbarController#_getHelpText')
    let l:new['_getMarkbarContents'] =
        \ function('markbar#StandardMarkbarController#_getMarkbarContents')

    let l:new['_openMarkbarSplit'] =
        \ function('markbar#StandardMarkbarController#_openMarkbarSplit')
    let l:new['_setMarkbarMappings'] =
        \ function('markbar#StandardMarkbarController#_setMarkbarMappings')

    return l:new
endfunction

function! markbar#StandardMarkbarController#AssertIsStandardMarkbarController(object) abort
    if type(a:object) !=# v:t_dict || index(a:object['DYNAMIC_TYPE'], 'StandardMarkbarController') ==# -1
        throw '(markbar#StandardMarkbarController) Object is not of type StandardMarkbarController: ' . a:object
    endif
endfunction

" RETURNS:  (v:t_list)      Lines of helptext to display at the top of the
"                           markbar.
function! markbar#StandardMarkbarController#_getHelpText(display_verbose) abort dict
    call markbar#StandardMarkbarController#AssertIsStandardMarkbarController(l:self)
    if (a:display_verbose)
        return [
            \ '" vim-markbar Keymappings',
            \ '" -----------------------',
            \ '" Press ? to close help' ,
            \ '" -----------------------',
            \ '" With the cursor over a mark or its context,',
            \ '" ' . markbar#settings#JumpToMarkMapping()
                \  . ': jump to mark',
            \ '" ' . markbar#settings#NextMarkMapping()
                \  . ': move cursor to next mark',
            \ '" ' . markbar#settings#PreviousMarkMapping()
                \  . ': move cursor to previous mark',
            \ '" ' . markbar#settings#RenameMarkMapping()
                \  . ': rename mark',
            \ '" ' . markbar#settings#ResetMarkMapping()
                \  . ": reset mark's name",
            \ '" ' . markbar#settings#DeleteMarkMapping()
                \  . ': delete mark',
            \ '" -----------------------',
        \ ]
    else
        return [ '" Press ? for help' ]
    endif
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
function! markbar#StandardMarkbarController#_getMarkbarContents(buffer_no, marks) abort dict
    call markbar#StandardMarkbarController#AssertIsStandardMarkbarController(l:self)
    if a:buffer_no ==# markbar#constants#GLOBAL_MARKS()
        throw '(markbar#StandardMarkbarController) Bad argument value: ' . a:buffer_no
    endif
    let l:buffer_caches = l:self['_markbar_model']['_buffer_caches']
    let l:marks   = l:buffer_caches[a:buffer_no]['_marks_dict']
    let l:globals = l:buffer_caches[markbar#constants#GLOBAL_MARKS()]['_marks_dict']

    let l:lines = [] " to return
    let l:section_separator = markbar#settings#MarkbarSectionSeparator()
    let l:i = -1
    while l:i <# len(a:marks)
        let l:i += 1
        let l:mark_char = a:marks[l:i]

        if !has_key(l:marks, l:mark_char) && !has_key(l:globals, l:mark_char)
            continue
        endif

        let l:mark =
            \ markbar#helpers#IsGlobalMark(l:mark_char) ?
                \ l:globals[l:mark_char] : l:marks[l:mark_char]
        let l:lines += [ l:self._getMarkHeading(l:mark) ]

        let l:indent_block = markbar#settings#ContextIndentBlock()
        for l:line in l:mark['_context']
            let l:lines += [l:indent_block . l:line]
        endfor

        let l:lines += l:section_separator
    endwhile

    return l:lines
endfunction

function! markbar#StandardMarkbarController#_openMarkbarSplit() abort dict
    call markbar#StandardMarkbarController#AssertIsStandardMarkbarController(l:self)
    let l:open_vertical = markbar#settings#MarkbarOpenVertical()
    call l:self['_markbar_view'].openMarkbar(
        \ markbar#settings#OpenPosition(),
        \ l:open_vertical,
        \ l:open_vertical ? markbar#settings#MarkbarWidth() : markbar#settings#MarkbarHeight()
    \ )
endfunction

function! markbar#StandardMarkbarController#_setMarkbarMappings() abort dict
    call markbar#StandardMarkbarController#AssertIsStandardMarkbarController(l:self)
    let b:ctrl  = l:self
    let b:view  = l:self['_markbar_view']
    let b:model = l:self['_markbar_model']
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#JumpToMarkMapping()
        \ . ' :call b:view._goToMark()<cr>'

    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#RenameMarkMapping()
        \ . ' :call b:model.renameMark(b:view._getCurrentMarkHeading())<cr>'
        \ . ' :call b:ctrl.openMarkbar()<cr>'
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#ResetMarkMapping()
        \ . ' :call b:model.resetMark(b:view._getCurrentMarkHeading())<cr>'
        \ . ' :call b:ctrl.openMarkbar()<cr>'
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#DeleteMarkMapping()
        \ . ' :call b:model.deleteMark(b:view._getCurrentMarkHeading())<cr>'
        \ . ' :call b:ctrl.openMarkbar()<cr>'

    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#NextMarkMapping()
        \ . ' :<C-U>call b:view._cycleToNextMark(v:count1)<cr>'
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#PreviousMarkMapping()
        \ . ' :<C-U>call b:view._cycleToPreviousMark(v:count1)<cr>'

    execute 'noremap <silent> <buffer> ? '
        \ . ':call b:view.toggleShowHelp()<cr>'
        \ . ':call b:ctrl.openMarkbar()<cr>'
endfunction
