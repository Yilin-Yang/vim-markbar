" BRIEF:    For bulk mapping of a number of keys in similar ways.

" BRIEF:    Construct a KeyMapper object.
" PARAM:    keys_mods_prefix    (v:t_list)  A list of three-element `v:t_list`'s,
"               each corresponding to a particular keymapping and each containing:
"               1)  A one-character `v:t_string` corresponding to a
"                   keyboard key (e.g. a letter, number, etc.)
"               2)  A `v:t_string` of comma-separated modifiers to be
"                   applied to that key.
"               3)  A `v:t_string` containing a 'prefix' to be prepended to
"                   the mapping.
" PARAM:    Callback    (v:t_func)  A function reference having the signature:
"               ```function! ExCallback(key, mods, prefix)```
"                   Where `a:key`, `a:mods`, and `a:prefix` are `v:t_string`
"                   objects formatted as they are in a:keys_mods_prefix.
function! markbar#KeyMapper#new(keys_and_mods, Callback) abort
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
        let l:actual_key = l:key
        if len(l:mods)
            let l:mod_notation = markbar#KeyTable#ParseModifiers(l:mods)
            " ugly handling for double quote edge case
            if l:key ==# '"' | let l:key = '\"' | endif
            let l:key = '<' . l:mod_notation . l:key . '>'
            " convert to expr-quote
            execute 'let l:key = "\' . l:key . '"'
        endif
        " remember the 'actual' basic key, e.g. 'a' in '<C-M-a>'
        let l:lookup_table[l:key] = l:actual_key
    endfor

    let l:new = {
        \ 'TYPE': 'KeyTable',
        \ '_keys': l:lookup_table,
        \ 'ParseModifiers': function('markbar#KeyTable#ParseModifiers'),
        \ 'contains': function('markbar#KeyTable#contains'),
    \ }

    return l:new
endfunction

function! markbar#KeyMapper#AssertIsKeyMapper(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'KeyMapper'
        throw '(markbar#KeyMapper) Object is not of type KeyMapper: ' . a:object
    endif
endfunction

" BRIEF:    Set all keymappings.
" PARAM:    mapcommand  (v:t_string)    The particular ':map' command to use
"                               when mapping each key. May contain any mapmode
"                               (e.g. `map, vmap, tunmap, snoremap`) and
"                               special arguments (e.g.  `<buffer>, <silent>,
"                               <expr>`).
" DETAILS:  See `:help :map-commands` and `:help :map-arguments` for details
"           on how to format a:mapcommand.
function! markbar#KeyMapper#setMappings(mapcommand) abort

endfunction
