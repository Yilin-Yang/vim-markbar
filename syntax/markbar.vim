" Vim syntax file
" Language: markbar
" Maintainer: Yilin Yang
" Latest Revision: 3 August 2018

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

syn match markbarSectionBrackets /[\[\]:]/ contained
syn match markbarSectionLowercaseMark /'[a-z]/ contained
syn match markbarSectionSpecialLocalMark /'[a-z<>'"^.(){}]/ contained
syn match markbarSectionNumberedMark /'[0-9]/ contained
syn match markbarSectionUppercaseMark /'[A-Z]/ contained
syn match markbarSectionName /\s.\+$/ contained

syn cluster markbarSectionHeaderElements
    \ contains=markbarSectionBrackets,
             \ markbarSectionLowercaseMark,
             \ markbarSectionNumberedMark,
             \ markbarSectionUppercaseMark,
             \ markbarSectionName

"-------------------------------------------------------------------------------

syn region markbarContext
    \ start="^\s" end="^\["me=s-1
    \ fold keepend contains=@markbarContextElements

syn match markbarContextEndOfBuffer /\M~/ contained

syn cluster markbarContextElements contains=markbarContextEndOfBuffer

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

let b:current_syntax = 'markbar'
