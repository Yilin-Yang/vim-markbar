" BRIEF:    Intercepts keypresses; returns some through a callback function.

" BRIEF:    Construct a KeyHandler object.
" PARAM:    keycodes    (v:t_dict)  TODO
" PARAM:    Keypress_callback   (v:t_func)  A callback function that accepts
"                                           a keycode as returned by
"                                           `getchar()`.
function! markbar#KeyHandler#new(keycodes, Keypress_callback) abort
    if type(a:keycodes) !=# v:t_dict
        throw '(markbar#KeyHandler) Invalid type for argument `keycodes`: '
            \ . type(a:keycodes)
    endif
    if type(a:Keypress_callback) !=# v:t_func
        throw '(markbar#KeyHandler) Invalid type for argument `Keypress_callback`: '
            \ . type(a:Keypress_callback)
    endif

    let l:new = {
        \ 'TYPE': 'KeyHandler',
        \ '_keycodes': a:keycodes,
        \ '_keypress_callback()': a:Keypress_callback,
        \ 'waitForKeypress': function('markbar#KeyHandler#waitForKeypress')
    \ }

    return l:new
endfunction

function! markbar#KeyHandler#AssertIsKeyHandler(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'KeyHandler'
        throw '(markbar#KeyHandler) Object is not of type KeyHandler: ' . a:object
    endif
endfunction

" BRIEF:    Wait for the user to press a key and process it.
" DETAILS:  - If the user's just-pressed keycode exists in this KeyHandler's
"           keymap, consume the character and feed it into the callback
"           function.
"           - Else, transparently feed the key back to vim.
" RETURNS:  (v:t_bool)  `v:true` if the user's keypress resulted in a
"                       callback, `v:false` otherwise.
function! markbar#KeyHandler#waitForKey() abort dict
    let l:key = nr2char(getchar())

endfunction
