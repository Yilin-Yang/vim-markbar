" BRIEF:    Somewhat user-facing interface for controlling the markbar UI.
" DETAILS:  The 'controller' in Model-View-Controller. Provides an abstract
"           interface for 'generating' markbars that can be manipulated
"           through implementation-defined keymappings.

" BRIEF:    Construct a MarkbarController object.
" PARAM:    model   (markbar#MarkbarModel)  Reference to the current markbar
"                                           state.
" PARAM:    view    (markbar#MarkbarView)   Reference to an object controlling
"                                           the appearance of the markbar UI.
function! markbar#MarkbarController#new(model, view) abort
    call markbar#MarkbarModel#AssertIsMarkbarModel(a:model)
    call markbar#MarkbarView#AssertIsMarkbarView(a:view)
    let l:new = {
        \ 'TYPE': 'MarkbarController',
        \ 'DYNAMIC_TYPE': '',
        \ '_markbar_model': a:model,
        \ '_markbar_view': a:view,
        \ 'openMarkbar':
            \ function('markbar#MarkbarController#__noImplementation', ['openMarkbar']),
        \ 'closeMarkbar':
            \ function('markbar#MarkbarController#__noImplementation', ['closeMarkbar']),
        \ 'toggleMarkbar':
            \ function('markbar#MarkbarController#__noImplementation', ['toggleMarkbar']),
        \ '_getHelpText':
            \ function(
                \ 'markbar#MarkbarController#__noImplementation',
                \ ['_getHelpText']
            \ ),
        \ '_getMarkHeading':
            \ function('markbar#MarkbarController#_getMarkHeading'),
        \ '_getDefaultMarkName':
            \ function('markbar#MarkbarController#_getDefaultMarkName'),
        \ '_getMarkbarContents':
            \ function(
                \ 'markbar#MarkbarController#__noImplementation',
                \ ['_getMarkbarContents']
            \ ),
    \ }

    return l:new
endfunction

function! markbar#MarkbarController#AssertIsMarkbarController(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'MarkbarController'
        throw '(markbar#MarkbarController) Object is not of type MarkbarController: ' . a:object
    endif
endfunction

function! markbar#MarkbarController#__noImplementation(func_name) abort dict
    call markbar#MarkbarController#AssertIsMarkbarController(l:self)
    throw '(markbar#MarkbarController) Invoked pure virtual function ' . a:func_name
endfunction

function! markbar#MarkbarController#_getMarkHeading() abort dict
endfunction

function! markbar#MarkbarController#_getDefaultMarkName() abort dict
endfunction
