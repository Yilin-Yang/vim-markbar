if exists('g:vim_markbar_autoloaded')
    finish
endif
let g:vim_markbar_autoloaded = 1

" BRIEF:    The entire vim-markbar state, not including user settings.
let g:markbar_model = markbar#MarkbarModel#get()
let g:markbar_view  = markbar#MarkbarView#new(g:markbar_model)
let g:standard_controller =
    \ markbar#StandardMarkbarController#new(g:markbar_model, g:markbar_view)

noremap <silent> <Plug>OpenMarkbar      :call g:standard_controller.openMarkbar()<cr>
noremap <silent> <Plug>CloseMarkbar     :call g:standard_controller.closeMarkbar()<cr>
noremap <silent> <Plug>ToggleMarkbar    :call g:standard_controller.toggleMarkbar()<cr>

augroup vim_markbar_buffer_updates
    au!
    autocmd BufEnter * call markbar#ui#SetEchoHeaderAutocmds()
augroup end
