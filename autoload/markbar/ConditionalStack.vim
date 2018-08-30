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
function! markbar#ConditionalStack#new(...) abort
    let l:Funcref  = get(a:, 1, -1)
    let l:max_size = get(a:, 2, 999999999)

    if type(l:Funcref) !=# v:t_number && type(l:Funcref) !=# v:t_func
        throw '(markbar#ConditionalStack) Given argument should be a funcref: ' . l:Funcref
    endif
    if !l:max_size || l:max_size <# 2
        throw '(markbar#ConditionalStack) Invalid max_size: ' . a:max_size
    endif

    let l:new = {
        \ 'TYPE': 'ConditionalStack',
        \ '_data': [],
        \ '_max_size': l:max_size,
        \ '_is_valid()': l:Funcref,
    \ }
    let l:new['clean']  = function('markbar#ConditionalStack#clean')
    let l:new['push']   = function('markbar#ConditionalStack#push')
    let l:new['shrink'] = function('markbar#ConditionalStack#shrink')
    let l:new['size']   = function('markbar#ConditionalStack#size')
    let l:new['top']    = function('markbar#ConditionalStack#top')
    return l:new
endfunction

function! markbar#ConditionalStack#AssertIsConditionalStack(object) abort
    if type(a:object) !=# v:t_dict || a:object['TYPE'] !=# 'ConditionalStack'
        throw '(markbar#ConditionalStack) Object is not of type ConditionalStack: ' . a:object
    endif
endfunction

" EFFECTS:  Push a new element onto the given ConditionalStack.
" RETURNS:  (v:t_bool)  `v:true` if the push succeeded (i.e. if the new
"                       element was valid, and was added to the stack.)
function! markbar#ConditionalStack#push(element) abort dict
    call markbar#ConditionalStack#AssertIsConditionalStack(self)
    if !self['_is_valid()'](a:element) | return v:false | endif
    let self['_data'] += [a:element]
    if self.size() ># self['_max_size']
        call self.clean()
        call self.shrink()
    endif
    return v:true
endfunction

" EFFECTS:  - Return the topmost valid element in the ConditionalStack.
"           - Throw an exception if none could be found.
"           - Shrink the stack if the new element makes it too large.
function! markbar#ConditionalStack#top() abort dict
    call markbar#ConditionalStack#AssertIsConditionalStack(self)
    let l:stack = self['_data']
    let l:IsValid = self['_is_valid()']
    while len(l:stack) && !l:IsValid(l:stack[-1])
        call remove(l:stack, -1)
    endwhile

    if empty(l:stack) | throw '(markbar#ConditionalStack) Called top() when empty!' | endif
    let l:top = l:stack[-1]

    if len(l:stack) > self['_max_size']
        call self.clean()
        call self.shrink()
    endif

    return l:top
endfunction

" EFFECTS:  Return the total number of elements, valid and invalid, currently
"           in the ConditionalStack.
function! markbar#ConditionalStack#size() abort dict
    call markbar#ConditionalStack#AssertIsConditionalStack(self)
    return len(self['_data'])
endfunction

" EFFECTS:  Remove all invalid elements from the stack.
function! markbar#ConditionalStack#clean() abort dict
    call markbar#ConditionalStack#AssertIsConditionalStack(self)
    let l:stack = self['_data']
    let l:IsValid = self['_is_valid()']
    let l:i = len(l:stack)
    while l:i
        let l:i -= 1
        if l:IsValid(l:stack[l:i]) | continue | endif
        call remove(l:stack, l:i)
    endwhile
endfunction

" EFFECTS:  Discard the first half of the ConditionalStack if it exceeds its
"           maximum size threshold.
function! markbar#ConditionalStack#shrink() abort dict
    call markbar#ConditionalStack#AssertIsConditionalStack(self)
    let l:stack = self['_data']
    let l:size = len(l:stack)
    if l:size > self['_max_size']
        let self['_data'] = l:stack[l:size / 2 : ]
    endif
endfunction
