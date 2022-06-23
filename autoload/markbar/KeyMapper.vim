let s:KeyMapper = {
    \ 'TYPE': 'KeyMapper',
    \ '_keys_to_map': v:null,
    \ '_Callback': v:null,
\ }

" BRIEF:    For bulk mapping of a number of keys in similar ways.
"
" MEMBER:   _keys_to_map    (v:t_list)
"                   Left-hand-sides for map commands, and the original
"                   'building block' constituents of the LHS.
"
"                   Elements consist of:
"                   0)  (v:t_string)    The left-hand-side expr to be used in
"                                       a map command.
"                   1)  (v:t_list)      Original LHS 'building blocks.'
"                                       Consists of:
"                       0)  (v:t_string)    The original key.
"                       1)  (v:t_string)    The comma-separated modifers.
"                       2)  (v:t_string)    The 'prefix' found in the LHS expr.
" MEMBER:   _Callback     (v:t_func)
"                   A function reference having the signature:
"                       function! ExCallback(key, mods, prefix)
"                   Where `a:key`, `a:mods`, and `a:prefix` are `v:t_string`
"                   objects formatted as they are in a:keys_mods_prefixes.
"
"                   Serves as the RHS of the mappings created by the
"                   KeyMapper, e.g. a mapping 'X' will effectively be mapped to:
"                       :call ExCallback(l:key_in_X, l:mods_in_X, l:prefix_in_X)<cr>
" MEMBER:   __self_ref      (v:t_string)    'Pointer-to-self'.
"                   g: variable reference to this KeyMapper object, usable as
"                   a RHS in a map command. Keeps the object alive in memory
"                   even after its parent is destroyed.

" used for name mangling
let s:counter = 0

" BRIEF:    Construct a KeyMapper object.
" PARAM:    keys_mods_prefixes  (v:t_list)  A list of three-element `v:t_list`'s,
"               each corresponding to a particular keymapping and each containing:
"               1)  A one-character `v:t_string` corresponding to a
"                   keyboard key (e.g. a letter, number, etc.)
"               2)  A `v:t_string` of comma-separated modifiers to be
"                   applied to that key.
"               3)  A `v:t_string` containing a 'prefix' to be prepended to
"                   the mapping.
" PARAM:    Callback    (v:t_func)  As described above, or v:null if it will
"                           be set later through setCallback.
function! markbar#KeyMapper#New(keys_mods_prefixes, Callback) abort
    call markbar#ensure#IsList(a:keys_mods_prefixes)
    for l:i in a:keys_mods_prefixes
        if type(l:i) !=# v:t_list && len(l:i) !=# 2
            throw 'Malformed key-and-modifier: ' . string(l:i)
        endif
    endfor

    let l:keys_to_map = []
    for [l:key, l:mods, l:prefix] in a:keys_mods_prefixes
        if len(l:key) !=# 1
            throw 'Bad keycode, should have len 1: ' . l:key
        endif
        " remember the 'actual' basic key, e.g. 'a' in '<C-M-a>'
        let l:actual_key = l:key
        let l:map_cmd_lhs = l:key
        if len(l:mods)
            let l:mod_notation = markbar#KeyMapper#ParseModifiers(l:mods)
            let l:map_cmd_lhs = printf('<%s%s>', l:mod_notation, l:key)
        endif
        let l:map_cmd_lhs = l:prefix.l:map_cmd_lhs
        call add(l:keys_to_map,
            \ [l:map_cmd_lhs, [l:actual_key, l:mods, l:prefix]])
    endfor

    let l:new = deepcopy(s:KeyMapper)
    let l:new._keys_to_map = l:keys_to_map

    if a:Callback !=# v:null
        call l:new.setCallback(a:Callback)
    endif

    let s:counter += 1
    let l:self_ref = 'g:markbar_KeyMapper_'.s:counter
    execute printf('let %s = l:new', l:self_ref)
    let l:new.__self_ref = l:self_ref

    return l:new
endfunction

