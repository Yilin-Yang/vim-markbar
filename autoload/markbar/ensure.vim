function! markbar#ensure#IsNumber(Object)
    if type(a:Object) ==# v:t_number
        return
    endif
    throw printf('Object is not an integer: %s', string(a:Object))
endfunction

function! markbar#ensure#IsString(Object) abort
    if type(a:Object) ==# v:t_string
        return
    endif
    throw printf('Object is not a string: %s', string(a:Object))
endfunction

function! markbar#ensure#IsFuncref(Object)
    if type(a:Object) ==# v:t_func
        return
    endif
    throw printf('Object is not a funcref: %s', string(a:Object))
endfunction

function! markbar#ensure#IsList(Object)
    if type(a:Object) ==# v:t_list
        return
    endif
    throw printf('Object is not a list: %s', string(a:Object))
endfunction

function! markbar#ensure#IsDictionary(Object)
    if type(a:Object) ==# v:t_dict
        return
    endif
    throw printf('Object is not a dict: %s', string(a:Object))
endfunction

function! markbar#ensure#IsFloat(Object)
    if type(a:Object) ==# v:t_float
        return
    endif
    throw printf('Object is not a float: %s', string(a:Object))
endfunction

function! markbar#ensure#IsBoolean(Object)
    if type(a:Object) ==# v:t_bool
        return
    endif
    throw printf('Object is not a boolean: %s', string(a:Object))
endfunction

function! markbar#ensure#IsClass(Object, classname) abort
    if type(a:Object) ==# v:t_dict && a:Object.TYPE ==# a:classname
        return
    endif
    throw printf('Object is not of type %s: %s',
        \ a:classname, string(a:Object))
endfunction
