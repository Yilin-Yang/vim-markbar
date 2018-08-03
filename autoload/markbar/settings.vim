" RETURNS:  (v:t_string)    All marks to display in the markbar, in order.
function! markbar#settings#MarksToDisplay() abort
    if !exists('g:markbar_marks_to_display')
        let g:markbar_marks_to_display =
            \ 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    endif
    return g:markbar_marks_to_display
endfunction

" RETURNS:  (v:t_bool)      Whether to open markbars as vertical splits
"                           (`v:true`) or horizontal splits (`v:false`).
function! markbar#settings#MarkbarOpenVertical() abort
    if !exists('g:markbar_open_vertical')
        let g:markbar_open_vertical = v:true
    endif
    return g:markbar_open_vertical
endfunction

" RETURNS:  (v:t_number)    The width of an opened vertical markbar, in columns.
function! markbar#settings#MarkbarWidth() abort
    if !exists('g:markbar_width')
        let g:markbar_width = 30
    endif
    return g:markbar_width
endfunction

" RETURNS:  (v:t_number)    The height of an opened horizontal markbar, in lines.
function! markbar#settings#MarkbarHeight() abort
    if !exists('g:markbar_height')
        let g:markbar_height = 30
    endif
    return g:markbar_height
endfunction

" RETURNS:  (v:t_bool)      Whether to close an open markbar after jumping to
"                           a mark from the markbar.
function! markbar#settings#CloseAfterGoTo() abort
    if !exists('g:markbar_close_after_go_to')
        let g:markbar_close_after_go_to = v:true
    endif
    return g:markbar_close_after_go_to
endfunction

" RETURNS:  (v:t_string)    The positional command modifier to apply when
"                           opening the markbar.
function! markbar#settings#OpenPosition() abort
    if !exists('g:markbar_open_position')
        let g:markbar_open_position = 'botright'
    endif
    let l:valid_positions = [
        \ 'leftabove', 'aboveleft', 'rightbelow',
        \ 'belowright', 'topleft', 'botright'
    \ ]
    if index(l:valid_positions, g:markbar_open_position) ==# -1
        throw '(vim-markbar) Bad value for g:markbar_open_position: ' . g:markbar_open_position
    endif
    return g:markbar_open_position
endfunction

" RETURNS:  (v:t_string)    The name to give to any opened markbar buffers.
function! markbar#settings#MarkbarBufferName() abort
    if !exists('g:markbar_buffer_name')
        let g:markbar_buffer_name = '[ Markbar ]'
    endif
    return g:markbar_buffer_name
endfunction

" RETURNS:  (v:t_string)    A block of text with which to indent lines of
"                           context in the markbar proper.
function! markbar#settings#ContextIndentBlock() abort
    if !exists('g:markbar_context_indent_block')
        let g:markbar_context_indent_block = '    '
    endif

    " if user specified a number, 'assemble' an indent block
    if type(g:markbar_context_indent_block ==# v:t_number)
        let l:block_to_return = ''
        let l:i = 0
        while l:i <# g:markbar_context_indent_block
            let l:block_to_return += ' '
            let l:i += 1
        endwhile
        let g:markbar_context_indent_block = l:block_to_return
    endif

    if !exists('g:markbar_context_indent_block_NOWARN')
        let l:silence_text =
            \ '(Set g:markbar_context_indent_block_NOWARN '
            \ . 'to 1 to silence this warning.)'
        if !len(g:markbar_context_indent_block)
                \ ||  (g:markbar_context_indent_block[0] !=# ' '
                \   && g:markbar_context_indent_block[0] !=# "\t")
            echoerr '(vim-markbar) WARNING: Context indentation block '
                \ . 'that doesn''t start with a space or tab '
                \ . 'will break markbar syntax highlighting. '
                \ . l:silence_text
        endif
        if len(matchstr(g:markbar_context_indent_block, '['))
            echoerr '(vim-markbar) WARNING: Given context indent block: "'
                \ . g:markbar_context_indent_block
                \ . '" contains dangerous character "[" that may break '
                \ . "markbar's 'jump to mark' mappings. "
                \ . l:silence_text
        endif
    endif

    return g:markbar_context_indent_block
endfunction

" RETURNS:  (v:t_list)      A list populated with a number of zero-length
"                           strings equal to the number of blank spaces that
"                           should exist in between markbar 'section
"                           headings'. Should be at least 1, or else syntax
"                           highlighting will break.
function! markbar#settings#MarkbarSectionSeparator() abort
    if !exists('g:markbar_section_separation')
        let g:markbar_section_separation = 1
    endif

    if g:markbar_section_separation <# 0
        throw '(vim-markbar) Bad value for g:markbar_section_separation: '
            \ . g:markbar_section_separation
    endif

    if !exists('g:markbar_section_separation_NOWARN') && !g:markbar_section_separation
        echoerr '(vim-markbar) WARNING: A zero-line section separation will break '
            \ . 'markbar syntax highlighting. (Set g:markbar_section_separation_NOWARN '
            \ . 'to 1 to silence this warning.)'
    endif

    let l:separator = []
    let l:i = 0
    while l:i <# g:markbar_section_separation
        let l:separator += ['']
        let l:i += 1
    endwhile
    return l:separator
endfunction

" RETURNS:  (v:t_dict)      A dictionary populated with the `bufhidden` values
"                           that indicate that a buffer should be ignored.
function! markbar#settings#IgnoreBufferCriteria() abort
    if !exists('g:markbar_ignore_buffer_criteria')
        let g:markbar_ignore_buffer_criteria = ['unload', 'delete', 'wipe']
    endif

    let l:valid_ignore_criteria = ['unload', 'delete', 'wipe', 'hide', '<empty>']
    let l:criteria = {}
    for l:criterion in g:markbar_ignore_buffer_criteria
        if index(l:valid_ignore_criteria, l:criterion) ==# -1
            throw '(vim-markbar) Invalid IgnoreBuffer criterion: ' . l:criterion
        endif
        if l:criterion ==# '<empty>'
            let l:criteria[''] = 1
        else
            let l:criteria[l:criterion] = 1
        endif
    endfor
    return l:criteria
endfunction

" RETURNS:  (v:t_number)    The maximum permissible size of
"                           `g:activeBufferStack`.
function! markbar#settings#MaximumActiveBufferHistory() abort
    if !exists('g:markbar_maximum_active_buffer_history')
        let g:markbar_maximum_active_buffer_history = 100
    endif
    if type(g:markbar_maximum_active_buffer_history) !=# v:t_number
        throw 'Invalid data type for g:markbar_maximum_active_buffer_history.'
    endif
    if g:markbar_maximum_active_buffer_history <# 2
        throw 'Value too small for g:markbar_maximum_active_buffer_history: '
            \ . g:markbar_maximum_active_buffer_history
    endif
    return g:markbar_maximum_active_buffer_history
endfunction

" RETURNS:  (v:t_number)    The number of lines of context to retrieve around
"                           marks, including the line that holds the mark.
function! markbar#settings#NumLinesContext() abort
    if !exists('g:markbar_num_lines_context')
        let g:markbar_num_lines_context = 5
    endif
    return g:markbar_num_lines_context
endfunction

" RETURNS:  (v:t_bool)      `v:true` if the 'jump to mark from markbar'
"                           mapping should go to the exact line *and column*
"                           of the mark, or `v:false` if it should go to the
"                           line (and column zero).
function! markbar#settings#JumpToExactPosition() abort
    if !exists('g:markbar_jump_to_exact_position')
        let g:markbar_jump_to_exact_position = v:true
    endif
    return g:markbar_jump_to_exact_position
endfunction
