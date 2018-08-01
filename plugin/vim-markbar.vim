if exists('g:vim_markbar_autoloaded')
    finish
endif
let g:vim_markbar_autoloaded = 1

"==============================================================================
" GLOBAL VARIABLES: ==========================================================
"==============================================================================

" BRIEF:    Association between buffer numbers and their local mark databases.
" DETAILS:  The buffer with number '0' holds 'global' marks, such as file marks.
"
"           Individual 'values' (the elements retrieved from key-based
"           lookup, e.g. by `g:buffersToMarks[1]`) are 'second-level'
"           dictionaries from `v:t_string` to a 2D `v:t_list`. Each dictionary
"           represents cached data about the marks for one specific buffer
"           (not counting the 'global' marks list with `key: 0`),
"
"           Indexing into a 'second-level' dictionary returns a list. For
"           instance, `g:buffersToMarks[3]['a']` returns a list for mark 'a'
"           in the buffer with associated `bufno()` `3`.
"
"           Each element in this list is one of that mark's fields, in the
"           following order (by index):
"               0.  the mark itself (same as the key associated with this list)
"               1.  the mark's line number
"               2.  the mark's column number
"               3.  the mark's 'file/text'
let g:buffersToMarks = { markbar#constants#GLOBAL_MARKS() : [] }

" BRIEF:    Association between buffer numbers and mark-to-context dictionaries.
" DETAILS:  The buffer with number '0' holds 'global' marks, such as file marks.
"
"           Individual 'values' (the elements retrieved from key-based
"           lookup, e.g. by `g:buffersToMarksToContexts[1]`) are dictionaries.
"           Each dictionary stores the marks, and the contexts in which those
"           marks appear, for one specific buffer (not counting the 'global'
"           marks context dictionary with `key: 0`.)
"
"           One can index into these dictionaries as follows:
"           - Keys are marks, i.e. strings of length 1.
"           `g:buffersToMarksToContexts[5]['d']` returns the contexts for mark
"           `'d` in buffer number 5.
"
"           - Values are 'contexts', stored as lists of strings. The string at
"           index `len(l:context_list) / 2` (with integer division, i.e.
"           rounding down) is the precise line on which the mark appears.
"
let g:buffersToMarksToContexts = { markbar#constants#GLOBAL_MARKS() : {} }

" BRIEF:    Association between buffer numbers and those of their markbars.
let g:buffersToMarkbars = {}

" BRIEF:    Record of the 'real buffers' most recently accessed by the user.
" DETAILS:  Maintained so that functions can figure out the 'active buffer',
"           even when `bufnr('%')` returns the buffer number of a markbar
"           buffer. (`markbar#helpers#IsRealBuffer()`, by itself, isn't
"           sufficient, since a new markbar buffer will register as a 'real'
"           buffer immediately after its creation.)
let g:activeBufferStack = [1]

"==============================================================================
" FUNCTIONS: =================================================================
"==============================================================================



"==============================================================================
" AUTOCMDS: ==================================================================
"==============================================================================

augroup vim_markbar_buffer_updates
    au!
    autocmd BufEnter * call markbar#state#PushNewActiveBuffer()
augroup end

" TODO: only trigger when performing actions that affect lines with marks
" TODO: does `x` from visual mode trigger TextChanged?
" augroup vim_markbar_database_populators
"     au!
"     autocmd BufEnter,TextYankPost,TextChanged,TextChangedI
"         \ *
"         \ g:PopulateBufferDatabase() | g:PopulateGlobalDatabase()
" augroup end
