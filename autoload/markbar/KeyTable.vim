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
        fi
    endfor

    let l:lookup_table = {}
    for [l:key, l:mods] in a:keys_and_mods
        let l:mod_bitflags = markbar#KeyTable#ParseModifiers(l:mods)
        if !has_key(l:lookup_table, l:key)
            let l:lookup_table[l:key] = { l:mod_bitflags : 1 }
        else
            let l:lookup_table[l:key][l:mod_bitflags] = 1
        endif
    endfor

    let l:new = {
        \ 'TYPE': 'KeyTable',
        \ '_keys': l:lookup_table
    \ }

    return l:new
endfunction

function! markbar#KeyTable#AssertIsKeyTable(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'KeyTable'
        throw '(markbar#KeyTable) Object is not of type KeyTable: ' . a:object
    endif
endfunction

" PARAM:    mods_as_str (v:t_string)    A comma-separated list of modifiers.
" RETURNS:  (v:t_number)    Those modifiers formatted as a set of bitflags,
"                           as defined by `:help getcharmod()`.
function! markbar#KeyTable#ParseModifiers(mods_as_str) abort
    if type(a:mods_as_str) !=# v:t_string
        throw '(markbar#KeyTable) Argument is not a string: ' . string(a:mods_as_str)
    endif
    let l:mods_as_str = tolower(a:mods_as_str)

    let l:mod_str_to_num = {
        \ '': 0,
        \ 'shift': 2,
        \ 'control': 4,
        \ 'alt': 8,
        \ 'meta': 16,
        \ 'mouse double click': 32,
        \ 'mouse triple click': 64,
        \ 'mouse quadruple click': 96,
        \ 'command': 128,
    \ }

    let l:mod_strs = split(a:mods_as_str, '\s*,\s*')
    let l:mod_strs_unique = {}

    " TODO: refuse to accept quadruple click?
    for l:str in l:mod_strs
        let l:str = tolower(l:str)
        if !has_key(l:mod_str_to_num, l:str)
            throw '(markbar#KeyTable) Malformed keymod, see :h getcharmod: ' . l:str
        endif
        let l:mod_strs_unique[l:str] = 1
    endfor

    let l:mods_as_bitflags = 0

    for l:mod in keys(l:mod_strs_unique)
        let l:mods_as_bitflags += l:mod_str_to_num[l:mod]
    endfor

    return l:mods_as_bitflags
endfunction

" RETURNS:  (v:t_bool)  `v:true` if the KeyTable contains the given key with
"                       the given modifier, `v:false` otherwise.
" PARAM:    keycode (v:t_number)    The raw keycode as returned by `getchar()`.
" PARAM:    charmod (v:t_number)    The raw modifiers as returned by
"                                   `getcharmod()`.
function! markbar#KeyTable#contains(keycode, charmod) abort dict
    call markbar#KeyTable#AssertIsKeyTable(l:self)
    let l:key = nr2char(a:keycode)
    return   has_key(l:self['_keys'], l:key)
        \ && has_key(l:self['_keys'][l:key], a:charmod)
endfunction
