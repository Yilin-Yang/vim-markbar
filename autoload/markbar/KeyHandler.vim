" BRIEF:    Intercepts keypresses; returns some through a callback function.

" BRIEF:    Construct a KeyHandler object.
" PARAM:    keytable    (markbar#KeyTable)  Keys that this KeyHandler should
"                                           intercept. KeyHandler will be
"                                           transparent to keys not held in
"                                           this table.
" PARAM:    Keypress_callback   (v:t_func)  A callback function that accepts
"                                           a keycode as returned by `getchar()`.
function! markbar#KeyHandler#new(keytable, Keypress_callback) abort
    call markbar#KeyTable#AssertIsKeyTable(a:keytable)
    if type(a:Keypress_callback) !=# v:t_func
        throw '(markbar#KeyHandler) Invalid type for argument `Keypress_callback`: '
            \ . type(a:Keypress_callback)
    endif

    let l:new = {
        \ 'TYPE': 'KeyHandler',
        \ '_keytable': a:keytable,
        \ '_keypress_callback()': a:Keypress_callback,
        \ 'waitForKey': function('markbar#KeyHandler#waitForKey')
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
    call markbar#KeyHandler#AssertIsKeyHandler(l:self)
    let l:key = getchar()
    if l:self['_keytable'].contains(l:key)
        call l:self['_keypress_callback()'](l:key)
        return v:true
    endif
    if type(l:key) ==# v:t_number
        let l:key = nr2char(l:key)
    endif
    call feedkeys(l:key, 't')
    return v:false
endfunction
