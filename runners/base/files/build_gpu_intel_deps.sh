#!/usr/bin/env bash

set -eux

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 WINDOW_SYSTEM (x11 or wayland)"
    exit 1
fi

WINDOW_SYSTEM="$1"

BUILD_NUM_WORKERS=8
BUILD_DIR="/tmp/build"
SRC_DIR="/tmp/src"

cd "$SRC_DIR"

# Intel Media SDK is the last missing component for Debian Trixie and newer; it previously came as libmfx1.
# We require it solely for libmfxhw64.so, which is needed for Coffee Lake Intel GPUs (like those in our OVH instance).
# The gst QSV plugin uses it to interface with older GPUs, while newer GPUs are supported via Intel's libvpl (libmfx-gen.so).
# TODO: remove once the OVH instance is upgraded to a newer GPU.
INTEL_MEDIA_SDK_VERSION="23.2.2"
INTEL_MEDIA_SDK_URL=https://github.com/Intel-Media-SDK/MediaSDK/archive/refs/tags/intel-mediasdk-$INTEL_MEDIA_SDK_VERSION.tar.gz
mkdir msdk \
    && curl -# -L -f "$INTEL_MEDIA_SDK_URL" | tar xz --strip 1 -C msdk \
    && mkdir msdk/build \
    && cd msdk/build \
    && cmake \
        -DCMAKE_BUILD_TYPE="Release" \
        -DCMAKE_INSTALL_PREFIX="$BUILD_DIR" \
        -DENABLE_OPENCL=OFF \
        $( [ "$WINDOW_SYSTEM" == "wayland" ] && echo "-DENABLE_WAYLAND=ON" ) \
        -DMFX_ENABLE_KERNELS=OFF \
        -DBUILD_DISPATCHER=OFF \
        -DBUILD_SAMPLES=OFF \
        -DBUILD_TESTS=OFF \
        -DBUILD_TUTORIALS=OFF \
        ../ \
    && make -j$BUILD_NUM_WORKERS \
    && make install
