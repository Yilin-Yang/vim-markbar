if exists('g:vim_markbar_autoloaded')
    finish
endif
let g:vim_markbar_autoloaded = 1

" BRIEF:    The entire vim-markbar state, not including user settings.
let g:markbar_buffers = markbar#MarkbarBuffers#new()

"==============================================================================
" AUTOCMDS: ==================================================================
"==============================================================================

augroup vim_markbar_buffer_updates
    au!
    autocmd BufEnter * call g:markbar_buffers['pushNewBuffer()']()
    autocmd BufEnter *
        \ if g:markbar_buffers['markbarOpenCurrentTab()']()
            \ | call g:markbar_buffers['updateCurrentAndGlobal()']()
        \ | endif
augroup end

" TODO: only trigger when performing actions that affect lines with marks
" TODO: does `x` from visual mode trigger TextChanged?
" augroup vim_markbar_database_populators
"     au!
"     autocmd BufEnter,TextYankPost,TextChanged,TextChangedI
"         \ *
"         \ g:PopulateBufferDatabase() | g:PopulateGlobalDatabase()
" augroup end
