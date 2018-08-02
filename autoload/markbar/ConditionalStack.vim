" EFFECTS:  Default-initialize a conditional stack object.
" DETAILS:  The ConditionalStack is a stack data structure storing elements of
"           uncertain 'validity,' i.e. elements that might not be known to be
"           invalid until one tries to access the top of the stack.
"
"           ConditionalStack accepts a boolean functor in its constructor that
"           it uses to check its elements for validity. It can silently reject
"           invalid elements before they're pushed, and it can intelligently
"           discard invalid elements when a user tries to access its top.
"
"           ConditionalStack can also accept a maximum size. When it exceeds
"           this maximum size, it will shrink: either by 'garbage-collecting'
"           invalid elements, or by arbitrarily throwing away the first half
"           of the stack.
function! markbar#ConditionalStack#new() abort
    let l:new = {
        \ 'TYPE': 'ConditionalStack',
        \ '_data': [],
        \ '_max_size': 9999999999,
        \ '_is_valid()': -1,
    \ }
    let l:new['clean()']  = function('markbar#ConditionalStack#clean',  [l:new])
    let l:new['push()']   = function('markbar#ConditionalStack#push',   [l:new])
    let l:new['shrink()'] = function('markbar#ConditionalStack#shrink', [l:new])
    let l:new['top()']    = function('markbar#ConditionalStack#top',    [l:new])
endfunction

" EFFECTS:  Construct a conditional stack with a given validity funcref.
function! markbar#ConditionalStack#new(funcref) abort
    if type(a:funcref) !=# v:t_func
        throw '(markbar#ConditionalStack) Bad argument type for: ' . a:funcref
    endif
    let l:new = markbar#ConditionalStack#new()
    let l:new['_is_valid()'] = a:funcref
    return l:new
endfunction

" EFFECTS:  Construct a conditional stack with a given validity funcref and
"           maximum size.
function! markbar#ConditionalStack#new(funcref, max_size) abort
    let l:max_size = a:max_size + 0
    if !l:max_size || l:max_size <# 2
        throw '(markbar#ConditionalStack) Invalid max_size: ' . a:max_size
    endif
    let l:new = markbar#ConditionalStack#new(a:funcref)
    let l:new['_max_size'] = l:max_size
    return l:new
endfunction

function! markbar#ConditionalStack#AssertIsConditionalStack(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'ConditionalStack'
        throw '(markbar#ConditionalStack) Object is not of type ConditionalStack: ' . a:object
    endif
endfunction

" EFFECTS:  Pushes a new element onto the given ConditionalStack.
" RETURN:   (v:t_bool)  `v:true` if the push succeeded (i.e. if the new
"                       element was valid, and was added to the stack.)
function! markbar#ConditionalStack#push(self, element) abort
    call markbar#ConditionalStack#AssertIsConditionalStack(a:self)
    if !a:self['_is_valid()'](a:element) | return v:false | endif
    let a:self['_data'] += [a:element]
    return v:true
endfunction

" EFFECTS:  - Returns the topmost valid element in the ConditionalStack.
"           - Throws an exception if none could be found.
"           - Shrinks the stack if the new element makes it too large.
function! markbar#ConditionalStack#top(self) abort
    call markbar#ConditionalStack#AssertIsConditionalStack(a:self)
    let l:stack = a:self['_data']
    let l:is_valid = a:self['_is_valid()']
    while !l:is_valid(l:stack[-1])
        call remove(l:stack[-1])
    endwhile

    if empty(l:stack) | throw '(markbar#ConditionalStack) Called top() when empty!' | endif
    let l:top = l:stack[-1]

    if len(l:stack) > a:self['_max_size']
        call markbar#ConditionalStack#clean(a:self)
        call markbar#ConditionalStack#shrink(a:self)
    endif

    return l:top
endfunction

" EFFECTS:  Removes all invalid elements from the stack.
function! markbar#ConditionalStack#clean(self) abort
    call markbar#ConditionalStack#AssertIsConditionalStack(a:self)
    let l:stack = a:self['_data']
    let l:is_valid = a:self['_is_valid()']
    let l:i = len(l:stack)
    while l:i
        let l:i -= 1
        if l:is_valid(l:stack[l:i]) | continue | endif
        call remove(l:stack, l:i)
    endwhile
endfunction

" EFFECTS:  Discard the first half of the ConditionalStack if it exceeds its
"           maximum size threshold.
function! markbar#ConditionalStack#shrink(self) abort
    call markbar#ConditionalStack#AssertIsConditionalStack(a:self)
    let l:stack = a:self['_data']
    let l:size = len(l:stack)
    if l:size > a:self['_max_size']
        let l:stack = l:stack[l:size / 2 : ]
    endif
endfunction
