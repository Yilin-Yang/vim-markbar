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
noremap <silent> <Plug>CloseMarkbar     :call g:standard_controller.closeMarkbar(1)<cr>
noremap <silent> <Plug>ToggleMarkbar    :call g:standard_controller.toggleMarkbar(1)<cr>

if markbar#settings#EnablePeekabooMarkbar()
    let g:peekaboo_controller =
        \ markbar#PeekabooMarkbarController#new(g:markbar_model, g:markbar_view)
    noremap <silent> <Plug>OpenMarkbarPeekabooApostrophe    :call g:peekaboo_controller.apostrophe()<cr>
    noremap <silent> <Plug>OpenMarkbarPeekabooBacktick      :call g:peekaboo_controller.backtick()<cr>

    if markbar#settings#SetDefaultPeekabooMappings()
        execute 'nmap <silent> '.markbar#settings#PeekabooApostropheMapping()
            \ .' <Plug>OpenMarkbarPeekabooApostrophe'
        execute 'nmap <silent> '.markbar#settings#PeekabooBacktickMapping()
            \ .' <Plug>OpenMarkbarPeekabooBacktick'
    endif
endif

if markbar#settings#ExplicitlyRemapMarkMappings()
    " explicitly map 'a, 'b, 'c, etc. to `normal! 'a` (etc.), to avoid
    " unnecessarily opening the peekaboo bar for quick jumps

    function! s:MarkbarGoToMark(key, modifiers, prefix) abort
        execute 'normal! ' . a:prefix . a:key
    endfunction

    let g:markbar_apostrophe_remapper = markbar#KeyMapper#newWithUniformModifiers(
        \ markbar#constants#ALL_MARKS_STRING(),
        \ '',
        \ "'",
        \ function('<SID>MarkbarGoToMark')
    \ )
    call g:markbar_apostrophe_remapper.setMappings('noremap <silent>')

    let g:markbar_backtick_remapper = markbar#KeyMapper#newWithUniformModifiers(
        \ markbar#constants#ALL_MARKS_STRING(),
        \ '',
        \ '`',
        \ function('<SID>MarkbarGoToMark')
    \ )
    call g:markbar_backtick_remapper.setMappings('noremap <silent>')
endif

augroup vim_markbar_buffer_updates
    au!
    autocmd BufEnter * call markbar#ui#SetEchoHeaderAutocmds()
augroup end
