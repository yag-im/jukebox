#!/usr/bin/env bash

set -eux

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 WINDOW_SYSTEM (x11 or wayland)"
    exit 1
fi

WINDOW_SYSTEM="$1"

export PKG_CONFIG_PATH="$BUILD_DIR/lib/pkgconfig:$BUILD_DIR/lib/x86_64-linux-gnu/pkgconfig"

BUILD_NUM_WORKERS=8
BUILD_DIR="/tmp/build"
SRC_DIR="/tmp/src"

# i965-va-driver is the intel-vaapi-driver (2.4.1 was released in 2020 and has never been updated since then)
# https://github.com/intel/intel-vaapi-driver/releases
apt-get install -y --no-install-recommends \
        i965-va-driver \
        libdrm-dev \
        ninja-build \
        pip \
    && pip install meson --break-system-packages

cd "$SRC_DIR"

if [ "$WINDOW_SYSTEM" = "wayland" ]; then
    # dep: wayland (required for intel-wayland deps)
    WAYLAND_VERSION="1.22.0"
    apt-get install -y --no-install-recommends \
        libexpat1-dev \
        libffi-dev \
        libxml2-dev
    git clone --depth=1 --single-branch --branch "$WAYLAND_VERSION" https://gitlab.freedesktop.org/wayland/wayland.git
    # COPY deps/wayland wayland
    cd wayland \
        && meson setup \
            --prefix="$BUILD_DIR" \
            -Ddocumentation=false \
            -Dtests=false \
            build \
        && ninja -C build install
elif [ "$WINDOW_SYSTEM" = "x11" ]; then
    apt-get install -y --no-install-recommends \
        libx11-dev \
        libx11-xcb-dev \
        libxcb-dri3-dev \
        libxext-dev \
        libxtst-dev \
        libxfixes-dev
else
    echo "Invalid WINDOW_SYSTEM provided: $WINDOW_SYSTEM"
    exit 1
fi

cd "$SRC_DIR"

# dep: intel-libva
LIBVA_VERSION="2.22.0"
LIBVA_URL="https://github.com/intel/libva/releases/download/$LIBVA_VERSION/libva-$LIBVA_VERSION.tar.bz2"
mkdir libva \
    && curl -# -L -f "$LIBVA_URL" | tar xj --strip 1 -C libva \
    && mkdir libva/build \
    && cd libva \
    && meson setup \
        -Dprefix="$BUILD_DIR" \
        -Dlibdir="$BUILD_DIR/lib/x86_64-linux-gnu" \
        -Dwith_glx=no \
        $( [ "$WINDOW_SYSTEM" == "wayland" ] && echo "-Dwith_wayland=yes -Dwith_x11=no" ) \
        $( [ "$WINDOW_SYSTEM" == "x11" ] && echo "-Dwith_x11=yes -Dwith_wayland=no" ) \
        build \
    && ninja -C build \
    && meson install -C build

cd "$SRC_DIR"

# dep: intel-media-driver
GMMLIB_VERSION="22.5.5"
GMMLIB_URL="https://github.com/intel/gmmlib/archive/intel-gmmlib-$GMMLIB_VERSION.tar.gz"
INTEL_MEDIA_DRIVER_VERSION="24.3.4"
INTEL_MEDIA_DRIVER_URL="https://github.com/intel/media-driver/archive/intel-media-$INTEL_MEDIA_DRIVER_VERSION.tar.gz"
# intel-media-driver looks in ../gmmlib
mkdir gmmlib \
    && curl -# -L -f "$GMMLIB_URL" | tar xz --strip 1 -C gmmlib
mkdir intel-media-driver \
    && curl -# -L -f "$INTEL_MEDIA_DRIVER_URL" | tar xz --strip 1 -C intel-media-driver \
    && mkdir intel-media-driver/build \
    && cd intel-media-driver/build \
    && cmake \
        -DBUILD_TYPE="Release" \
        -DCMAKE_INSTALL_PREFIX="$BUILD_DIR" \
        -DMEDIA_RUN_TEST_SUITE="OFF" \
        -DSKIP_GMM_CHECK="ON" \
        ../ \
    && make -j$BUILD_NUM_WORKERS \
    && make install

cd "$SRC_DIR"

# dep: oneVPL-intel-gpu
INTEL_ONEVPL_GPU_RUNTIME_VERSION="24.3.4"
INTEL_ONEVPL_GPU_RUNTIME_URL="https://github.com/oneapi-src/oneVPL-intel-gpu/archive/refs/tags/intel-onevpl-$INTEL_ONEVPL_GPU_RUNTIME_VERSION.tar.gz"
mkdir oneVPL-intel-gpu \
    && curl -# -L -f "$INTEL_ONEVPL_GPU_RUNTIME_URL" | tar xz --strip 1 -C oneVPL-intel-gpu \
    && mkdir oneVPL-intel-gpu/build \
    && cd oneVPL-intel-gpu/build \
    && cmake \
        -DCMAKE_BUILD_TYPE="Release" \
        -DCMAKE_INSTALL_PREFIX="$BUILD_DIR" \
        ../ \
    && make -j$BUILD_NUM_WORKERS \
    && make install
