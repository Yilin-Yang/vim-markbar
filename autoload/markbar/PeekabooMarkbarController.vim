" BRIEF:    Controller for the 'vim-peekaboo' markbar.
" DETAILS:  Handles creation and population of the 'compact' markbar opened
"           when the user hits the apostrophe or backtick keys.

" BRIEF:    Construct a PeekabooMarkbarController object. Set keymaps.
function! markbar#PeekabooMarkbarController#new(model, view) abort
    let l:new = markbar#MarkbarController#new(a:model, a:view)
    let l:new['DYNAMIC_TYPE'] += ['PeekabooMarkbarController']

    let l:new['apostrophe'] =
        \ function('markbar#PeekabooMarkbarController#apostrophe')
    let l:new['backtick'] =
        \ function('markbar#PeekabooMarkbarController#backtick')

    let l:new['_getHelpText'] =
        \ function('markbar#PeekabooMarkbarController#_getHelpText')
    let l:new['_getDefaultNameFormat'] =
        \ function('markbar#PeekabooMarkbarController#_getDefaultNameFormat')
    let l:new['_getMarksToDisplay'] =
        \ function('markbar#PeekabooMarkbarController#_getMarksToDisplay')
    let l:new['_getMarkbarContents'] =
        \ function('markbar#PeekabooMarkbarController#_getMarkbarContents')

    let l:new['_openMarkbarSplit'] =
        \ function('markbar#PeekabooMarkbarController#_openMarkbarSplit')
    let l:new['_setMarkbarMappings'] =
        \ function('markbar#PeekabooMarkbarController#_setMarkbarMappings')


    let l:new['_shouldNotOpen'] =
        \ function('markbar#PeekabooMarkbarController#_shouldNotOpen')

    let l:select_keys = markbar#KeyMapper#newWithUniformModifiers(
        \ markbar#constants#ALL_MARKS_STRING(),
        \ markbar#settings#PeekabooSelectModifiers(),
        \ markbar#settings#PeekabooSelectPrefix(),
        \ v:false
    \ )
    let l:new['_select_keys'] = l:select_keys

    let l:jump_to_keys = markbar#KeyMapper#newWithUniformModifiers(
        \ markbar#constants#ALL_MARKS_STRING(),
        \ markbar#settings#PeekabooJumpToMarkModifiers(),
        \ markbar#settings#PeekabooJumpToMarkPrefix(),
        \ v:false
    \ )
    let l:new['_jump_to_keys'] = l:jump_to_keys

    " behavioral and signal flags
    let l:new['_jump_like_backtick'] = v:false

    return l:new
endfunction

function! markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(object) abort
    if type(a:object) !=# v:t_dict || index(a:object['DYNAMIC_TYPE'], 'PeekabooMarkbarController') ==# -1
        throw '(markbar#PeekabooMarkbarController) Object is not of type PeekabooMarkbarController: ' . a:object
    endif
endfunction

" BRIEF:    Open the peekaboo bar with apostrophe-like jump behavior.
" DETAILS:  - Don't open the peekaboo markbar if an invocation filter returns
"           `v:true` for the current buffer.
function! markbar#PeekabooMarkbarController#apostrophe() abort dict
    call markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(l:self)
    if l:self._shouldNotOpen() | return | endif
    if markbar#settings#BacktickBehaviorWithApostrophe()
        let l:self['_jump_like_backtick'] = v:true
    else
        let l:self['_jump_like_backtick'] = v:false
    endif
    call l:self.openMarkbar()
endfunction

" BRIEF:    Open the peekaboo bar with backtick-like jump behavior.
" DETAILS:  - Don't open the peekaboo markbar if an invocation filter returns
"           `v:true` for the current buffer.
function! markbar#PeekabooMarkbarController#backtick() abort dict
    call markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(l:self)
    if l:self._shouldNotOpen() | return | endif
    let l:self['_jump_like_backtick'] = v:true
    call l:self.openMarkbar()
endfunction

