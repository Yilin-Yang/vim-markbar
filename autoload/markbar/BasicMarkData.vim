" EFFECTS:  Default-initialize a BasicMarkData object from a markbar#MarkData.
" DETAILS:  BasicMarkData is a 'plain-old-data' struct that holds information
"           about a particular mark, as well as the context in which that mark
"           appears.
"
"           BasicMarkData is meant to serve as a component of vim-markbar's
"           public interface, as the more robust MarkData object is not
"           guaranteed to have a stable API between plugin versions.
function! markbar#BasicMarkData#new(orig_mark_data) abort
    let l:new = {'TYPE': 'BasicMarkData'}
    let l:m = a:orig_mark_data.getMark()
    let l:new.mark     = l:m
    let l:new.line     = a:orig_mark_data.getLineNo()
    let l:new.column   = a:orig_mark_data.getColumnNo()
    if markbar#helpers#IsGlobalMark(l:m) || markbar#helpers#IsNumberedMark(l:m)
        let l:new.filename = markbar#helpers#ParentFilename(l:new.mark)
    else
        let l:last_active = g:markbar_model.getActiveBuffer()
        let l:new.filename = bufname(l:last_active)
    endif
    let l:new.context = deepcopy(a:orig_mark_data._context)
    return l:new
endfunction
