" BRIEF:    Takes formatting options and outputs text to display in a markbar.
"
" MEMBER:   format      (markbar#MarkbarFormat)
"               Formatting options for markbar text. Modifying these options
"               changes MarkbarTextGenerator's output.

let s:MarkbarTextGenerator = {
    \ 'TYPE': 'MarkbarTextGenerator',
    \ 'format': v:null,
\ }

function! markbar#MarkbarTextGenerator#New(markbar_format) abort
    call markbar#ensure#IsClass(a:markbar_format, 'MarkbarFormat')
    let l:new = deepcopy(s:MarkbarTextGenerator)
    let l:new.format = a:markbar_format
    return l:new
endfunction

" RETURNS:  (v:t_list)  Text content for the markbar as a list of strings.
" PARAM:    locals      `marks_dict` for local marks from a markbar#BufferCache.
" PARAM:    globals     Ditto, but for global marks.
function! markbar#MarkbarTextGenerator#getText(local_marks, global_marks) abort dict
    call markbar#ensure#IsDictionary(a:local_marks)
    call markbar#ensure#IsDictionary(a:global_marks)

    let l:lines = []
    call extend(l:lines, l:self.format.getOption('show_verbose_help')
                            \ ? l:self.format.getOption('verbose_help_text')
                                \ : l:self.format.getOption('short_help_text'))

    let l:marks_to_display = l:self.format.getOption('marks_to_display')
    let l:section_separator = l:self.format.getOption('section_separator')
    let l:i = -1
    while l:i <# len(l:marks_to_display)
        let l:i += 1
        let l:mark_char = l:marks_to_display[l:i]

        if !has_key(a:local_marks, l:mark_char)
                \ && !has_key(a:global_marks, l:mark_char)
            continue
        endif

        let l:is_global_mark = markbar#helpers#IsGlobalMark(l:mark_char)

        try
            let l:mark =
                \  l:is_global_mark ?
                    \ a:global_marks[l:mark_char] : a:local_marks[l:mark_char]
            call add(l:lines, l:self.getMarkHeading(l:mark))
        catch /E716/  " Key not in dictionary
            continue
        endtry

        let l:full_context = l:mark.getContext()
        let l:indent_block = l:self.format.getOption('indent_block')

        " get number of lines of context
        let l:num_lines_context = l:is_global_mark ?
                \ l:self.format.getOption('num_lines_context_around_global') :
                \ l:self.format.getOption('num_lines_context_around_local')

        let [l:start, l:end] = markbar#helpers#TrimmedContextRange(
            \ len(l:full_context), l:num_lines_context)
        if !l:self.format.getOption('enable_mark_highlighting')
            let l:j = l:start
            while l:j <# l:end
                call add(l:lines, l:indent_block . l:full_context[l:j])
                let l:j += 1
            endwhile
        else
            " insert the mark marker at the mark's line, column in the context
            let l:marker = l:self.format.getOption('mark_marker')
            let l:mark_line_idx =
                \ markbar#helpers#MarkLineIdxInContext(l:full_context)
            let l:jump_like_backtick =
                \ l:self.format.getOption('jump_like_backtick')

            let l:j = l:start
            while l:j <# l:end
                let l:line = l:full_context[l:j]
                if l:j ==# l:mark_line_idx
                    let l:col_idx = (l:jump_like_backtick) ?
                        \ l:mark.getColumnNo() - 1 : matchstrpos(l:line, '\S')[1]
                    let l:parts = markbar#helpers#SplitString(l:line, l:col_idx)
                    let l:line = l:parts[0].l:marker.l:parts[1]
                endif
                call add(l:lines, l:indent_block . l:line)
                let l:j += 1
            endwhile
        endif

        call extend(l:lines, l:section_separator)
    endwhile

    return l:lines
endfunction
let s:MarkbarTextGenerator.getText = function('markbar#MarkbarTextGenerator#getText')

" RETURNS:  (v:t_string)    Section heading for the given mark.
function! markbar#MarkbarTextGenerator#getMarkHeading(mark) abort dict
    call markbar#ensure#IsClass(a:mark, 'MarkData')
    let l:suffix = ' '

    let l:mark_char = a:mark.getMarkChar()
    if !markbar#helpers#IsGlobalMark(l:mark_char)
        let l:format_str =
            \ l:self.format.getOption('local_mark_name_format_str')
        let l:format_arg =
            \ l:self.format.getOption('local_mark_name_arguments')
    elseif markbar#helpers#IsUppercaseMark(l:mark_char)
        let l:format_str =
            \ l:self.format.getOption('file_mark_name_format_str')
        let l:format_arg =
            \ l:self.format.getOption('file_mark_name_arguments')
    else " numbered mark
        let l:format_str =
            \ l:self.format.getOption('numbered_mark_name_format_str')
        let l:format_arg =
            \ l:self.format.getOption('numbered_mark_name_arguments')
    endif

    let l:name = ''
    if !empty(l:format_str)
        let l:cmd = printf("let l:name = printf('%s'", l:format_str)

        for l:Arg in l:format_arg " capital 'Arg' to handle funcrefs
            let l:cmd .= ', '
            if type(l:Arg) == v:t_func
                let l:cmd .= string(l:Arg(markbar#BasicMarkData#New(a:mark)))
            elseif l:Arg ==# 'line'
                let l:cmd .= a:mark.getLineNo()
            elseif l:Arg ==# 'col'
                let l:cmd .= a:mark.getColumnNo()
            elseif l:Arg ==# 'fname'
                " string() to include quotes when concatenating onto l:cmd
                let l:cmd .= string(a:mark.getBufname())
            elseif l:Arg ==# 'name'
                let l:name = a:mark.getUserName()
                if empty(l:name)
                    let l:name = a:mark.getDefaultName()
                endif
                let l:cmd .= string(l:name)
            else
                throw printf('Unrecognized format argument: %s',
                    \ string(l:Arg))
            endif
        endfor
        let l:cmd .= ')'
        execute l:cmd
    endif

    " strip leading, trailing whitespace
    let l:name = matchlist(l:name, '\m^\s*\(.\{-}\)\s*$')[1]

    let l:suffix .= l:name

    return printf("['%s]:%s", a:mark.getMarkChar(), l:suffix)
endfunction
let s:MarkbarTextGenerator.getMarkHeading = function('markbar#MarkbarTextGenerator#getMarkHeading')
