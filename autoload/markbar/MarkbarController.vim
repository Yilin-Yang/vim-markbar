" BRIEF:    Somewhat user-facing interface for manipulating the markbar state.
" DETAILS:  The 'controller' in Model-View-Controller. Provides functions that
"           to be called through keymappings.

" BRIEF:    Construct a MarkbarController object.
function! markbar#MarkbarController#new() abort
    " TODO: make model, pass model into view
    let l:new = {
        \ '_markbar_model': markbar#MarkbarModel#new(),
        \ '_markbar_view':
            \ markbar#MarkbarView#new(
                \ l:new['_markbar_model']
            \ ),
    \ }

    " TODO: implement with MarkbarFactory

    let l:new['openStandardMarkbar'] = function('markbar#MarkbarController#openStandardMarkbar')
    let l:new['openCompactMarkbar']  = function('markbar#MarkbarController#openCompactMarkbar')
endfunction

function! markbar#MarkbarController#AssertIsMarkbarController(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'MarkbarController'
        throw '(markbar#MarkbarController) Object is not of type MarkbarController: ' . a:object
    endif
endfunction

function! markbar#MarkbarController#openStandardMarkbar() abort dict
    call markbar#MarkbarController#AssertIsMarkbarController(self)
    " TODO
endfunction

function! markbar#MarkbarController#openCompactMarkbar() abort dict
    call markbar#MarkbarController#AssertIsMarkbarController(self)
    " TODO
endfunction
