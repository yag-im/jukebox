ARG BASE_IMAGE

ARG PACKAGES_DIR=/tmp/packages

# wine binaries builder
FROM ${BASE_IMAGE} AS builder

ARG BUILD_DIR=/tmp/build
ARG OS_TYPE
ARG OS_VER
ARG PACKAGES_DIR
ARG SRC_DIR=/tmp/src

ARG NUM_BUILD_WORKERS=8
ARG RUNNER_VER

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        automake \
        bison \
        build-essential \
        ca-certificates \
        flex \
        gcc-multilib \
        gettext \
        git

WORKDIR ${SRC_DIR}

RUN git clone --depth 1 --single-branch --branch wine-${RUNNER_VER} https://github.com/wine-mirror/wine.git
# honor drive type reported by mounts manager (configured through the wincfg) 
# otherwise GetDriveTypeW() returns DRIVE_REMOTE for NFS mounted directories while we want them as DRIVE_CDROM
COPY patches/*.patch .
RUN patch ./wine/dlls/kernelbase/volume.c kernelbase-volume.c.patch
RUN patch ./wine/dlls/kernel32/volume.c kernel32-volume.c.patch
RUN patch ./wine/programs/winecfg/driveui.c winecfg-driveui.c.patch

# alsa is required for midi (in pilot-brothers)
# libxxf86vm is required for directx switch to fullscreen (NtUserChangeDisplaySettings -> apply_display_settings) (in galador)

# install wine64 deps
RUN apt-get install -y --no-install-recommends \
    libasound2-dev \
    libfontconfig-dev \
    libfreetype-dev \
    libgl-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libosmesa6-dev \
    libpulse-dev \
    libsdl2-dev \
    libudev-dev \
    libunwind-dev \
    libx11-dev \
    libxcomposite-dev \
    libxcursor-dev \
    libxext-dev \
    libxfixes-dev \
    libxi-dev \
    libxrandr-dev \
    libxrender-dev \
    libxxf86vm-dev

# build wine64
WORKDIR ${BUILD_DIR}/wine64

RUN ${SRC_DIR}/wine/configure \
        --prefix=${PACKAGES_DIR}/wine64 \
        --enable-win64 \
    && make -j${NUM_BUILD_WORKERS} \
    && make install

# install wine32 deps
RUN dpkg --add-architecture i386 \
    && apt-get update

# otherwise libudev-dev:i386 installation fails on ubuntu
RUN rm -rf /usr/share/gir-1.0/GUdev-1.0.gir

RUN apt-get install -y \
    libasound2-dev:i386 \
    libfontconfig-dev:i386 \
    libfreetype-dev:i386 \
    libgl-dev:i386 \
    libgstreamer1.0-dev:i386 \
    libgstreamer-plugins-base1.0-dev:i386 \
    libosmesa6-dev:i386 \
    libpulse-dev:i386 \
    libsdl2-dev:i386 \
    libudev-dev:i386 \
    libunwind-dev:i386 \
    libx11-dev:i386 \
    libxcomposite-dev:i386 \
    libxcursor-dev:i386 \
    libxext-dev:i386 \
    libxfixes-dev:i386 \
    libxi-dev:i386 \
    libxrandr-dev:i386 \
    libxrender-dev:i386 \
    libxxf86vm-dev:i386

# build wine32-tools
WORKDIR ${BUILD_DIR}/wine32-tools

RUN ${SRC_DIR}/wine/configure \
        --prefix=${PACKAGES_DIR}/wine32-tools \
    && make -j${NUM_BUILD_WORKERS} \
    && make install
  
# build wine32
WORKDIR ${BUILD_DIR}/wine32

RUN ${SRC_DIR}/wine/configure \
        --prefix=${PACKAGES_DIR}/wine32 \
        --with-wine64=${BUILD_DIR}/wine64 \
        --with-wine-tools=${BUILD_DIR}/wine32-tools \
    && make -j${NUM_BUILD_WORKERS} \
    && make install

ARG BASE_IMAGE

# wine runner
FROM ${BASE_IMAGE} AS runner

ARG OS_TYPE
ARG OS_VER
ARG PACKAGES_DIR
ARG RUNNER_BRANCH

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        fluidsynth \
        gnupg2 \
        wget

# we need this block to just install all runtime deps; we're replacing all wine binaries afterward.
# styrlitz requires avi player (gstreamer1.0-plugins-good:i386) with intel indeo codec (gstreamer1.0-libav:i386)
RUN dpkg --add-architecture i386 \
    && mkdir -pm755 /etc/apt/keyrings \
    && wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
    && wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/${OS_TYPE}/dists/${OS_VER}/winehq-${OS_VER}.sources \
    && apt-get update \
    && apt-get install --install-recommends -y \
        gstreamer1.0-plugins-good:i386 \
        gstreamer1.0-libav:i386 \
        wine-${RUNNER_BRANCH} \
        $(if [ "${OS_TYPE}" = "debian" ]; then echo "winehq-stable"; fi) \
    && rm -rf /var/lib/apt/lists/*

# install wine32 (should go first) and wine64
RUN rm -rf /opt/wine-stable
COPY --from=builder ${PACKAGES_DIR}/wine32 /opt/wine-stable
COPY --from=builder ${PACKAGES_DIR}/wine64 /opt/wine-stable

RUN if [ "${OS_TYPE}" = "ubuntu" ]; then \
        rm -rf /usr/bin/wine \
        && ln -s /opt/wine-stable/bin/wine /usr/bin/wine; \
    fi

ENTRYPOINT ["/etc/init.d/init.sh"]
