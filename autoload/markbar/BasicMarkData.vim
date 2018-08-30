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
    if a:0
        let a:orig_mark_data = get(a:, 1, v:false)
        call markbar#MarkData#AssertIsMarkData(a:orig_mark_data)
        let l:new['mark']     = a:orig_mark_data.getMark()
        let l:new['line']     = a:orig_mark_data.getLineNo()
        let l:new['column']   = a:orig_mark_data.getColumnNo()
        let l:new['filename'] = markbar#helpers#ParentFilename(l:new['mark'])
        let l:new['context']  = deepcopy(a:orig_mark_data['_context'])
    endif
    return l:new
endfunction
