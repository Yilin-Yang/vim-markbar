vim-markbar Tests
================================================================================

Tests are written using [vader.vim](https://github.com/junegunn/vader.vim) and
are run with the [`run_tests.sh`](./run_tests.sh) script. This script can only
be run from this `test` directory.

**To run, vader.vim needs to be in the test environment's `runtimepath`.**
You can achieve this by cloning vader.vim into the test directory.
```bash
# from project root,
git clone https://github.com/junegunn/vader.vim test/vader.vim
```

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

Dockerfile
--------------------------------------------------------------------------------
This directory includes a Dockerfile to build a Docker image that will compile
and include the oldest officially supported versions of vim and neovim.

### Pulling Docker image from DockerHub repository

After installing Docker, you can pull the prebuilt test image by running:

```bash
# this may be necessary for docker to find the yiliny/vim-markbar-tester image
docker login

docker pull yiliny/vim-markbar-tester
```

Whereupon you should be able to spool up a container instance with:

```bash
yiliny@computer:~/plugins/vim-markbar$ docker run -it -v /path/to/vim-markbar:/root/vim-markbar yiliny/vim-markbar-tester
```

### Building Docker image from scratch
You can build the container image by running these commands:

```bash
# from project root,
docker buildx build --tag yiliny/vim-markbar-tester test
```

This should create a Docker image with the DockerHub repository-name
`yiliny/vim-markbar-tester`.

To spool up a container instance, run the following:
```bash

# this may be necessary for docker to find the yiliny/vim-markbar-tester image
docker login

docker run -it -v /path/to/vim-markbar:/root/vim-markbar yiliny/vim-markbar-tester
```

If that doesn't work then you can just use the newly built image's Image ID directly:
```bash
yiliny@computer:~/plugins/vim-markbar$$ docker images
REPOSITORY                  TAG       IMAGE ID       CREATED              SIZE
yiliny/vim-markbar-tester   latest    xxxxxxxxxxxx   About a minute ago   843MB
ubuntu                      jammy     5a81c4b8502e   2 weeks ago          77.8MB
ubuntu                      kinetic   692eb4a905c0   2 weeks ago          70.3MB
hello-world                 latest    9c7a54a9a43c   2 months ago         13.3kB

yiliny@computer:~/plugins/vim-markbar$ docker run -it -v /path/to/vim-markbar:/root/vim-markbar xxxxxxxxxxxx
```

### Running tests with Docker

You should be attached to the new container instance running as the root user.
The `vim` 8.1.0039 and `nvim` v0.3.4 binaries will be in `/root/out/bin`.

```bash
# from inside /path/to/vim-markbar/test,
./run_tests.sh --vim_exe=~/out/vim8.1.0039/bin/vim
./run_tests.sh --neovim --vim_exe=~/out/nvim0.3.4/bin/nvim
```

Note that if you see messages like `Press ENTER or type command to continue`
when running headless nvim v0.3.4 tests, that suggests that you're receiving
error message prompts "inside" of the running neovim instances, which indicates
test failure.

Detach from the running Docker container with `Ctrl-P` and then `Ctrl-Q`.
Reattach to the container with `docker container ls` and then `docker attach
<NAME>` with the appropriate `NAME` from the list you were given. Deactivate
the container with `docker kill <NAME>`.

```bash
yiliny@computer:~/plugins/vim-markbar$ docker container list
CONTAINER ID   IMAGE     COMMAND       CREATED          STATUS          PORTS     NAMES
xxxxxxxxxxxx   yyyyyyy   "/bin/bash"   27 minutes ago   Up 27 minutes             elated_mccarthy
yiliny@computer:~/plugins/vim-markbar$ docker kill xxxxxxxxxxxx
xxxxxxxxxxxx
yiliny@computer:~/plugins/vim-markbar$ docker container list
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
yiliny@computer:~/plugins/vim-markbar$
```

Other Notes
--------------------------------------------------------------------------------
vader.vim is sensitive to trailing whitespace in its `Expect:` blocks, where
they denote an empty line in the buffer. Some tests (particularly
[standalone-test-openmarkbar.vader](./standalone-test-openmarkbar.vader)
and [standalone-test-peekaboo.vader](./standalone-test-peekaboo.vader)) rely on
this behavior. If you use vim autocommands to automatically delete trailing
whitespace on buffer write, then you should disable those autocommands when
editing vader files.
