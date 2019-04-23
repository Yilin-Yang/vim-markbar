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

" EFFECTS:  Refresh the contents of any open markbars using the given
"           MarkbarController, if the active window is a 'real' window.
function! markbar#ui#RefreshMarkbar(controller) abort
    if !markbar#helpers#IsRealBuffer(bufnr('%')) | return | endif
    if g:markbar_view.markbarIsOpenCurrentTab()
        call markbar#MarkbarController#AssertIsMarkbarController(a:controller)
        let l:cur_winnr = winnr()
        call a:controller.refreshContents()
        execute l:cur_winnr . 'wincmd w'
    endif
endfunction
