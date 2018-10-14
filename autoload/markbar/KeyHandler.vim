" BRIEF:    Intercepts keypresses; returns some through a callback function.

" BRIEF:    Construct a KeyHandler object.
" PARAM:    keytable    (markbar#KeyTable)  Keys that this KeyHandler should
"                                           intercept. KeyHandler will be
"                                           transparent to keys not held in
"                                           this table.
" PARAM:    Keypress_callback   (v:t_func)  A callback function that accepts
"                                           a keycode as returned by
"                                           `getchar()` and a set of modifiers
"                                           as returned by `getcharmod()`.
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
        \ 'waitForKeypress': function('markbar#KeyHandler#waitForKeypress')
    \ }

    return l:new
endfunction

function! markbar#KeyHandler#AssertIsKeyHandler(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'KeyHandler'
        throw '(markbar#KeyHandler) Object is not of type KeyHandler: ' . a:object
    endif
endfunction

" RETURNS:  (v:t_string)    The given keycode and modifiers, as an `eval`uable
"                           string (see `:h expr-quote`). Doesn't actually use
"                           feedkeys, despite the name.
function! markbar#KeyHandler#ParseIntoFeedkeys(keycode, charmod) abort
    let l:key = nr2char(a:keycode)
    let l:mods = a:charmod
    let l:command = '<'

    " see `:h keycodes`
    let l:num_to_mods = {
        \ 128: 'D',
        \ 16: 'M',
        \ 8: 'A',
        \ 4: 'C',
        \ 2: 'S',
    \ }

    " NOTE: doesn't handle mouse clicks
    for l:num in l:num_to_mods
        if l:mods <# l:num | continue | endif
        let l:mods    -= l:num
        let l:command .= l:num_to_mods[l:num] . '-'
    endfor

    let l:command .= l:key . '>'
    return l:command
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
    let l:mod = getcharmod()
    if l:self.contains(l:key, l:mod)
        call l:self['_keypress_callback()'](l:key, l:mod)
        return v:true
    endif
    let l:feedkeys_cmd = markbar#KeyHandler#ParseIntoFeedkeys(l:key, l:mod)
    execute 'normal ' . l:feedkeys_cmd
    return v:false
endfunction
