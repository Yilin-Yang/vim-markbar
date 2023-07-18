FROM ubuntu:kinetic
# FROM ubuntu:jammy

# $HOME will evaluate to /root
WORKDIR /root

# can't directly use $HOME in Dockerfile without this
ENV HOME=/root

RUN apt-get update


# git clone first, to save time when debugging failing builds of this image
# RUN apt-get install -y git build-essential gcc=4:11.2.0-1ubuntu1
RUN apt-get install -y git build-essential gcc

# to try to stop RPC failures, see: https://stackoverflow.com/a/46171246
RUN git config --global http.postBuffer 1048576000


RUN echo 'Clone vim repo.' && \
    git clone https://github.com/vim/vim ${HOME}/vim
# RUN echo 'Clone neovim repo.' && \
#     git clone https://github.com/neovim/neovim ${HOME}/neovim

# # install build dependencies for neovim (from the wiki)
# RUN apt-get install -y ninja-build gettext cmake unzip curl

# # install build dependencies for neovim (from cmake build failures)
# RUN apt-get install -y luajit libuv1 libuv1-dev libmsgpack-dev pkg-config \
#     libluajit-5.1-dev libunibilium-dev libtermkey-dev libvterm-dev \
#     libjemalloc-dev lua-lpeg-dev lua-mpack gperf libtool libtool-bin \
#     libgtest-dev zlib1g-dev doxygen lua-luv-dev

# and then for vim (as reported by build failures during ./configure)
RUN apt-get install -y libncurses5-dev


WORKDIR ${HOME}/vim

# bust the cache to force a clean rebuild, https://stackoverflow.com/a/49772666
# ARG CACHEBUST=1

# build target vim version from source, install artifacts in $HOME/out
RUN echo 'Build and install vim 8.1.0039.' && \
    git checkout v8.1.0039 && \
    ./configure --with-features=huge --prefix=$HOME/out/vim8.1.0039 && \
    make -j install


# RUN mkdir ${HOME}/neovim/build
# RUN mkdir ${HOME}/neovim/.deps
# WORKDIR ${HOME}/neovim/.deps


# build neovim dependencies from source: more deterministic than relying on apt
# "fill in the gaps" when an apt-provided package doesn't work
# RUN echo 'Build third-party neovim dependencies.' && \
#     git checkout v0.3.4 && \
#     # git checkout v0.4.4 && \
#     # cmake ../third-party -G Ninja && \
#     cmake ../third-party && \
#     # ninja
#     make -j


# WORKDIR ${HOME}/neovim/build
# # ditto: build target neovim version from source, etc.
# RUN echo 'Build and install neovim v0.3.4.' && \
#     # git checkout v0.3.4 && \
#     # git checkout v0.4.4 && \
#     cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=${HOME}/usr && \
#     cmake .. && \
#     make -j && \
#     make install

# ^ Setting up this build to work properly is absurdly difficult, unless I'm
# just doing something wrong. Currently fails due to "multiple definition".

# just git it done; download pre-compiled artifacts
WORKDIR ${HOME}
RUN apt-get install -y curl
RUN curl -fLo nvim-linux64.tar.gz https://github.com/neovim/neovim/releases/download/v0.3.4/nvim-linux64.tar.gz
RUN tar -xaf nvim-linux64.tar.gz

# unpack from the archive's folder into our 'out' artifacts folder
RUN apt-get install -y rsync
RUN rsync -avz nvim-linux64/* ${HOME}/out/nvim0.3.4
