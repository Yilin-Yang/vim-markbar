scriptencoding utf-8
" Vim syntax file
" Language: markbar
" Maintainer: Yilin Yang

if exists('b:current_syntax')
    finish
endif

"===============================================================================

syn region markbarComment start=/^"/ end=/$/

"-------------------------------------------------------------------------------

" keepend, to avoid eating into markbarContext
syn region markbarSectionHeader
    \ start=/\m^\['.\]:/ end=/\m$/
    \ keepend contains=@markbarSectionHeaderElements

syn match markbarSectionBrackets /\%\(^\[\)\|\%\(\]:\)/ contained
syn match markbarSectionLowercaseMark /'[a-z]/ contained
syn match markbarSectionSpecialLocalMark /'[\[\]<>\.\^'"(){}]/ contained
syn match markbarSectionNumberedMark /'[0-9]/ contained
syn match markbarSectionUppercaseMark /'[A-Z]/ contained
syn match markbarSectionName /\s.\+$/ contained

syn cluster markbarSectionHeaderElements
    \ contains=markbarSectionBrackets,
             \ markbarSectionLowercaseMark,
             \ markbarSectionSpecialLocalMark,
             \ markbarSectionNumberedMark,
             \ markbarSectionUppercaseMark,
             \ markbarSectionName

"-------------------------------------------------------------------------------

syn region markbarContext
    \ start="^\s" end="^\["me=s-1
    \ fold keepend contains=@markbarContextElements

syn match markbarContextEndOfBuffer /\M~/ contained
syn match markbarContextMarkHighlightMarker /➜/ contained conceal
execute 'syn match markbarContextMarkHighlight /'
    \ . markbar#settings#MarkMarker()
    \ . './ contained contains=markbarContextMarkHighlightMarker'

syn cluster markbarContextElements
    \ contains=markbarContextEndOfBuffer,
             \ markbarContextMarkHighlight

"===============================================================================

hi default link markbarComment                 Comment

hi default link markbarSectionBrackets         Type
hi default link markbarSectionLowercaseMark    Type
hi default link markbarSectionSpecialLocalMark Type
hi default link markbarSectionNumberedMark     Special
hi default link markbarSectionUppercaseMark    Underlined
hi default link markbarSectionName             Title

hi default link markbarContext                 NormalNC
hi default link markbarContextEndOfBuffer      EndOfBuffer
hi default link markbarContextMarkHighlight    TermCursor

let b:current_syntax = 'markbar'