" BRIEF:    Make a `uniform' KeyMapper; same modifiers and prefixes for all keys.
" PARAM:    keys    (v:t_string)    Every individual character to be included
"                                   in the KeyMapper, e.g. 'abc' to map a, b,
"                                   and c.
" PARAM:    modifiers   (v:t_string)    Comma-separated list of modifiers to
"                                       be applied to every key.
" PARAM:    prefix  (v:t_string)    Prefix to be prepended to every keymapping.
function! markbar#KeyMapper#NewWithSameModsPrefixes(keys, modifiers, prefix,
                                                  \ Callback) abort
    call markbar#ensure#IsString(a:keys)
    call markbar#ensure#IsString(a:modifiers)
    call markbar#ensure#IsString(a:prefix)

    let l:keys_mods_prefix = []
    let l:i = 0
    while l:i <# len(a:keys)
        let l:m = a:keys[l:i]
        call add(l:keys_mods_prefix, [l:m, a:modifiers, a:prefix])
        let l:i += 1
    endwhile

    return markbar#KeyMapper#New(l:keys_mods_prefix, a:Callback)
endfunction


" PARAM:    mods_as_str (v:t_string)    Comma-separated list of modifiers.
" RETURNS:  (v:t_string)    Modifiers formatted as a string, formatted
"                           like: 'C-A-S-' (for Ctrl+Alt+Shift).
function! markbar#KeyMapper#ParseModifiers(mods_as_str) abort
    call markbar#ensure#IsString(a:mods_as_str)
    let l:mods_as_str = tolower(a:mods_as_str)

    let l:mod_str_to_notation = {
        \ 'shift': 'S',
        \ 'control': 'C',
        \ 'ctrl': 'C',
        \ 'alt': 'A',
        \ 'meta': 'M',
        \ 'command': 'D',
    \ }

    let l:mod_strs = split(l:mods_as_str, '\s*,\s*')
    let l:unique_mod_strs = {}

    for l:str in l:mod_strs
        if !has_key(l:mod_str_to_notation, l:str)
            throw 'Malformed keymod, see :h getcharmod: ' . l:str
        endif
        let l:unique_mod_strs[l:str] = 1
    endfor

    let l:mods_as_keynotation = ''
    for l:mod in keys(l:unique_mod_strs)
        let l:mods_as_keynotation .= l:mod_str_to_notation[l:mod] . '-'
    endfor

    return l:mods_as_keynotation
endfunction

" BRIEF:    Replace the callback function used as the RHS in mappings.
function! markbar#KeyMapper#setCallback(NewCallback) abort dict
    call markbar#ensure#IsFuncref(a:NewCallback)
    let l:self._Callback = a:NewCallback
endfunction
let s:KeyMapper.setCallback = function('markbar#KeyMapper#setCallback')

" BRIEF:    Set all keymappings.
" PARAM:    mapcommand  (v:t_string)    The particular ':map' command to use
"                               when mapping each key. May contain any mapmode
"                               (e.g. `map, vmap, tunmap, snoremap`) and
"                               special arguments (e.g.  `<buffer>, <silent>,
"                               <expr>`).
" DETAILS:  See `:help :map-commands` and `:help :map-arguments` for details
"           on how to format a:mapcommand.
function! markbar#KeyMapper#setMappings(mapcommand) abort dict
    let l:keys_to_map_ref = l:self._keys_to_map
    for [l:map_cmd_lhs, l:lhs_pieces] in l:keys_to_map_ref
        let l:prefix = l:lhs_pieces[2]
        let l:command = printf('%s %s :call %s._Callback(',
            \ a:mapcommand, l:map_cmd_lhs, l:self.__self_ref)

        " handle edge case where mapped key is the single quote '
        " ''' --> syntax error, instead write a double-quoted apostrophe
        if l:lhs_pieces[0] !=# "'"
            let l:command .= printf("'%s','", l:lhs_pieces[0])
        else
            let l:command .= printf('"%s",''', l:lhs_pieces[0])
        endif

        let l:command .= l:lhs_pieces[1]."','"

        " :execute parses:
        "           'map <foo> :call Blah('<space>')<cr>'
        "                                  ^ note
        "       as:
        "           'map <foo> :call Blah(' ')<cr>'
        " This is not desired behavior. We want to preserve the
        " *exact* contents of the quoted string.
        "
        " Do this by 'breaking' the affected string:
        "           'map <foo> :call Blah('<'.'space>')<cr>'
        "                                    ^ note
        if len(l:prefix) ># 1
            let l:command .= printf("%s'.'%s')<cr>", l:prefix[0], l:prefix[1:])
        elseif l:prefix ==# "'"
            " escape single quote inside of a single-quoted string by
            " prepending another single quote
            let l:command .= printf("'%s')<cr>", l:prefix)
        else
            let l:command .= l:prefix."')<cr>"
        endif
        execute l:command
    endfor
endfunction
let s:KeyMapper.setMappings = function('markbar#KeyMapper#setMappings')
