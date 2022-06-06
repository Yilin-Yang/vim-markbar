" EFFECTS:  Default-initialize a BasicMarkData object from a markbar#MarkData.
" DETAILS:  BasicMarkData is a 'plain-old-data' struct that holds information
"           about a particular mark, as well as the context in which that mark
"           appears.
"
"           BasicMarkData is meant to serve as a component of vim-markbar's
"           public interface, as the more robust MarkData object is not
"           guaranteed to have a stable API between plugin versions.
function! markbar#BasicMarkData#New(orig_mark_data) abort
    let l:new = {'TYPE': 'BasicMarkData'}
    let l:new.mark = a:orig_mark_data.getMarkChar()
    let l:new.line = a:orig_mark_data.getLineNo()
    let l:new.column = a:orig_mark_data.getColumnNo()
    let l:new.full_filepath = a:orig_mark_data.getFilename()
    let l:new.filename = a:orig_mark_data.getBufname()
    let l:new.context = deepcopy(a:orig_mark_data._context)
    let l:new.mark_line_idx = markbar#helpers#MarkLineIdxInContext(l:new.context)
    let l:new.user_given_name = a:orig_mark_data.getUserName()
    let l:new.default_name = a:orig_mark_data.getDefaultName()
    return l:new
endfunction
