" BRIEF:    Controller for the 'vim-peekaboo' markbar.
" DETAILS:  Handles creation and population of the 'compact' markbar opened
"           when the user hits the apostrophe or backtick keys.

" BRIEF:    Construct a PeekabooMarkbarController object. Set keymaps.
function! markbar#PeekabooMarkbarController#new(model, view) abort
    let l:new = markbar#MarkbarController#new(a:model, a:view)
    let l:new['DYNAMIC_TYPE'] += ['PeekabooMarkbarController']

    let l:new['openMarkbar_SUPER'] = l:new['openMarkbar']
    let l:new['openMarkbar'] =
        \ function('markbar#PeekabooMarkbarController#openMarkbar')

    let l:new['apostrophe'] =
        \ function('markbar#PeekabooMarkbarController#apostrophe')
    let l:new['backtick'] =
        \ function('markbar#PeekabooMarkbarController#backtick')

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

    " TODO: check that select, jump to modifiers aren't the same

    let l:select_keys = markbar#KeyTable#newWithUniformModifiers(
        \ markbar#constants#ALL_MARKS_STRING(),
        \ markbar#settings#PeekabooSelectModifiers()
    \ )
    let l:new['_select_keys'] = l:select_keys

    let l:jump_keys = markbar#KeyTable#newWithUniformModifiers(
        \ markbar#settings#PeekabooMarksToDisplay(),
        \ markbar#settings#PeekabooJumpToMarkModifiers()
    \ )
    let l:new['_jump_keys'] = l:jump_keys

    let l:new['_keyhandler'] =
        \ markbar#KeyHandler#new(
            \ markbar#KeyTable#fromTwoCombined(
                \ l:select_keys,
                \ l:jump_keys
            \ ),
            \ function('markbar#PeekabooMarkbarController#DispatchFromKeypress', [l:new] )
        \ )
    let l:new['_jump_like_backtick'] = v:false

    return l:new
endfunction

function! markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(object) abort
    if type(a:object) !=# v:t_dict || index(a:object['DYNAMIC_TYPE'], 'PeekabooMarkbarController') ==# -1
        throw '(markbar#PeekabooMarkbarController) Object is not of type PeekabooMarkbarController: ' . a:object
    endif
endfunction

" BRIEF:    Open markbar; wait for user input; go to mark, or close markbar.
function! markbar#PeekabooMarkbarController#openMarkbar() abort dict
    call markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(l:self)
    call l:self.openMarkbar_SUPER()
    redraw " don't wait for user key input, even if ladyredraw is set

    " TODO: constantly reprompt the user for additional inputs?

    " wait for user input, while open
    while exists('b:is_markbar') && !l:self['_keyhandler'].waitForKey()
        " waitForKey may dispatch to _dispatchFromKeypress
    endwhile

    " if !exists('b:is_markbar')
    "     " close peekaboo markbar, if the user manually unfocused its window
    "     call l:self.closeMarkbar()
    " endif
endfunction

" BRIEF:    Open the peekaboo bar with apostrophe-like jump behavior.
function! markbar#PeekabooMarkbarController#apostrophe() abort dict
    call markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(l:self)
    let l:self['_jump_like_backtick'] = v:false
    call l:self.openMarkbar()
endfunction

" BRIEF:    Open the peekaboo bar with backtick-like jump behavior.
function! markbar#PeekabooMarkbarController#backtick() abort dict
    call markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(l:self)
    let l:self['_jump_like_backtick'] = v:true
    call l:self.openMarkbar()
endfunction

" RETURNS:  (v:t_list)      Lines of helptext to display at the top of the
"                           markbar.
function! markbar#PeekabooMarkbarController#_getHelpText(display_verbose) abort dict
    call markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(l:self)
    if (a:display_verbose)
        let l:select_mods = markbar#settings#PeekabooSelectModifiers()
        if !len(l:select_mods)
            let l:select_mods = 'no modifiers.'
        endif
        let l:jump_mods = markbar#settings#PeekabooJumpToMarkModifiers()
        if !len(l:jump_mods)
            let l:jump_mods = 'no modifiers.'
        endif
        return [
            \ '" vim-markbar "Peekaboo" Keymappings',
            \ '" -----------------------',
            \ '" Press ? to close help' ,
            \ '" -----------------------',
            \ '" To jump directly to a mark, press',
            \ '"  its key with ' .  l:jump_mods,
            \ '" To select a mark in the markbar,',
            \ '"  press its key with ' . l:select_mods,
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
    let b:ctrl  = l:self
    let b:view  = l:self['_markbar_view']
    let b:model = l:self['_markbar_model']

    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#PeekabooJumpToMarkMapping()
        \ . ' :call b:view._goToMark()<cr>'
    execute 'noremap <silent> <buffer> ? '
        \ . ':call b:view.toggleShowHelp()<cr>'
        \ . ':call b:ctrl.openMarkbar()<cr>'

    " disable mappings that open peekaboo markbar
    " buffer-local remapping to noop
    silent! map <buffer> ' <Plug>
    silent! map <buffer> ` <Plug>
endfunction

" BRIEF:    Select or jump to a mark, depending on what keys were pressed.
function! markbar#PeekabooMarkbarController#DispatchFromKeypress(self, keycode) abort
    call markbar#PeekabooMarkbarController#AssertIsPeekabooMarkbarController(a:self)
    " NOTE: currently, just prints the given keycode
    if a:self['_select_keys'].contains(a:keycode)
        " TODO: select the given mark
        echoerr "SELECT: " . a:keycode
        return
    elseif a:self['_jump_keys'].contains(a:keycode)
        " TODO: go to the given mark
        echoerr "JUMP: " . a:keycode
        return
    endif
    throw '(markbar#PeekabooMarkbarController) Intercepted bad keycode: ' . a:keycode
endfunction
