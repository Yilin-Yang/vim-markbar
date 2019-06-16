" EFFECTS:  Default-initialize a BasicMarkData object.
" DETAILS:  BasicMarkData is a 'plain-old-data' struct that holds information
"           about a particular mark, as well as the context in which that mark
"           appears.
"
"           BasicMarkData is meant to serve as a component of vim-markbar's
"           public interface, as the more robust MarkData object is not
"           guaranteed to have a stable API between plugin versions.
function! markbar#BasicMarkData#new(...) abort
    let l:new = {
        \ 'TYPE': 'BasicMarkData',
        \ 'mark': 0,
        \ 'line': 0,
        \ 'column': 0,
        \ 'filename': 0,
        \ 'context': 0,
    \ }
    if !a:0 | return l:new | endif
    let l:orig_mark_data = get(a:, 1, v:false)
    call markbar#MarkData#AssertIsMarkData(l:orig_mark_data)
    let l:m = l:orig_mark_data.getMark()
    let l:new.mark     = l:m
    let l:new.line     = l:orig_mark_data.getLineNo()
    let l:new.column   = l:orig_mark_data.getColumnNo()
    if markbar#helpers#IsGlobalMark(l:m) || markbar#helpers#IsNumberedMark(l:m)
        let l:new.filename = markbar#helpers#ParentFilename(l:new.mark)
    else
        let l:last_active = g:markbar_model.getActiveBuffer()
        let l:new.filename = bufname(l:last_active)
    endif
    let l:new.context  = deepcopy(l:orig_mark_data._context)
    return l:new
endfunction

function! markbar#BasicMarkData#AssertIsBasicMarkData(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'BasicMarkData'
        throw '(markbar#BasicMarkData) Object is not of type BasicMarkData: ' . a:object
    endif
endfunction