" RETURNS:  (v:t_list)      Lines of helptext to display at the top of the
"                           markbar.
function! markbar#PeekabooMarkbarController#_getHelpText(display_verbose) abort dict
    call markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(l:self)
    if (a:display_verbose)
        " use an arbitrary LHS entry from KeyMapper objects in the helptext
        let l:select_map  = l:self['_select_keys' ]['_keys_to_map'][0]
            let l:select_lhs_map = l:select_map[0]
            let l:select_target = l:select_map[1][0]
        let l:jump_to_map = l:self['_jump_to_keys']['_keys_to_map'][0]
            let l:jump_to_lhs_map = l:jump_to_map[0]
            let l:jump_to_target = l:jump_to_map[1][0]
        return [
            \ '" "Peekaboo" vim-markbar',
            \ '" -----------------------',
            \ '" Press ? to close help' ,
            \ '" -----------------------',
            \ '" ' . l:select_lhs_map.': select ['''.l:select_target.'] in markbar',
            \ '" ' . markbar#settings#PeekabooJumpToMarkMapping()
                \ . ': jump to selected mark',
            \ '" ' . l:jump_to_lhs_map.': jump directly to mark ['''
                \ . l:jump_to_target . ']',
            \ '" -----------------------',
        \ ]
    endif
    return [ '" Press ? for help' ]
endfunction

" RETURNS:  (v:t_list)  The name format string for the given mark, and the
"                       list of naming arguments for that mark, in that order.
" DETAILS:  See `:h vim-markbar-funcref`.
function! markbar#PeekabooMarkbarController#_getDefaultNameFormat(mark) abort dict
    call markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(l:self)
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

function! markbar#PeekabooMarkbarController#_getMarksToDisplay() abort dict
    call markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(l:self)
    return markbar#settings#PeekabooMarksToDisplay()
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
    let l:NumContext = markbar#helpers#NumContextFunctor(
        \ markbar#settings#NumLinesContext(), v:true)
    return l:self._generateMarkbarContents(
        \ a:buffer_no,
        \ a:marks,
        \ l:NumContext,
        \ markbar#settings#PeekabooMarkbarSectionSeparator(),
        \ markbar#settings#PeekabooContextIndentBlock(),
        \ markbar#settings#EnableMarkHighlighting(),
        \ l:self['_jump_like_backtick']
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
    mapclear <buffer>

    let b:ctrl  = l:self
    let b:view  = l:self['_markbar_view']
    let b:model = l:self['_markbar_model']

    noremap <silent> <buffer> <Esc> :call b:ctrl.closeMarkbar(1)<cr>
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#PeekabooJumpToMarkMapping()
        \ . ' :call b:view._goToSelectedMark('
            \ . 'markbar#settings#JumpToExactPosition()'
        \ . ')<cr>'
    execute 'noremap <silent> <buffer> ? '
        \ . ':call b:view.toggleShowHelp()<cr>'
        \ . ':call b:ctrl.refreshContents()<cr>'

    call l:self['_select_keys'].setCallback(
        \ { key, mods, prefix -> b:view._selectMark(key) }
    \ )
    call l:self['_jump_to_keys'].setCallback(
        \ { key, mods, prefix -> b:view._goToMark(key, l:self['_jump_like_backtick']) }
    \ )

    call l:self['_select_keys' ].setMappings('noremap <silent> <buffer>')
    call l:self['_jump_to_keys'].setMappings('noremap <silent> <buffer>')

endfunction

" RETURNS:  (v:t_bool)  `v:true` if the peekaboo markbar should not be opened
"                       from the current buffer, i.e. if a call to
"                       `apostrophe()` or `backtick()` should silently fail.
function! markbar#PeekabooMarkbarController#_shouldNotOpen() abort dict
    call markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(l:self)
    let l:bufno = bufnr('%')
    let l:filters = markbar#settings#PeekabooInvocationFilters()
    for l:Test in l:filters
        if l:Test(l:bufno) | return v:true | endif
    endfor
    return v:false
endfunction
