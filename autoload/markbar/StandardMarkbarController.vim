" BRIEF:    Controller for the 'ordinary' markbar.
" DETAILS:  Handles creation and population of the 'standard' markbar opened
"           through explicit invocations of, e.g. `<Plug>ToggleMarkbar`.

" BRIEF:    Construct a StandardMarkbarController object.
function! markbar#StandardMarkbarController#new(model, view) abort
    let l:new = markbar#MarkbarController#new(a:model, a:view)
    let l:new['DYNAMIC_TYPE'] += ['StandardMarkbarController']

    let l:new['_getHelpText'] =
        \ function('markbar#StandardMarkbarController#_getHelpText')
    let l:new['_getDefaultNameFormat'] =
        \ function('markbar#StandardMarkbarController#_getDefaultNameFormat')
    let l:new['_getMarksToDisplay'] =
        \ function('markbar#StandardMarkbarController#_getMarksToDisplay')
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

" RETURNS:  (v:t_list)  The name format string for the given mark, and the
"                       list of naming arguments for that mark, in that order.
" DETAILS:  See `:h vim-markbar-funcref`.
function! markbar#StandardMarkbarController#_getDefaultNameFormat(mark) abort dict
    call markbar#StandardMarkbarController#AssertIsStandardMarkbarController(l:self)
    call markbar#MarkData#AssertIsMarkData(a:mark)

    let l:mark_char = a:mark.getMark()
    if !markbar#helpers#IsGlobalMark(l:mark_char)
        let l:format_str = markbar#settings#MarkNameFormatString()
        let l:format_arg = markbar#settings#MarkNameArguments()
    elseif markbar#helpers#IsUppercaseMark(l:mark_char)
        let l:format_str = markbar#settings#FileMarkFormatString()
        let l:format_arg = markbar#settings#FileMarkArguments()
    else " IsNumberedMark
        let l:format_str = markbar#settings#NumberedMarkFormatString()
        let l:format_arg = markbar#settings#NumberedMarkArguments()
    endif

    return [ l:format_str, l:format_arg ]
endfunction

function! markbar#StandardMarkbarController#_getMarksToDisplay() abort dict
    call markbar#StandardMarkbarController#AssertIsStandardMarkbarController(l:self)
    return markbar#settings#MarksToDisplay()
endfunction

function! markbar#StandardMarkbarController#_getMarkbarContents(buffer_no, marks) abort dict
    call markbar#StandardMarkbarController#AssertIsStandardMarkbarController(l:self)
    let l:NumContext = markbar#helpers#NumContextFunctor(
        \ markbar#settings#NumLinesContext(), v:false)
    return l:self._generateMarkbarContents(
        \ a:buffer_no,
        \ a:marks,
        \ l:NumContext,
        \ markbar#settings#MarkbarSectionSeparator(),
        \ markbar#settings#ContextIndentBlock(),
        \ markbar#settings#EnableMarkHighlighting(),
        \ markbar#settings#JumpToExactPosition()
    \ )
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
    mapclear <buffer>

    let b:ctrl  = l:self
    let b:view  = l:self['_markbar_view']
    let b:model = l:self['_markbar_model']
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#JumpToMarkMapping()
        \ . ' :call b:view._goToSelectedMark('
            \ . 'markbar#settings#JumpToExactPosition()'
        \ . ')<cr>'

    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#RenameMarkMapping()
        \ . ' :call b:model.renameMark(b:view._getCurrentMarkHeading())<cr>'
        \ . ' :call b:ctrl.refreshContents()<cr>'
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#ResetMarkMapping()
        \ . ' :call b:model.resetMark(b:view._getCurrentMarkHeading())<cr>'
        \ . ' :call b:ctrl.refreshContents()<cr>'
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#DeleteMarkMapping()
        \ . ' :call b:model.deleteMark(b:view._getCurrentMarkHeading())<cr>'
        \ . ' :call b:ctrl.refreshContents()<cr>'

    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#NextMarkMapping()
        \ . ' :<C-U>call b:view._cycleToNextMark(v:count1)<cr>'
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#PreviousMarkMapping()
        \ . ' :<C-U>call b:view._cycleToPreviousMark(v:count1)<cr>'

    execute 'noremap <silent> <buffer> ? '
        \ . ':call b:view.toggleShowHelp()<cr>'
        \ . ' :call b:ctrl.refreshContents()<cr>'
endfunction
