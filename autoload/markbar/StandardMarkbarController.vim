" BRIEF:    Controller for the 'ordinary' markbar.
" DETAILS:  Handles creation and population of the 'standard' markbar opened
"           through explicit invocations of, e.g. `<Plug>ToggleMarkbar`.

" BRIEF:    Construct a StandardMarkbarController object.
function! markbar#StandardMarkbarController#new(model, view) abort
    let l:new = markbar#MarkbarController#new(a:model, a:view)

    let l:new['openMarkbar'] =
        \ function('markbar#StandardMarkbarController#openMarkbar')
    let l:new['closeMarkbar'] =
        \ function('markbar#StandardMarkbarController#closeMarkbar')
    let l:new['toggleMarkbar'] =
        \ function('markbar#StandardMarkbarController#toggleMarkbar')


endfunction

function! markbar#StandardMarkbarController#AssertIsStandardMarkbarController(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'StandardMarkbarController'
        throw '(markbar#StandardMarkbarController) Object is not of type StandardMarkbarController: ' . a:object
    endif
endfunction

function! markbar#StandardMarkbarController#openMarkbar() abort dict
endfunction

function! markbar#StandardMarkbarController#closeMarkbar() abort dict
endfunction

function! markbar#StandardMarkbarController#toggleMarkbar() abort dict
endfunction
