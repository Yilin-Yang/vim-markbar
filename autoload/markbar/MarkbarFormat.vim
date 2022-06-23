" BRIEF:    Dict of options that control markbar rendering.
" DETAILS:  Type-safe interface for getting and setting options. Passed to a
"           markbar#MarkbarTextGenerator instance; changing options in the
"           MarkbarFormat will change how the MarkbarTextGenerator renders text
"           in subsequent calls.

let s:options_and_types = {
    \ 'marks_to_display': v:t_string,
    \ 'short_help_text': v:t_list,
    \ 'verbose_help_text': v:t_list,
    \ 'show_verbose_help': v:t_bool,
    \ 'num_lines_context_around_local': v:t_number,
    \ 'num_lines_context_around_global': v:t_number,
    \ 'section_separator': v:t_list,
    \ 'indent_block': v:t_string,
    \ 'enable_mark_highlighting': v:t_bool,
    \ 'mark_marker': v:t_string,
    \ 'jump_like_backtick': v:t_bool,
    \ 'local_mark_name_format_str': v:t_string,
    \ 'local_mark_name_arguments': v:t_list,
    \ 'file_mark_name_format_str': v:t_string,
    \ 'file_mark_name_arguments': v:t_list,
    \ 'numbered_mark_name_format_str': v:t_string,
    \ 'numbered_mark_name_arguments': v:t_list,
\ }

let s:MarkbarFormat = {
    \ 'TYPE': 'MarkbarFormat',
    \ '_options': {},
\ }

" BRIEF:    Construct a MarkbarFormat object.
" PARAM:    options     (v:t_dict)  Dict having all keys in s:options_and_types
"                                   with values of proper type.
function! markbar#MarkbarFormat#New(options) abort
    call markbar#ensure#IsDictionary(a:options)
    if len(a:options) ># len(s:options_and_types)
        throw 'Too many rendering options in dict'
    endif

    let l:new = deepcopy(s:MarkbarFormat)
    for l:option in keys(s:options_and_types)
        let l:given_value = get(a:options, l:option, v:null)
        if l:given_value is v:null
            throw printf('Missing option "%s" in dict', l:option)
        endif
        call l:new.ensureCorrectTypeForOption(l:option, l:given_value)
        let l:new._options[l:option] = l:given_value
    endfor
    lockvar 1 l:new._options

    return l:new
endfunction

" BRIEF:    Throw an exception if a value has the wrong type for an option.
function! markbar#MarkbarFormat#ensureCorrectTypeForOption(option, value) abort dict
    call markbar#ensure#IsString(a:option)
    let l:correct_type = get(s:options_and_types, a:option, v:null)
    if l:correct_type is v:null
        throw printf('Invalid option: %s', a:option)
    endif
    let l:given_type = type(a:value)
    if l:given_type !=# l:correct_type
        throw printf('Option "%s" has wrong type %s, should be %s',
            \ a:option, markbar#helpers#VimLTypeToString(l:given_type),
            \ markbar#helpers#VimLTypeToString(l:correct_type))
    endif
endfunction
let s:MarkbarFormat.ensureCorrectTypeForOption = function('markbar#MarkbarFormat#ensureCorrectTypeForOption')

" EFFECTS:  Change an option's value. Throw exception on bad option name or if
"           type doesn't match.
function! markbar#MarkbarFormat#setOption(option, new_value) abort dict
    call markbar#ensure#IsString(a:option)
    call l:self.ensureCorrectTypeForOption(a:option, a:new_value)
    let l:self._options[a:option] = a:new_value
endfunction
let s:MarkbarFormat.setOption = function('markbar#MarkbarFormat#setOption')

" EFFECTS:  Change multiple options' values. Throw exception on a bad option
"           name or if a given type doesn't match.
function! markbar#MarkbarFormat#setOptions(options) abort dict
    call markbar#ensure#IsDictionary(a:options)
    for [l:option, l:new_value] in items(a:options)
        call l:self.setOption(l:option, l:new_value)
    endfor
endfunction
let s:MarkbarFormat.setOptions = function('markbar#MarkbarFormat#setOptions')

" EFFECTS:  Flip a boolean option's value.
"           Exists because `type(!v:true) == v:t_number`, so flipping a
"           boolean option through setOption is needlessly convoluted.
function! markbar#MarkbarFormat#flipOption(option) abort dict
    call markbar#ensure#IsString(a:option)
    let l:cur_val = l:self.getOption(a:option)
    if type(l:cur_val) !=# v:t_bool
        throw printf('Can''t flip non-boolean option "%s"', a:option)
    endif
    call l:self.setOption(a:option, l:cur_val ? v:false : v:true)
endfunction
let s:MarkbarFormat.flipOption = function('markbar#MarkbarFormat#flipOption')

" EFFECTS:  Get an option's value. Throw exception if option doesn't exist.
function! markbar#MarkbarFormat#getOption(option) abort dict
    call markbar#ensure#IsString(a:option)
    let l:value = get(l:self._options, a:option, v:null)
    if l:value is v:null
        throw printf('Invalid option: %s', a:option)
    endif
    return l:value
endfunction
let s:MarkbarFormat.getOption = function('markbar#MarkbarFormat#getOption')
