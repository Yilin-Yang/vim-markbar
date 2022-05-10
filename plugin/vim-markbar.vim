if exists('g:vim_markbar_autoloaded')
    finish
endif
let g:vim_markbar_autoloaded = 1

function! s:StandardFormatOptions() abort
    let l:num_lines_context = markbar#settings#NumLinesContext()
    let l:num_lines_context_around_local = l:num_lines_context.around_local
    let l:num_lines_context_around_global = l:num_lines_context.around_file
    return {
        \ 'marks_to_display': markbar#settings#MarksToDisplay(),
        \ 'short_help_text': ['" Press ? for help'],
        \ 'verbose_help_text': [
            \ '" vim-markbar Keymappings',
            \ '" -----------------------',
            \ '" Press ? to close help' ,
            \ '" -----------------------',
            \ '" With the cursor over a mark or its context,',
            \ printf('" %s: jump to mark', markbar#settings#JumpToMarkMapping()),
            \ printf('" %s: move cursor to next mark', markbar#settings#NextMarkMapping()),
            \ printf('" %s: move cursor to previous mark', markbar#settings#PreviousMarkMapping()),
            \ printf('" %s: rename mark', markbar#settings#RenameMarkMapping()),
            \ printf('" %s: reset mark''s name', markbar#settings#ResetMarkMapping()),
            \ printf('" %s: delete mark', markbar#settings#DeleteMarkMapping()),
            \ '" -----------------------',
        \ ],
        \ 'show_verbose_help': v:false,
        \ 'num_lines_context_around_local': l:num_lines_context_around_local,
        \ 'num_lines_context_around_global': l:num_lines_context_around_global,
        \ 'section_separator': markbar#settings#MarkbarSectionSeparator(),
        \ 'indent_block': markbar#settings#ContextIndentBlock(),
        \ 'enable_mark_highlighting': markbar#settings#EnableMarkHighlighting(),
        \ 'mark_marker': markbar#settings#MarkMarker(),
        \ 'jump_like_backtick': markbar#settings#JumpToExactPosition(),
        \ 'local_mark_name_format_str': markbar#settings#MarkNameFormatString(),
        \ 'local_mark_name_arguments': markbar#settings#MarkNameArguments(),
        \ 'file_mark_name_format_str': markbar#settings#FileMarkFormatString(),
        \ 'file_mark_name_arguments': markbar#settings#FileMarkArguments(),
        \ 'numbered_mark_name_format_str': markbar#settings#NumberedMarkFormatString(),
        \ 'numbered_mark_name_arguments': markbar#settings#NumberedMarkArguments(),
    \ }
endfunction


let g:markbar_model = markbar#MarkbarModel#New()
let g:markbar_view  = markbar#MarkbarView#New(g:markbar_model)
let g:markbar_standard_format = markbar#MarkbarFormat#New(
        \ s:StandardFormatOptions())
let g:markbar_standard_controller =
        \ markbar#MarkbarController#New(g:markbar_model, g:markbar_view,
                                      \ g:markbar_standard_format)

if v:vim_did_enter
    " catching /Buffer not cached/ in MarkbarController.refreshContents()
    " might make this unnecessary, but it can't hurt
    call g:markbar_model.pushNewBuffer(markbar#helpers#GetOpenBuffers())
    call g:markbar_model.updateCurrentAndGlobal()
endif


function! s:OpenMarkbar() abort
    call g:markbar_standard_format.setOptions(s:StandardFormatOptions())
    call g:markbar_standard_controller.openMarkbar()
    call s:SetMarkbarMappings()
    call s:SetRefreshMarkbarAutocmds(g:markbar_standard_controller)
endfunction

function! s:CloseMarkbar() abort
    call g:markbar_standard_controller.closeMarkbar()
endfunction

function! s:ToggleMarkbar() abort
    if g:markbar_view.closeMarkbar()
        return
    endif
    call s:OpenMarkbar()
endfunction


noremap <silent> <Plug>OpenMarkbar      :call <SID>OpenMarkbar()<cr>
noremap <silent> <Plug>CloseMarkbar     :call <SID>CloseMarkbar()<cr>
noremap <silent> <Plug>ToggleMarkbar    :call <SID>ToggleMarkbar()<cr>

function! s:SetMarkbarMappings() abort
    mapclear <buffer>

    let b:ctrl  = g:markbar_standard_controller
    let b:fmt   = g:markbar_standard_format
    let b:view  = g:markbar_view
    let b:model = g:markbar_model
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#JumpToMarkMapping()
        \ . ' :call b:view.goToSelectedMark('
            \ . 'markbar#settings#JumpToExactPosition()'
        \ . ')<cr>'

    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#RenameMarkMapping()
        \ . ' :call b:model.renameMark(b:view.getCurrentMarkHeading())<cr>'
        \ . ' :call b:ctrl.refreshContents()<cr>'
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#ResetMarkMapping()
        \ . ' :call b:model.resetMark(b:view.getCurrentMarkHeading())<cr>'
        \ . ' :call b:ctrl.refreshContents()<cr>'
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#DeleteMarkMapping()
        \ . ' :call b:model.deleteMark(b:view.getCurrentMarkHeading())<cr>'
        \ . ' :call b:ctrl.refreshContents()<cr>'

    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#NextMarkMapping()
        \ . ' :<C-U>call b:view.cycleToNextMark(v:count1)<cr>'
    execute 'noremap <silent> <buffer> '
        \ . markbar#settings#PreviousMarkMapping()
        \ . ' :<C-U>call b:view.cycleToPreviousMark(v:count1)<cr>'

    execute 'noremap <silent> <buffer> ? '
        \ . ':call b:fmt.flipOption("show_verbose_help")<cr>'
        \ . ':call b:ctrl.refreshContents()<cr>'
endfunction

function! s:RefreshMarkbar(controller) abort
    if !markbar#helpers#IsRealBuffer(bufnr('%')) | return | endif
    if g:markbar_view.markbarIsOpenCurrentTab()
        call markbar#ensure#IsClass(a:controller, 'MarkbarController')
        let l:cur_winnr = winnr()
        call a:controller.refreshContents()
        execute l:cur_winnr . 'wincmd w'
    endif
endfunction

function! s:SetRefreshMarkbarAutocmds(controller) abort
    let g:markbar_active_controller = a:controller
    augroup markbar_refresh
        au!
        autocmd BufEnter,BufLeave,TextChanged,CursorHold,FileChangedShellPost
            \ * call s:RefreshMarkbar(g:markbar_active_controller)
    augroup end
endfunction


if markbar#settings#EnablePeekabooMarkbar()

    function! s:PeekabooFormatOptions(select_map, jump_to_map) abort
        call markbar#ensure#IsClass(a:select_map, 'KeyMapper')
        call markbar#ensure#IsClass(a:jump_to_map, 'KeyMapper')
        let l:select_map = a:select_map._keys_to_map[0]
        let l:select_lhs_map = l:select_map[0]
        let l:select_target = l:select_map[1][0]
        let l:jump_to_map = a:jump_to_map._keys_to_map[0]
        let l:jump_to_lhs_map = l:jump_to_map[0]
        let l:jump_to_target = l:jump_to_map[1][0]

        let l:num_lines_context = markbar#settings#NumLinesContext()
        let l:num_lines_context_around_local = l:num_lines_context.peekaboo_around_local
        let l:num_lines_context_around_global = l:num_lines_context.peekaboo_around_file
        return {
            \ 'marks_to_display': markbar#settings#PeekabooMarksToDisplay(),
            \ 'short_help_text': ['" Press ? for help'],
            \ 'verbose_help_text': [
                \ '" "Peekaboo" vim-markbar',
                \ '" -----------------------',
                \ '" Press ? to close help' ,
                \ '" -----------------------',
                \ '" <Esc>: close markbar',
                \ '" ' . l:select_lhs_map.': select ['''.l:select_target.'] in markbar',
                \ '" ' . markbar#settings#PeekabooJumpToMarkMapping()
                    \ . ': jump to selected mark',
                \ '" ' . l:jump_to_lhs_map.': jump directly to mark ['''
                    \ . l:jump_to_target . ']',
                \ '" -----------------------',
            \ ],
            \ 'show_verbose_help': v:false,
            \ 'num_lines_context_around_local': l:num_lines_context_around_local,
            \ 'num_lines_context_around_global': l:num_lines_context_around_global,
            \ 'section_separator': markbar#settings#PeekabooMarkbarSectionSeparator(),
            \ 'indent_block': markbar#settings#PeekabooContextIndentBlock(),
            \ 'enable_mark_highlighting': markbar#settings#EnableMarkHighlighting(),
            \ 'mark_marker': markbar#settings#MarkMarker(),
            \ 'jump_like_backtick': markbar#settings#BacktickBehaviorWithApostrophe(),
            \ 'local_mark_name_format_str': markbar#settings#PeekabooMarkNameFormatString(),
            \ 'local_mark_name_arguments': markbar#settings#PeekabooMarkNameArguments(),
            \ 'file_mark_name_format_str': markbar#settings#PeekabooFileMarkFormatString(),
            \ 'file_mark_name_arguments': markbar#settings#PeekabooFileMarkArguments(),
            \ 'numbered_mark_name_format_str': markbar#settings#PeekabooNumberedMarkFormatString(),
            \ 'numbered_mark_name_arguments': markbar#settings#PeekabooNumberedMarkArguments(),
        \ }
    endfunction

    let g:markbar_peekaboo_select_keys = markbar#KeyMapper#NewWithSameModsPrefixes(
        \ markbar#constants#ALL_MARKS_STRING(),
        \ markbar#settings#PeekabooSelectModifiers(),
        \ markbar#settings#PeekabooSelectPrefix(),
        \ v:null
    \ )

    let g:markbar_peekaboo_jump_to_keys = markbar#KeyMapper#NewWithSameModsPrefixes(
        \ markbar#constants#ALL_MARKS_STRING(),
        \ markbar#settings#PeekabooJumpToMarkModifiers(),
        \ markbar#settings#PeekabooJumpToMarkPrefix(),
        \ v:null
    \ )

    let g:markbar_peekaboo_format = markbar#MarkbarFormat#New(
            \ s:PeekabooFormatOptions(g:markbar_peekaboo_select_keys,
                                    \ g:markbar_peekaboo_jump_to_keys))
    let g:markbar_peekaboo_controller = markbar#MarkbarController#New(
            \ g:markbar_model, g:markbar_view, g:markbar_peekaboo_format)

    noremap <silent> <Plug>OpenMarkbarPeekabooApostrophe :call <SID>Apostrophe()<cr>
    noremap <silent> <Plug>OpenMarkbarPeekabooBacktick   :call <SID>Backtick()<cr>

    if markbar#settings#SetDefaultPeekabooMappings()
        execute 'nmap <silent> '.markbar#settings#PeekabooApostropheMapping()
            \ .' <Plug>OpenMarkbarPeekabooApostrophe'
        execute 'nmap <silent> '.markbar#settings#PeekabooBacktickMapping()
            \ .' <Plug>OpenMarkbarPeekabooBacktick'
    endif

    function! s:OpenPeekaboo(jump_like_backtick)
        let l:bufno = bufnr('%')
        let l:filters = markbar#settings#PeekabooInvocationFilters()
        for l:ShouldNotOpen in l:filters
            if l:ShouldNotOpen(l:bufno)
                return
            endif
        endfor
        call g:markbar_peekaboo_format.setOptions(
                \ s:PeekabooFormatOptions(g:markbar_peekaboo_select_keys,
                                        \ g:markbar_peekaboo_jump_to_keys))
        call g:markbar_peekaboo_format.setOption('jump_like_backtick',
                                               \ a:jump_like_backtick)
        call g:markbar_peekaboo_controller.openMarkbar()
        call s:SetPeekabooMarkbarMappings(a:jump_like_backtick)
        call s:SetRefreshMarkbarAutocmds(g:markbar_peekaboo_controller)
    endfunction

    function! s:Apostrophe() abort
        call s:OpenPeekaboo(markbar#settings#BacktickBehaviorWithApostrophe())
    endfunction

    function! s:Backtick() abort
        call s:OpenPeekaboo(v:true)
    endfunction


    function! s:SetPeekabooMarkbarMappings(jump_like_backtick) abort
        mapclear <buffer>

        let b:ctrl  = g:markbar_peekaboo_controller
        let b:fmt   = g:markbar_peekaboo_format
        let b:view  = g:markbar_view
        let b:model = g:markbar_model

        noremap <silent> <buffer> <Esc> :call b:ctrl.closeMarkbar()<cr>
        execute 'noremap <silent> <buffer> '
            \ . markbar#settings#PeekabooJumpToMarkMapping()
            \ . ' :call b:view.goToSelectedMark('
                \ . (a:jump_like_backtick ? 'v:true' : 'v:false')
            \ . ')<cr>'
        execute 'noremap <silent> <buffer> ? '
            \ . ':call b:fmt.flipOption("show_verbose_help")<cr>'
            \ . ':call b:ctrl.refreshContents()<cr>'

        call g:markbar_peekaboo_select_keys.setCallback(
            \ { key, mods, prefix -> b:view.selectMark(key) }
        \ )
        call g:markbar_peekaboo_jump_to_keys.setCallback(
            \ { key, mods, prefix -> b:view.goToMark(key, a:jump_like_backtick) }
        \ )

        call g:markbar_peekaboo_select_keys.setMappings(
                \ 'noremap <silent> <buffer>')
        call g:markbar_peekaboo_jump_to_keys.setMappings(
                \ 'noremap <silent> <buffer>')
    endfunction

endif


if markbar#settings#ExplicitlyRemapMarkMappings()
    " explicitly map 'a, 'b, 'c, etc. to `normal! 'a` (etc.), to avoid
    " unnecessarily opening the peekaboo bar for quick jumps

    function! s:MarkbarGoToMark(key, modifiers, prefix) abort
        execute 'normal! ' . a:prefix . a:key
    endfunction

    let g:markbar_apostrophe_remapper =
        \ markbar#KeyMapper#NewWithSameModsPrefixes(
            \ markbar#constants#ALL_MARKS_STRING(), '', "'",
            \ function('<SID>MarkbarGoToMark'))
    call g:markbar_apostrophe_remapper.setMappings('noremap <silent>')

    let g:markbar_backtick_remapper =
        \ markbar#KeyMapper#NewWithSameModsPrefixes(
            \ markbar#constants#ALL_MARKS_STRING(), '', '`',
            \ function('<SID>MarkbarGoToMark'))
    call g:markbar_backtick_remapper.setMappings('noremap <silent>')
endif

function! s:SetEchoHeaderAutocmds() abort
    if getbufvar(bufnr('%'), 'is_markbar')
        augroup markbar_echo_header
            au!
            autocmd CursorHold,CursorMoved *
                \ echo getline(g:markbar_view.getCurrentMarkHeadingLine())
        augroup end
    else
        augroup markbar_echo_header
            au!
        augroup end
    endif
endfunction

augroup markbar_buffer_updates
    au!
    autocmd BufEnter * call s:SetEchoHeaderAutocmds()
augroup end

augroup markbar_model_update
    au!
    autocmd VimEnter * call g:markbar_model.pushNewBuffer(markbar#helpers#GetOpenBuffers())
    autocmd BufEnter * call g:markbar_model.pushNewBuffer(expand('<abuf>') + 0)
    autocmd BufDelete,BufWipeout *
        \ call g:markbar_model.evictBufferCache(expand('<abuf>') + 0)
augroup end
