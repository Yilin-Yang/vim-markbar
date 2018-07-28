if exists('g:vim_markbar_autoloaded')
    finish
endif
let g:vim_markbar_autoloaded = 1

"==============================================================================
" GLOBAL VARIABLES: ==========================================================
"==============================================================================

" BRIEF:    Association between buffer numbers and their local mark databases.
" DETAILS:  The buffer with number '0' holds 'global' marks, such as file marks.
let g:buffersToDatabases = { markbar#constants#GLOBAL_MARKS() : [] }

" BRIEF:    Association between buffer numbers and mark-to-context dictionaries.
" DETAILS:  The buffer with number '0' holds 'global' marks, such as file marks.
let g:buffersToContexts = { markbar#constants#GLOBAL_MARKS() : {} }

"==============================================================================
" FUNCTIONS: =================================================================
"==============================================================================

" RETURNS:  (v:t_bool)      `v:true` if the given line number, in the *current
"                           buffer*, has a mark. `v:false` otherwise.
function! g:LineHasMark(line_no) abort
    let l:cur_buffer = bufnr('%')
    let l:marks_ptr = g:buffersToDatabases[l:cur_buffer] " alias
    let l:i = 0
    while l:i <# len(l:marks_ptr)
        if l:marks_ptr[l:i][1] ==# a:line_no
            return v:true
        endif
        let l:i += 1
    endwhile

    let l:marks_ptr = g:buffersToDatabases[0] " alias
    let l:i = 0
    while l:i <# len(l:marks_ptr)
        let l:mark_ptr = l:marks_ptr[l:i]
        if InCurrentBuffer(l:mark_ptr[0]) && l:mark_ptr[1] ==# a:line_no
            return v:true
        endif
        let l:i += 1
    endwhile

    return v:false
endfunction

" RETURNS:  (v:t_bool)      `v:true` if a line number in the given range, in
"                           the *current buffer*, has a mark. `v:false`
"                           otherwise.
function! g:RangeHasMark(start, end) abort
    if a:start ># a:end || a:start <# 0 || a:end <# 0
        throw 'Invalid range in call to RangeHasMark: '.a:start.','.a:end
    endif

    let l:cur_buffer = bufnr('%')
    let l:marks_ptr = g:buffersToDatabases[l:cur_buffer] " alias
    let l:i = 0
    while l:i <# len(l:marks_ptr)
        let l:line_no = l:marks_ptr[l:i][1]
        if l:line_no >=# a:start && l:line_no <= a:end
            return v:true
        endif
        let l:i += 1
    endwhile

    let l:marks_ptr = g:buffersToDatabases[0] " alias
    let l:i = 0
    while l:i <# len(l:marks_ptr)
        let l:mark_ptr = l:marks_ptr[l:i]
        let l:line_no = l:mark_ptr[1]
        if InCurrentBuffer(l:mark_ptr[0])
        \ && (l:line_no >=# a:start && l:line_no <=# a:end)
            return v:true
        endif
        let l:i += 1
    endwhile

    return v:false
endfunction

" EFFECTS:  Totally reconstruct the local marks database for the current
"           buffer.
function! g:PopulateBufferDatabase() abort
    let l:cur_buffer = bufnr('%')
    let l:raw_local_marks =
        \ markbar#textmanip#TrimMarksHeader(markbar#helpers#GetLocalMarks())
    let g:buffersToDatabases[l:cur_buffer] =
        \ markbar#textmanip#MarksStringToNestedList(l:raw_local_marks)
endfunction

" EFFECTS:  Totally reconstruct the global marks database.
function! g:PopulateGlobalDatabase() abort
    let l:raw_global_marks =
        \ markbar#textmanip#TrimMarksHeader(markbar#helpers#GetGlobalMarks())
    let g:buffersToDatabases[0] =
        \ markbar#textmanip#MarksStringToNestedList(l:raw_global_marks)
endfunction

"==============================================================================
" AUTOCMDS: ==================================================================
"==============================================================================

" TODO: only trigger when performing actions that affect lines with marks
" TODO: does `x` from visual mode trigger TextChanged?
" augroup vim_markbar_database_populators
"     au!
"     autocmd BufEnter,TextYankPost,TextChanged,TextChangedI
"         \ *
"         \ g:PopulateBufferDatabase() | g:PopulateGlobalDatabase()
" augroup end
