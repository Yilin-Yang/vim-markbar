function! markbar#ensure#IsNumber(Object)
    if type(a:Object) ==# v:t_number
        return a:Object
    endif
    throw printf('Object is not an integer: %s', string(a:Object))
endfunction

function! markbar#ensure#IsString(Object) abort
    if type(a:Object) ==# v:t_string
        return a:Object
    endif
    throw printf('Object is not a string: %s', string(a:Object))
endfunction

function! markbar#ensure#IsFuncref(Object)
    if type(a:Object) ==# v:t_func
        return a:Object
    endif
    throw printf('Object is not a funcref: %s', string(a:Object))
endfunction

function! markbar#ensure#IsList(Object)
    if type(a:Object) ==# v:t_list
        return a:Object
    endif
    throw printf('Object is not a list: %s', string(a:Object))
endfunction

function! markbar#ensure#IsDictionary(Object)
    if type(a:Object) ==# v:t_dict
        return a:Object
    endif
    throw printf('Object is not a dict: %s', string(a:Object))
endfunction

function! markbar#ensure#IsFloat(Object)
    if type(a:Object) ==# v:t_float
        return a:Object
    endif
    throw printf('Object is not a float: %s', string(a:Object))
endfunction

function! markbar#ensure#IsBoolean(Object)
    if type(a:Object) ==# v:t_bool
        return a:Object
    endif
    throw printf('Object is not a boolean: %s', string(a:Object))
endfunction

function! markbar#ensure#IsClass(Object, classname) abort
    if type(a:Object) ==# v:t_dict && get(a:Object, 'TYPE', '') ==# a:classname
        return a:Object
    endif
    throw printf('Object is not of type %s: %s',
        \ a:classname, string(a:Object))
endfunction

" BRIEF:    Ensure that a string is a valid mark identifier.
function! markbar#ensure#IsMarkChar(Object) abort
    call markbar#ensure#IsString(a:Object)
    if !has_key(markbar#constants#ALL_MARKS_DICT(), a:Object)
        throw printf('Invalid mark name: %s', a:Object)
    endif
    return a:Object
endfunction
