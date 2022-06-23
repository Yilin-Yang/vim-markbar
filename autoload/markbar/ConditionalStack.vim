let s:ConditionalStack = {
    \ 'TYPE': 'ConditionalStack',
    \ '_data': []
\ }

" EFFECTS:  Default-initialize a conditional stack object.
" DETAILS:  The ConditionalStack is a stack data structure storing elements of
"           uncertain 'validity,' i.e. elements that might become invalid
"           after being pushed onto the stack.
"
"           ConditionalStack accepts a boolean functor that checks elements
"           for validity. It silently rejects invalid elements before they're
"           pushed, and it discards invalid elements from its top until it
"           finds a valid element to return when a user calls `top()`.
"
"           ConditionalStack accepts a maximum size. When it exceeds this
"           maximum size, it will shrink: either by 'garbage-collecting'
"           invalid elements, or by throwing away the first half of the stack.
function! markbar#ConditionalStack#New(ElementIsValid, max_size) abort
    call markbar#ensure#IsFuncref(a:ElementIsValid)
    call markbar#ensure#IsNumber(a:max_size)
    if a:max_size <# 2
        throw printf('Invalid max_size for ConditionalStack: %d', a:max_size)
    endif

    let l:new = deepcopy(s:ConditionalStack)
    let l:new._max_size = a:max_size
    let l:new.IsValid = a:ElementIsValid

    return l:new
endfunction

" EFFECTS:  Push a new element onto the given ConditionalStack.
" RETURNS:  (v:t_bool)  `v:true` if the push succeeded (i.e. if the new
"                       element was valid, and was added to the stack.)
function! markbar#ConditionalStack#push(element) abort dict
    if !l:self.IsValid(a:element)
        return v:false
    endif
    call add(l:self._data, a:element)
    if l:self.size() ># l:self._max_size
        call l:self.clean()
        call l:self.shrink()
    endif
    return v:true
endfunction
let s:ConditionalStack.push = function('markbar#ConditionalStack#push')

" EFFECTS:  - Return the topmost valid element in the ConditionalStack.
"           - Throw an exception if none could be found.
function! markbar#ConditionalStack#top() abort dict
    let l:stack = l:self._data
    let l:IsValid = l:self.IsValid
    while len(l:stack) && !l:IsValid(l:stack[-1])
        call remove(l:stack, -1)
    endwhile
    if empty(l:stack)
        throw 'ConditionalStack is empty!'
    endif
    return l:stack[-1]
endfunction
let s:ConditionalStack.top = function('markbar#ConditionalStack#top')

" EFFECTS:  Return the total number of elements, valid and invalid, currently
"           in the ConditionalStack.
function! markbar#ConditionalStack#size() abort dict
    return len(l:self._data)
endfunction
let s:ConditionalStack.size = function('markbar#ConditionalStack#size')

" EFFECTS:  Remove all invalid elements from the stack.
function! markbar#ConditionalStack#clean() abort dict
    let l:stack = l:self._data
    let l:IsValid = l:self.IsValid
    let l:i = len(l:stack)
    while l:i
        let l:i -= 1
        if l:IsValid(l:stack[l:i])
            continue
        endif
        call remove(l:stack, l:i)
    endwhile
endfunction
let s:ConditionalStack.clean = function('markbar#ConditionalStack#clean')

" EFFECTS:  Discard the first half of the ConditionalStack if it exceeds its
"           maximum size threshold.
function! markbar#ConditionalStack#shrink() abort dict
    let l:stack = l:self._data
    let l:size = len(l:stack)
    if l:size > l:self._max_size
        let l:self._data = l:stack[l:size/2:]
    endif
endfunction
let s:ConditionalStack.shrink = function('markbar#ConditionalStack#shrink')
