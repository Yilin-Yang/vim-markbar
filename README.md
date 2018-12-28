[![Build Status](https://travis-ci.com/Yilin-Yang/vim-markbar.svg?branch=master)](https://travis-ci.com/Yilin-Yang/vim-markbar)

vim-markbar
================================================================================
Open a sidebar that shows you every mark that you can access from your current
buffer, as well as the contexts in which those marks appear. Now with "peekaboo"
support!

Features
--------------------------------------------------------------------------------

### Demo
![markbar](https://user-images.githubusercontent.com/23268616/47609602-2fbc4680-da10-11e8-9789-1ab6575d22d6.gif)

[(asciinema Link)](https://asciinema.org/a/JY4F2AHb0PSBMINOQg6APFNa0)

### List

- **Remember** why you set those marks in the first place by looking at their context!
- **Jump to marks** directly from the markbar.
- **Open automatically on `` ` `` or `'`,** _à la_ [vim-peekaboo!](https://github.com/junegunn/vim-peekaboo)
- **Assign names** to your marks, directly or automatically!
- **Heavily customizable!** See below for details.

Requirements
--------------------------------------------------------------------------------
vim-markbar requires either:
- **vim 8.1**, at least up through [patch 8.1.0039.](https://github.com/vim/vim/commit/d79a26219d7161e9211fd144f0e874aa5f6d251e)
- **neovim 0.1.6** or newer.

neovim 0.1.6 was released in November of 2016, so if you use neovim at all,
you're almost certainly fine. As of the time of writing, vim 8.1 is new _enough_
that it isn't readily available through the default apt repositories for
Ubuntu 16.04. You may need to install it by [adding an apt repository,](https://launchpad.net/~jonathonf/+archive/ubuntu/vim)
or simply compile it from [source.](https://github.com/vim/vim)

Installation
--------------------------------------------------------------------------------
With [vim-plug,](https://github.com/junegunn/vim-plug)

```vim
" .vimrc
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
" .vimrc
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
nmap <Leader>m <Plug>ToggleMarkbar

" the following are unneeded if ToggleMarkbar is mapped
nmap <Leader>mo <Plug>OpenMarkbar
nmap <Leader>mc <Plug>CloseMarkbar
```

These examples use the [leader key,](https://stackoverflow.com/questions/1764263/what-is-the-leader-in-a-vimrc-file)
but you can use any mapping that you prefer. **Note the use of `map` instead of
`noremap`:** by definition, `noremap` mappings cannot trigger other mappings
and won't work with the functions given above.

You can manipulate marks in the markbar by moving your cursor over the mark or
its context and then activating a keymapping.

By default, you:

- **Jump to marks** using `<Enter>`,
- **Move the cursor to the next mark in the markbar** using `n`,
- **Move the cursor to the previous mark in the markbar** using `N`,
- **Rename marks** using `r`,
- **Clear the name of a mark** using `c`,
- **Delete marks entirely** using `d`.

These bindings only activate while you have a markbar window focused, so they
shouldn't conflict with your other mappings. Note that the mappings for moving
between marks in the markbar do shadow vim's "repeat last search" mappings: if
you plan to frequently `/` or `?` from inside the markbar, you may wish to
change this behavior.

A few examples of how to remap these bindings are given below:

```vim
" g, t to 'go to' a mark
let g:markbar_jump_to_mark_mapping = 'gt'

" Ctrl-r, d to rename a mark
let g:markbar_rename_mark_mapping = '<C-r>d'

" Backspace to clear a mark's name
let g:markbar_reset_mark_mapping = '<BS>'
```

### The "Peekaboo" Markbar
The "peekaboo" markbar is meant to be used in the same fashion as vim's
built-in "jump to mark" functionality: to jump to a mark, the user
only needs to press `'` or `` ` ``, and then the key corresponding to their
target mark, e.g. `'a` to jump to mark `a`.

By default, pressing the apostrophe key (`'`) or the backtick key (`` ` ``)
opens the peekaboo markbar with apostrophe-like or backtick-like behavior,
respectively. "Apostrophe-like" behavior moves the cursor to "the first
non-blank character in the line of the specified location" (see `:help
mark-motions`), while "backtick-like" behavior moves the cursor to the exact
line and column of the mark. See `:help 'a` for details.

If opened by accident, the peekaboo markbar can be closed by pressing `Escape`.

#### Navigating the Peekaboo Markbar
You can scroll the peekaboo markbar using standard vim keymappings, provided
that they don't collide with markbar mappings (e.g. `Ctrl-D` will scroll down
as expected, but `j` will jump to the mark `j`).

There also exist mappings to **select a mark,** i.e. move the cursor to
a particular mark's location in the markbar. By default, this is done by
prefixing the target mark with the `<leader>` key, e.g. `'<leader>a` to open
the peekaboo markbar and _select_ mark `a`, rather than `'a` to open it and
_jump to_ mark `a`.

By default, you can **jump to the selected mark** by pressing the `Enter` key.

Customization
--------------------------------------------------------------------------------

### Common Options
These are a few of the options that you're most likely to change. For full
documentation on options (what they are, their default values, and what they
do), see `:help vim-markbar-options`.

```vim
" for example
" only display alphabetic marks a-i and A-I
let g:markbar_marks_to_display = 'abcdefghiABCDEFGHI'

" width of a vertical split markbar
let g:markbar_width = 30

" indentation for lines of context
let g:markbar_context_indent_block = '  '

" number of lines of context to retrieve per mark
let g:markbar_num_lines_context = 3

" markbar-local mappings
let g:markbar_jump_to_mark_mapping  = 'G'
let g:markbar_next_mark_mapping     = '/'
let g:markbar_previous_mark_mapping = '?'
let g:markbar_rename_mark_mapping   = '<F2>'
let g:markbar_reset_mark_mapping    = 'r'
let g:markbar_delete_mark_mapping   = '<Del>'

" open/close markbar mappings
nmap <Leader>m  <Plug>ToggleMarkbar
nmap <Leader>mo <Plug>OpenMarkbar
nmap <Leader>mc <Plug>CloseMarkbar
```

### Peekaboo Customization

The peekaboo markbar has its own equivalents for most of the standard markbar's
customization options, e.g. `g:markbar_section_separation <-->
g:markbar_peekaboo_section_separation`. See `:help vim-markbar-options` for
details.

If you want to use the peekaboo markbar without shadowing vim's built-in "jump
to marks" functionality, you can set the following options:

```vim
" open an 'apostrophe-like' peekaboo markbar with <Leader>a
let g:markbar_peekaboo_apostrophe_mapping = '<leader>a'

" open a 'backtick-like' peekaboo markbar with <Leader>b
let g:markbar_peekaboo_backtick_mapping = '<leader>b'
```

Alternatively, if you want to set your own explicit mappings, you can set the
following options:

```vim
" leave peekaboo markbar enabled, but don't set default mappings
let g:markbar_set_default_peekaboo_mappings = v:false

nmap <leader>a <Plug>OpenMarkbarPeekabooApostrophe
nmap <leader>b <Plug>OpenMarkbarPeekabooBacktick
```

#### "Select" and "Jump To" Mappings
The plugin sets buffer-local "select" and "jump to" mappings for every possible
mark on entering the peekaboo markbar. These mappings can be customized by
setting a **prefix** (e.g. `<leader>` for "select" mappings) or by setting
**modifiers** (e.g. `Control`, `Shift`, `Meta`).

The use of modifiers is not recommended. vim's built-in support for modifiers
can be flaky at the best of times, and attempting to set multiple modifiers may
lead to undefined behavior.

For example, you can set the following:

```vim
" select a mark by pressing backslash, and then the target mark
let g:markbar_peekaboo_select_prefix = '\'

" OR, select mark 'a' just by tapping the 'a' key
" NOTE: you'll have to change the 'jump_to_mark' mappings accordingly
let g:markbar_peekaboo_select_prefix = ''

" jump to mark 'a' by pressing Ctrl-Shift-Alt-a
" NOTE: this probably won't work in practice
let g:markbar_peekaboo_jump_to_mark_modifiers = 'control,shift,alt'
```

#### Known Issues
As of the time of writing, the peekaboo markbar isn't fully compatible with
operator-pending mode, visual mode, or select mode. For instance, setting `vmap
' <Plug>OpenMarkbarPeekabooApostrophe` will allow you to _open_ the
peekaboo markbar from visual mode, but doing so will cancel your visual selection.
For this reason, the peekaboo markbar only opens from normal mode by default.

If you don't want to open the peekaboo markbar for quick jumps (e.g.
double-tapping `'` to go to "position before last jump"), then see
`:help g:markbar_explicitly_remap_mark_mappings`. Setting this option to
`v:true` will let you "short-circuit" the peekaboo markbar if you already know
which mark to jump to.

If you want to disable the peekaboo markbar entirely, you can set
`g:markbar_enable_peekaboo` to `v:false`.

### Default Mark Name Customization
Marks that have not been explicitly named by the user will show "default" names
in the markbar. By default, this consists of basic information about the mark,
e.g. the file in which it resides, its line number, and its column number. If
you'd like, you can customize how vim-markbar constructs these default names.

The default name for a file mark is controlled by the options:
```vim
let g:markbar_file_mark_format_string = '%s [l: %4d, c: %4d]'
let g:markbar_file_mark_arguments = ['fname', 'line', 'col']
```

Which will produce a default name that looks like:
```vim
['A]: test/30lines.txt [l:   10, c:    0]
"     ^ 'fname'              ^ 'line'  ^ 'col'
```

You might decide to swap the line and column number, and also display them more
compactly, like so:

```vim
['A]: test/30lines.txt (0, 10)
"                 'col' ^  ^ 'line'
```

You can achieve this by setting the following options:
```vim
let g:markbar_file_mark_format_string = '%s (%d, %d)'
let g:markbar_file_mark_arguments = ['fname', 'col', 'line'] " note the swapped 'col' and 'line'
```

See `:help printf` and `:help g:markbar_mark_name_format_string` for more details.

#### Naming Marks with User-Provided Functions
If you would like additional flexibility, you can provide vim-markbar with a
reference to a "mark naming" function that you've written yourself. vim-markbar
will call this function when "default naming" marks, providing information
about the mark as arguments and taking a string (the name of the mark) as a
return value.

See `:help vim-markbar-function-references` for more details.

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
|`markbarContextMarkHighlight`    | `TermCursor`            | Highlighting used to show a mark's location in its context.

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
