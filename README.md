[![Build Status](https://travis-ci.com/Yilin-Yang/vim-markbar.svg?branch=master)](https://travis-ci.com/Yilin-Yang/vim-markbar)

vim-markbar (BETA)
================================================================================
Open a sidebar that shows you every mark that you can access from your current
buffer, as well as the contexts in which those marks appear.

Features
--------------------------------------------------------------------------------

<!-- ### Demo -->
<!-- TODO -->

### List

- **Remember** why you set those marks in the first place by looking at their context!
- **Jump to marks** directly from the markbar.
- **Assign names** to your marks, directly or automatically!
- **Heavily customizable!** See below for details.

Installation
--------------------------------------------------------------------------------
With [vim-plug,](https://github.com/junegunn/vim-plug)

```vim
# .vimrc
call plug#begin('~/.vim/bundle')
" ...
Plug 'Yilin-Yang/vim-markbar'
" ...
call plug#end()
```
And then run `:PlugInstall`.

---

With [Vundle,](https://github.com/VundleVim/Vundle.vim)

```vim
# .vimrc
call vundle#begin()
" ...
Plugin 'Yilin-Yang/vim-markbar'
" ...
call vundle#end()
```
And then run `:PluginInstall`.

---

With [pathogen,](https://github.com/tpope/vim-pathogen)

```bash
cd ~/.vim/bundle
git clone https://github.com/Yilin-Yang/vim-markbar.git
```

Quick Start
--------------------------------------------------------------------------------
At a minimum, you should set some of the following keymappings in your `.vimrc`.

```vim
map <Leader>m <Plug>ToggleMarkbar

" the following are unneeded if ToggleMarkbar is mapped
map <Leader>mo <Plug>OpenMarkbar
map <Leader>mc <Plug>CloseMarkbar
```

These examples use the [leader key,](https://stackoverflow.com/questions/1764263/what-is-the-leader-in-a-vimrc-file)
but you can use any mapping that you prefer. **Note the use of `map` instead of
`noremap`:** `noremap` mappings, by definition, cannot trigger other mappings
and won't work with the functions given above.

You can manipulate marks in the markbar by moving your cursor over the mark or
its context and then activating a keymapping. By default, you **jump to marks**
using `<Enter>`, **rename marks** using `r`, and **clear the name of a mark**
using `c`. These bindings only activate while you have a markbar window
focused, so they shouldn't conflict with your other mappings.

A few examples of how to remap these bindings are given below:

```vim
" g, t to 'go to' a mark
let g:markbar_jump_to_mark_mapping = 'gt'

" Ctrl-r, d to rename a mark
let g:markbar_rename_mark_mapping = '<C-r>d'

" Backspace to clear a mark's name
let g:markbar_reset_mark_mapping = '<BS>'
```

Customization
--------------------------------------------------------------------------------
For full documentation on options (what they are, their default values, and
what they do), see `:help markbar`.

### Common Options

| Setting Name                               | Type     | Default Value                       |
|:-------------------------------------------|:--------:|:------------------------------------|
| `g:markbar_marks_to_display`               | `string` | `'abc...xyzABC...XYZ012...789'`     |
| `g:markbar_open_vertical`                  | `bool  ` | `v:true`                            |
| `g:markbar_width`                          | `number` | 30                                  |
| `g:markbar_height`                         | `number` | 30                                  |
| `g:markbar_close_after_go_to`              | `bool  ` | `v:true`                            |
| `g:markbar_open_position`                  | `string` | `'botright'`                        |
| `g:markbar_buffer_name`                    | `string` | `'[ Markbar ]'`                     |
| `g:markbar_context_indent_block`           | `string` | `    ` (four spaces)                |
| `g:markbar_section_separation`             | `number` | `1`                                 |
| `g:markbar_ignore_buffer_criteria`         | `dict  ` | `['unload', 'delete', 'wipe']`      |
| `g:markbar_maximum_active_buffer_history`  | `number` | `100`                               |
| `g:markbar_num_lines_context`              | `number` | `5`                                 |
| `g:markbar_jump_to_mark_mapping`           | `string` | `<cr>` (Enter)                      |
| `g:markbar_rename_mark_mapping`            | `string` | `r`                                 |
| `g:markbar_reset_mark_mapping`             | `string` | `c`                                 |
| `g:markbar_jump_to_exact_position`         | `bool  ` | `v:true`                            |
| `g:markbar_rename_mark_completion`         | `string` | `file_in_path`                      |
| `g:markbar_mark_name_format_string`        | `string` | `'l: %4d, c: %4d'`                  |
| `g:markbar_mark_name_arguments`            | `list  ` | `['line', 'col']`                   |
| `g:markbar_file_mark_format_string`        | `string` | `%s [l: %4d, c: %4d]`               |
| `g:markbar_file_mark_arguments`            | `list  ` | `['fname', 'line', 'col']`          |
| `g:markbar_numbered_mark_format_string`    | `string` | `g:markbar_file_mark_format_string` |
| `g:markbar_numbered_mark_arguments`        | `list  ` | `g:markbar_file_mark_arguments`     |

### Highlight Groups
vim-markbar defines its own syntax file that it uses inside markbar buffers.
This syntax file defines the following highlight groups, which you can
customize to your liking.

| Highlight Group                 | Default Value (Linkage) | Description                           |
|:--------------------------------|:-----------------------:|:--------------------------------------|
|`markbarComment`                 | `Comment`               | Lines that start with `"`.            |
|`markbarSectionBrackets`         | `Type`                  | The square brackets in, e.g. `['A]`.  |
|`markbarSectionLowercaseMark`    | `Type`                  | The quote and letter in, e.g. `['a]`. |
|`markbarSectionSpecialLocalMark` | `Type`                  | The quote and symbol in, e.g. `['^]`. |
|`markbarSectionNumberedMark`     | `Special`               | The quote and number in, e.g. `['5]`. |
|`markbarSectionUppercaseMark`    | `Underlined`            | The quote and letter in, e.g. `['A]`. |
|`markbarSectionName`             | `Title`                 | The text following the colon in, e.g. `['A]:    Section Name Here`
|`markbarContext`                 | `NormalNC`              | The lines below the section headings, plucked from around the mark's actual location.
|`markbarContextEndOfBuffer`      | `EndOfBuffer`           | The `~` character that appears when a mark's context is cut off by the top  or bottom of its parent file.

These can be customized by linking them to other preexisting highlight groups
(as is done by default), or by explicitly defining a colorscheme for the
highlight group to use.

```vim
" 'reusing' an existing highlight group
hi link markbarContext String

" explicitly defining which colors to use, see `:h highlight-args` for details
hi markbarSectionNumberedMark cterm=bold ctermfg=green gui=bold guifg=green
```

Contribution
--------------------------------------------------------------------------------
If you encounter bugs while using vim-markbar, or if you think of features that
you would like to see in later versions, please feel free to report them on the
repository's [issues page.](https://github.com/Yilin-Yang/vim-markbar/issues)

If you'd like to try your hand at patching bugs or writing features yourself,
you're also free to fork the repository and to submit pull requests. If you do,
make sure that your code passes the existing [vader.vim](https://github.com/junegunn/vader.vim)
test suite, and make sure to write new tests as is appropriate.

To run test cases:

```bash
# from project root,
cd test
./run_tests_vim.sh   # to run test cases in vim
./run_tests_nvim.sh  # to run test cases in neovim
```

If you're fixing a bug, try to replicate the bug (using the old, "broken" code)
in a test case. If you're adding a new feature, try to write unit tests for the
new feature. This will make it much easier for me to maintain the code that you
submit, and it should make your life much easier as well.

License
--------------------------------------------------------------------------------
MIT
