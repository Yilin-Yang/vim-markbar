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
        \ 'DYNAMIC_TYPE': [],
        \ '_markbar_model': a:model,
        \ '_markbar_view': a:view,
        \ 'openMarkbar':
            \ function('markbar#MarkbarController#openMarkbar'),
        \ 'closeMarkbar':
            \ function('markbar#MarkbarController#closeMarkbar'),
        \ 'toggleMarkbar':
            \ function('markbar#MarkbarController#toggleMarkbar'),
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
        \ '_populateWithMarkbar':
            \ function('markbar#MarkbarController#_populateWithMarkbar')
    \ }

    return l:new
endfunction

function! markbar#MarkbarController#AssertIsMarkbarController(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'MarkbarController'
        throw '(markbar#MarkbarController) Object is not of type MarkbarController: ' . a:object
    endif
endfunction

" EFFECTS:  - Close any existing markbars.
"           - Create a markbar buffer for the currently active buffer if one
"           does not yet exist.
"           - Open this markbar buffer in a sidebar.
function! markbar#MarkbarController#openMarkbar() abort dict
    call markbar#MarkbarController#AssertIsMarkbarController(l:self)
    let l:model = l:self['_markbar_model']
    let l:view  = l:self['_markbar_view']

    call l:model.updateCurrentAndGlobal()
    call l:view.openMarkbar()

    let l:active_buffer  = l:model.getActiveBuffer()
    let l:markbar_buffer = l:view.getMarkbarBuffer()

    call l:self._populateWithMarkbar(l:active_buffer, l:markbar_buffer)
endfunction

function! markbar#MarkbarController#closeMarkbar() abort dict
    call markbar#MarkbarController#AssertIsMarkbarController(l:self)
    call l:self['_markbar_view'].closeMarkbar()
endfunction

function! markbar#MarkbarController#toggleMarkbar() abort dict
    call markbar#MarkbarController#AssertIsMarkbarController(l:self)
    call l:self['_markbar_view'].toggleMarkbar()
endfunction


function! markbar#MarkbarController#__noImplementation(func_name, ...) abort dict
    call markbar#MarkbarController#AssertIsMarkbarController(l:self)
    throw '(markbar#MarkbarController) Invoked pure virtual function ' . a:func_name
endfunction

" RETURNS:  (v:t_string)    The given mark, reformatted into a markbar
"                           'section heading'.
" PARAM:    mark    (MarkData)  The mark for which to produce a heading.
function! markbar#MarkbarController#_getMarkHeading(mark) abort dict
    call markbar#MarkbarController#AssertIsMarkbarController(l:self)
    call markbar#MarkData#AssertIsMarkData(a:mark)
    let l:suffix = ' '
    let l:user_given_name = a:mark.getName()
    if empty(l:user_given_name)
        let l:suffix .= markbar#ui#GetDefaultName(a:mark)
    else
        let l:suffix .= l:user_given_name
    endif
    return "['" . a:mark.getMark() . ']:' . l:suffix
endfunction

" RETURNS:  (v:t_string)    The 'default name' for the given mark, as
"                           determined by the global mark name format strings.
" PARAM:    mark    (markbar#MarkData)  The mark to be named.
function! markbar#MarkbarController#_getDefaultMarkName(mark) abort dict
    call markbar#MarkbarController#AssertIsMarkbarController(l:self)
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
    let l:name = ''
    if empty(l:format_str) | return l:name | endif

    let l:cmd = 'let l:name = printf(''' . l:format_str . "'"

    for l:Arg in l:format_arg " capital 'Arg' to handle funcrefs
        let l:cmd .= ', '
        if type(l:Arg) == v:t_func
            let l:cmd .= string(l:Arg(markbar#BasicMarkData#new(a:mark)))
        elseif l:Arg ==# 'line'
            let l:cmd .= a:mark.getLineNo()
        elseif l:Arg ==# 'col'
            let l:cmd .= a:mark.getColumnNo()
        elseif l:Arg ==# 'fname'
            " include quotes when concatenating onto l:cmd
            let l:cmd .= string(markbar#helpers#ParentFilename(l:mark_char))
        else
            throw '(MarkbarController#_getDefaultName) Unrecognized format argument: '
                \ . l:Arg
        endif
    endfor
    let l:cmd .= ')'
    execute l:cmd
    return l:name
endfunction

" BRIEF:    Replace the target buffer with the marks/contexts of the given buffer.
function! markbar#MarkbarController#_populateWithMarkbar(
    \ for_buffer_no,
    \ into_buffer_expr
\ ) abort dict
    call markbar#MarkbarController#AssertIsMarkbarController(l:self)
    let l:contents  = l:self._getHelpText(g:markbar_show_verbose_help)
    let l:contents += l:self._getMarkbarContents(
        \ a:for_buffer_no,
        \ markbar#settings#MarksToDisplay()
    \ )
    call markbar#helpers#ReplaceBuffer(a:into_buffer_expr, l:contents)
endfunction
