ARG BASE_IMAGE

ARG BUILD_DIR=/tmp/build

# qemu binaries builder
FROM ${BASE_IMAGE} AS builder

ARG BUILD_DIR
ARG NUM_BUILD_WORKERS=8
ARG RUNNER_VER
ARG SRC_DIR=/tmp/src

ENV DEBIAN_FRONTEND=noninteractive

# deps: https://www.qemu.org/docs/master/devel/build-environment.html
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        git \
        ninja-build \
        pkg-config \
        python3 \
        python3-venv \
        libepoxy-dev \
        libgbm-dev \
        libglib2.0-dev \
        libgtk-3-dev \
        libpixman-1-dev \
        libpulse-dev \
        libsdl2-dev \
        zlib1g-dev
RUN rm -rf /var/lib/apt/lists/*

WORKDIR ${SRC_DIR}

RUN git clone --depth 1 --single-branch --branch v${RUNNER_VER} https://gitlab.com/qemu-project/qemu.git

# Ctrl+F4 cycling through multiple -cdrom / -cdrom-swap images (GTK and SDL displays)
COPY patches/*.patch .
RUN cd ./qemu \
    && git apply --verbose ../cdrom-swap.patch

# minimal x86_64 system emulator (KVM + TCG fallback) with SDL/GTK (OpenGL) displays, PulseAudio and qemu-img
RUN cd ./qemu \
    && ./configure \
        --prefix=/usr \
        --target-list=x86_64-softmmu \
        --without-default-features \
        --audio-drv-list=pa \
        --disable-debug-info \
        --enable-strip \
        --enable-gtk \
        --enable-kvm \
        --enable-opengl \
        --enable-pa \
        --enable-pixman \
        --enable-sdl \
        --enable-tcg \
        --enable-tools \
    && make -j${NUM_BUILD_WORKERS} \
    && mkdir -p ${BUILD_DIR} \
    && make DESTDIR=${BUILD_DIR} install

# qemu runner
FROM ${BASE_IMAGE} AS runner
ARG BUILD_DIR
ARG USERNAME

ENV DEBIAN_FRONTEND=noninteractive
# qemu 11 (unlike 10.0) forces SDL to use EGL instead of GLX on X11 (for dma-buf), which renders vertical stripes and a
# squeezed image with "-display sdl,gl=on" on a 16-bit X server (e.g. COLOR_BITS=16). Env var overrides that hint.
ENV SDL_VIDEO_X11_FORCE_EGL=0

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libepoxy0 \
        libgbm1 \
        libglib2.0-0t64 \
        libgtk-3-0t64 \
        libpixman-1-0 \
        libpulse0 \
        libsdl2-2.0-0 \
        zlib1g
RUN rm -rf /var/lib/apt/lists/*

COPY --from=builder ${BUILD_DIR} /

RUN groupadd -f -r kvm \
    && usermod -aG kvm $USERNAME

ENTRYPOINT ["/etc/init.d/init.sh"]
