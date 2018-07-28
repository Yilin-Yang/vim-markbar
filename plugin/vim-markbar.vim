if exists('g:vim_markbar_autoloaded')
    finish
endif
let g:vim_markbar_autoloaded = 1

"==============================================================================
" GLOBAL VARIABLES: ==========================================================
"==============================================================================

" BRIEF:    Association between buffer numbers and their local mark databases.
" DETAILS:  The buffer with number '0' holds 'global' marks, such as file marks.
let g:buffersToDatabases = { markbar#constants#GLOBAL_MARKS() : [] }

" BRIEF:    Association between buffer numbers and mark-to-context dictionaries.
" DETAILS:  The buffer with number '0' holds 'global' marks, such as file marks.
let g:buffersToContexts = { markbar#constants#GLOBAL_MARKS() : {} }

"==============================================================================
" FUNCTIONS: =================================================================
"==============================================================================




"==============================================================================
" AUTOCMDS: ==================================================================
"==============================================================================

" TODO: only trigger when performing actions that affect lines with marks
" TODO: does `x` from visual mode trigger TextChanged?
" augroup vim_markbar_database_populators
"     au!
"     autocmd BufEnter,TextYankPost,TextChanged,TextChangedI
"         \ *
"         \ g:PopulateBufferDatabase() | g:PopulateGlobalDatabase()
" augroup end
