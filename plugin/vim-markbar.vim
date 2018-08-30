if exists('g:vim_markbar_autoloaded')
    finish
endif
let g:vim_markbar_autoloaded = 1

" BRIEF:    The entire vim-markbar state, not including user settings.
let g:markbar_buffers = markbar#MarkbarState#new()

" BRIEF:    Whether or not to display the verbose quick-help at the top of the
"           markbar.
let g:markbar_show_verbose_help = v:false

noremap <silent> <Plug>OpenMarkbar      :call markbar#ui#OpenMarkbar()<cr>
noremap <silent> <Plug>CloseMarkbar     :call markbar#ui#CloseMarkbar()<cr>
noremap <silent> <Plug>ToggleMarkbar    :call markbar#ui#ToggleMarkbar()<cr>

augroup vim_markbar_buffer_updates
    au!
    autocmd BufEnter * call g:markbar_buffers.pushNewBuffer(expand('<abuf>') + 0)
    autocmd BufEnter * call markbar#ui#SetEchoHeaderAutocmds()
    autocmd BufEnter,TextChanged,CursorHold,FileChangedShellPost
        \ * call markbar#ui#RefreshMarkbar()
    autocmd BufDelete,BufWipeout *
        \ call g:markbar_buffers.evictBufferCache(expand('<abuf>') + 0)
augroup end
