" EFFECTS:  Default-initialize a MarkData object.
" DETAILS:  MarkData is a struct that holds information about a particular
"           mark, as well as the context in which that mark appears. It
"           provides basic observer functions and a convenience constructor.
function! markbar#MarkData#new() abort
    let l:new = {
        \ 'TYPE': 'MarkData',
        \ '_data': [],
        \ '_context': [],
    \ }
    let l:new['getColumnNo()'] = function('markbar#MarkData#getColumnNo', [l:new])
    let l:new['getLineNo()']   = function('markbar#MarkData#getLineNo',   [l:new])
    let l:new['getMark()']     = function('markbar#MarkData#getMark',     [l:new])
    let l:new['isGlobal()']    = function('markbar#MarkData#isGlobal',    [l:new])
    return l:new
endfunction

" EFFECTS:  Create a MarkData object from a one-line 'markstring'.
" PARAM:    markstring  (v:t_string)    The one-line markstring.
"
"           Shall be formatted as follows:
"               A     10    0   foo.txt
"               ^ mark
"                     ^ line no
"                           ^ col no
"                               ^ file/text
"           This is the manner in which the `marks` command prints output for
"           a particular mark. See `:h marks` for more details.
function! markbar#MarkData#fromMarkString(markstring) abort
    if type(a:markstring) !=# v:t_string
        throw '(markbar#MarkData#FromMarkString) Bad argument type for: ' . a:markstring
    endif
    let l:new_markdata = markbar#MarkData#new()
    let l:new_markdata['_data'] = matchlist(
        \ a:markstring,
        \ '\(\S\+\)\s\+\(\S\+\)\s\+\(\S\+\)\s*\(.*\)'
    \ )[1:3]
    if empty(l:new_markdata['_data'])
        throw '(markbar#MarkData) markstring parsing failed for: ' . a:markstring
    endif
    return l:new_markdata
endfunction

function! markbar#MarkData#AssertIsMarkData(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'MarkData'
        throw '(markbar#MarkData) Object is not of type MarkData: ' . a:object
    endif
endfunction

function! markbar#MarkData#getMark(self) abort
    call markbar#MarkData#AssertIsMarkData(a:self)
    return a:self['_data'][0]
endfunction

function! markbar#MarkData#getLineNo(self) abort
    call markbar#MarkData#AssertIsMarkData(a:self)
    return a:self['_data'][1]
endfunction

function! markbar#MarkData#getColumnNo(self) abort
    call markbar#MarkData#AssertIsMarkData(a:self)
    return a:self['_data'][2]
endfunction

function! markbar#MarkData#isGlobal(self) abort
    call markbar#MarkData#AssertIsMarkData(a:self)
    return markbar#helpers#IsGlobalMark(
        \ markbar#MarkData#getMark(a:self)
    \ )
endfunction
