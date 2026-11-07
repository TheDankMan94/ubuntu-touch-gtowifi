# Build container for Halium 9 (Android 9). Android 9 needs Python 2 and an older host
# toolchain than Linux Mint 22 / Ubuntu 24.04 provides, so we build in Ubuntu 20.04.
FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ARG HOST_UID=1000
ARG HOST_GID=1000

RUN apt-get update && apt-get install -y --no-install-recommends \
    bc bison build-essential bzip2 ca-certificates ccache cpio curl dosfstools \
    fontconfig flex g++-multilib gcc-multilib git git-lfs gnupg gperf kmod \
    lib32ncurses5-dev lib32z1-dev libc6-dev-i386 libelf-dev libgl1-mesa-dev \
    libncurses5 libncurses5-dev libreadline-dev libssl-dev libx11-dev libxml2-utils \
    lz4 openssh-client python2 python3 python-is-python2 rsync sudo unzip \
    x11proto-core-dev xsltproc zip zlib1g-dev android-sdk-libsparse-utils \
    android-sdk-ext4-utils abootimg \
 && rm -rf /var/lib/apt/lists/*

# Same uid/gid as the host user so files in the mounted source tree stay yours.
RUN groupadd -g ${HOST_GID} builder \
 && useradd -m -u ${HOST_UID} -g ${HOST_GID} -s /bin/bash builder \
 && echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder

# 'repo' is mounted from the host (~/.local/bin or /usr/bin); fetch it inside if missing.
USER builder
WORKDIR /home/builder
ENV USE_CCACHE=1 CCACHE_EXEC=/usr/bin/ccache CCACHE_DIR=/work/.ccache LC_ALL=C
