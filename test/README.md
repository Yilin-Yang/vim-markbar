vim-markbar Tests
================================================================================

Tests are written using [vader.vim](https://github.com/junegunn/vader.vim) and
are run with the [`run_tests.sh`](./run_tests.sh) script. This script can only
be run from this `test` directory.

See `./run_tests --help` for options.

Some common test workflows are given below:

```bash
# from project root,
cd test
./run_tests.sh           # to run test cases in vim
./run_tests.sh --neovim  # to run test cases in neovim

# run all tests in a non-headless, visible vim instance
./run_tests.sh -v

# ditto, but in neovim
./run_tests.sh -v --neovim

# run all tests in English, and again in an international locale
./run_tests.sh --international

# run a specific test in a visible vim instance
./run_tests.sh -v -f test-MarkbarModel.vader

# run a set of sequential standalone tests
./run_tests.sh -v -f standalone-test-sequential-name-persistence.vader

# To run test cases in a visible, non-headless neovim instance,
# using /usr/local/bin/nvim as the nvim executable,
# *Note* that run_tests.sh doesn't know if a vim/nvim executable is passed
# as the --vim_exe, so you still need to omit/specify --neovim.
./run_tests.sh --neovim -v --vim_exe=/usr/local/bin/nvim
```

Test Organization
--------------------------------------------------------------------------------
By default, vader.vim doesn't isolate tests from each other: global variables
set in one test will persist when other tests are run. See [vader.vim #101](https://github.com/junegunn/vader.vim/issues/101).

For this reason, we maintain three kinds of tests: "regular" tests, standalone
tests, and standalone sequential tests.

"Regular" tests are named like `test-specificthing.vader` or
`test-ClassName.vader`. When running all tests (by omitting `-f` arguments to
`run_tests.sh`), "regular" tests are globbed together and run in a single (n)vim
instance.

Standalone tests are named like `standalone-test-specificthing.vader`.
`run_tests.sh` always runs each of these tests in a new (n)vim instance. Exiting
and restarting (n)vim between tests ensures that these tests are isolated from
each other. Roughly speaking, standalone tests are tests that manipulate vim or
vim-markbar settings.

Standalone sequential tests are tests that require a viminfo/shada file. Regular
and standalone tests pass `-i NONE` to (n)vim, to prevent viminfo/shada from
affecting test execution. Some of vim-markbar's features rely on viminfo/shada,
like persistent user-given mark names, and these can't be tested without
a viminfo/shada file.

Standalone sequential tests are kept in subdirectories named like
`standalone-test-sequential-something.vader`, and are named like
`XX-standalone-test-sequential-something.vader` within that subdirectory, where
`XX` is a number (with leading 0, if applicable). Standalone sequential tests in
a subdirectory are each run in separate (n)vim instances, one after the other in
ascending numerical order, and share the same initially empty viminfo/shada file
with each other.

Other Notes
--------------------------------------------------------------------------------
vader.vim is sensitive to trailing whitespace in its `Expect:` blocks, where
they denote an empty line in the buffer. Some tests (particularly
[standalone-test-openmarkbar.vader](./standalone-test-openmarkbar.vader)
and [standalone-test-peekaboo.vader](./standalone-test-peekaboo.vader)) rely on
this behavior. If you use vim autocommands to automatically delete trailing
whitespace on buffer write, then you should disable those autocommands when
editing vader files.
