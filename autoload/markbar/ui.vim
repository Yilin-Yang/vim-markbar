" EFFECTS:  Set an autocommand to print the current mark heading, or disable
"           the same if the current buffer is not a markbar buffer.
function! markbar#ui#SetEchoHeaderAutocmds() abort
    if getbufvar(bufnr('%'), 'is_markbar')
        augroup vim_markbar_echo_header
            au!
            autocmd CursorHold,CursorMoved *
                \ echo getline(g:markbar_view._getCurrentMarkHeadingLine())
        augroup end
    else
        augroup vim_markbar_echo_header
            au!
        augroup end
    endif
endfunction

" EFFECTS:  Sets autocommands to refresh the contents of any open markbars,
"           using the given markbar controller.
" PARAM:    controller (markbar#MarkbarController)
"                                           The MarkbarController responsible
"                                           for repopulating the markbar.
function! markbar#ui#SetRefreshMarkbarAutocmds(controller) abort
    augroup vim_markbar_refresh
        au!
        autocmd BufEnter,TextChanged,CursorHold,FileChangedShellPost
            \ * call markbar#ui#RefreshMarkbar(a:controller)
    augroup end
endfunction

" EFFECTS:  Refresh the contents of any open markbars, if the active window is
"           a 'real' window.
function! markbar#ui#RefreshMarkbar(controller) abort
    if !markbar#helpers#IsRealBuffer(bufnr('%')) | return | endif
    if g:markbar_view.markbarIsOpenCurrentTab()
        call markbar#MarkbarController#AssertIsMarkbarController(a:controller)
        let l:cur_winnr = winnr()
        call a:controller.openMarkbar()
        execute l:cur_winnr . 'wincmd w'
    endif
endfunction
