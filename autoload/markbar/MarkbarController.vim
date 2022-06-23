" BRIEF:    Somewhat user-facing interface for controlling the markbar UI.
" DETAILS:  The 'controller' in Model-View-Controller. Provides an abstract
"           interface for 'generating' markbars that can be manipulated
"           through implementation-defined keymappings.

let s:MarkbarController = {
    \ 'TYPE': 'MarkbarController',
    \ '_markbar_model': v:null,
    \ '_markbar_view': v:null,
    \ '_text_generator': v:null
\ }

" BRIEF:    Construct a MarkbarController object.
" PARAM:    model   (markbar#MarkbarModel)  Current markbar state.
" PARAM:    view    (markbar#MarkbarView)   Object contolling markbar window.
" PARAM:    format  (markbar#MarkbarFormat) Formatting options for the markbar.
function! markbar#MarkbarController#New(model, view, format) abort
    call markbar#ensure#IsClass(a:model, 'MarkbarModel')
    call markbar#ensure#IsClass(a:view, 'MarkbarView')
    let l:new = deepcopy(s:MarkbarController)
    let l:new._markbar_model = a:model
    let l:new._markbar_view = a:view
    let l:new._text_generator = markbar#MarkbarTextGenerator#New(a:format)
    return l:new
endfunction

" EFFECTS: - Create a markbar buffer for the currently active buffer if one
"           does not yet exist.
"           - Open this markbar buffer in a sidebar if the markbar is not yet
"           open, or refresh its contents if it is already open.
"           - Set autocmds to refresh the markbar buffer if it remains open.
function! markbar#MarkbarController#openMarkbar() abort dict
    call l:self._markbar_model.updateCurrentAndGlobal()

    let l:open_vertical = markbar#settings#MarkbarOpenVertical()
    call l:self._markbar_view.openMarkbar(
            \ markbar#settings#OpenPosition(), l:open_vertical,
            \ l:open_vertical ? markbar#settings#MarkbarWidth()
                \ : markbar#settings#MarkbarHeight())

    " TODO: update the setbufline implementation for vim so that the markbar
    " doesn't need to be open in order for the contents to refresh
    call l:self.refreshContents()
endfunction
let s:MarkbarController.openMarkbar = function('markbar#MarkbarController#openMarkbar')

function! markbar#MarkbarController#closeMarkbar() abort dict
    return l:self._markbar_view.closeMarkbar()
endfunction
let s:MarkbarController.closeMarkbar = function('markbar#MarkbarController#closeMarkbar')

function! markbar#MarkbarController#toggleMarkbar() abort dict
    if l:self._markbar_view.closeMarkbar() | return | endif
    call l:self.openMarkbar()
endfunction
let s:MarkbarController.toggleMarkbar = function('markbar#MarkbarController#toggleMarkbar')

" BRIEF:    Update cached marks; clear and repopulate the markbar buffer.
function! markbar#MarkbarController#refreshContents() abort dict
    let l:model = l:self._markbar_model
    let l:view  = l:self._markbar_view

    let l:active_buffer  = l:model.getActiveBuffer()

    call l:model.updateCurrentAndGlobal()
    try
        call l:self._populateWithMarkbar(l:active_buffer)
    catch /Buffer not cached/
        " We're in the markbar, but the last active buffer wasn't cached.
        " This can happen if the user creates and loads a |session-file|
        " with the cursor inside a markbar.
        " Close the markbar, cache whatever buffer the cursor moves to, then
        " reopen a markbar for that buffer.
        " TODO: it's practically impossible to write a test for this?
        call l:view.closeMarkbar()
        let l:active_buffer = bufnr('%')
        call l:model.pushNewBuffer(l:active_buffer)
        call l:model.updateCurrentAndGlobal()

        let l:open_vertical = markbar#settings#MarkbarOpenVertical()
        call l:view.openMarkbar(
                \ markbar#settings#OpenPosition(), l:open_vertical,
                \ l:open_vertical ? markbar#settings#MarkbarWidth()
                    \ : markbar#settings#MarkbarHeight())
        call l:self._populateWithMarkbar(l:active_buffer)
    endtry
endfunction
let s:MarkbarController.refreshContents = function('markbar#MarkbarController#refreshContents')

" BRIEF:    Replace the target buffer with the marks/contexts of the given buffer.
function! markbar#MarkbarController#_populateWithMarkbar(for_buffer_no) abort dict
    let l:local_cache = l:self._markbar_model.getBufferCache(a:for_buffer_no)
    let l:global_cache = l:self._markbar_model.getBufferCache(0)
    let l:contents = l:self._text_generator.getText(
            \ l:local_cache.marks_dict, l:global_cache.marks_dict)

    let l:markbar_buffer = l:self._markbar_view.getMarkbarBuffer()
    call markbar#helpers#ReplaceBuffer(l:markbar_buffer, l:contents)
endfunction
let s:MarkbarController._populateWithMarkbar = function('markbar#MarkbarController#_populateWithMarkbar')
