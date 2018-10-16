" BRIEF:    Lookup table containing keyboard keys, possibly with modifiers.

" BRIEF:    Construct a KeyTable object.
" PARAM:    keys_and_mods   (v:t_list)  A list of two-element v:t_list's
"               containing:
"               1) A one-character v:t_string corresponding to a keyboard key
"               (e.g. a letter, number, etc.)
"               2) A v:t_string of comma-separated modifiers to be applied to
"               that key.
function! markbar#KeyTable#new(keys_and_mods) abort
    for l:i in a:keys_and_mods
        if type(l:i) !=# v:t_list && len(l:i) !=# 2
            throw '(markbar#KeyTable) Malformed key-and-modifier: ' . string(l:i)
        endif
    endfor

    let l:lookup_table = {}
    for [l:key, l:mods] in a:keys_and_mods
        if len(l:key) !=# 1
            throw '(markbar#KeyTable) Bad keycode, should have len 1: ' . l:key
        endif
        if len(l:mods)
            let l:mod_notation = markbar#KeyTable#ParseModifiers(l:mods)
            let l:key = '<' . l:mod_notation . l:key . '>'
            " convert to expr-quote
            execute 'let l:key = "\' . l:key . '"'
        endif
        let l:lookup_table[l:key] = 1
    endfor

    let l:new = {
        \ 'TYPE': 'KeyTable',
        \ '_keys': l:lookup_table,
        \ 'ParseModifiers': function('markbar#KeyTable#ParseModifiers'),
        \ 'contains': function('markbar#KeyTable#contains'),
    \ }

    return l:new
endfunction

" BRIEF:    Construct a KeyTable object by combining two existing KeyTables.
function! markbar#KeyTable#fromTwoCombined(lhs, rhs) abort
    call markbar#KeyTable#AssertIsKeyTable(a:lhs)
    call markbar#KeyTable#AssertIsKeyTable(a:rhs)
    let l:new = deepcopy(a:lhs, 1)
    for l:keycode in keys(a:rhs['_keys'])
        let l:new['_keys'][l:keycode] = 1
    endfor
    return l:new
endfunction

function! markbar#KeyTable#AssertIsKeyTable(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'KeyTable'
        throw '(markbar#KeyTable) Object is not of type KeyTable: ' . a:object
    endif
endfunction

" PARAM:    mods_as_str (v:t_string)    A comma-separated list of modifiers.
" RETURNS:  (v:t_string)    Those modifiers formatted as a string, formatted
"                           like: 'C-A-S-' (for Ctrl+Alt+Shift).
function! markbar#KeyTable#ParseModifiers(mods_as_str) abort
    if type(a:mods_as_str) !=# v:t_string
        throw '(markbar#KeyTable) Argument is not a string: ' . string(a:mods_as_str)
    endif
    let l:mods_as_str = tolower(a:mods_as_str)

    let l:mod_str_to_notation = {
        \ 'shift': 'S',
        \ 'control': 'C',
        \ 'ctrl': 'C',
        \ 'alt': 'A',
        \ 'meta': 'M',
        \ 'command': 'D',
    \ }

    let l:mod_strs = split(a:mods_as_str, '\s*,\s*')
    let l:mod_strs_unique = {}

    for l:str in l:mod_strs
        let l:str = tolower(l:str)
        if !has_key(l:mod_str_to_notation, l:str)
            throw '(markbar#KeyTable) Malformed keymod, see :h getcharmod: ' . l:str
        endif
        let l:mod_strs_unique[l:str] = 1
    endfor

    let l:mods_as_keynotation = ''

    for l:mod in keys(l:mod_strs_unique)
        let l:mods_as_keynotation .= l:mod_str_to_notation[l:mod] . '-'
    endfor

    return l:mods_as_keynotation
endfunction

" RETURNS:  (v:t_bool)  `v:true` if the KeyTable contains the given key with
"                       the given modifier, `v:false` otherwise.
" PARAM:    keycode (v:t_number)    The raw keycode as returned by `getchar()`.
function! markbar#KeyTable#contains(keycode) abort dict
    call markbar#KeyTable#AssertIsKeyTable(l:self)
    let l:key = a:keycode
    if type(l:key) ==# v:t_number
        let l:key = nr2char(a:keycode)
    endif
    return has_key(l:self['_keys'], l:key)
endfunction
