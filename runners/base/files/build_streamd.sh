#!/usr/bin/env bash

set -eux

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 WINDOW_SYSTEM (x11, wayland) VIDEO_ENC (gpu-intel, cpu)"
    exit 1
fi

WINDOW_SYSTEM="$1"
VIDEO_ENC="$2"

BUILD_NUM_WORKERS=8
BUILD_DIR="/tmp/build"
BUILD_TYPE=Release
SRC_DIR="/tmp/src"

apt-get install -y --no-install-recommends \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev

cd "$SRC_DIR"

# TODO: make sure COPY "deps/streamd/$WINDOW_SYSTEM" streamd was called from your Dockerfile

# dep: streamd
cd streamd \
    && cmake -E make_directory "build" \
    && cmake \
        -DCMAKE_INSTALL_PREFIX="$BUILD_DIR" \
        -DVIDEO_ENC="$VIDEO_ENC" \
        -S . -B "build" \
    && cmake --build "build" --config "$BUILD_TYPE" --parallel $BUILD_NUM_WORKERS

cd "$SRC_DIR"

mkdir -p "$BUILD_DIR/bin" && cp streamd/build/src/streamd "$BUILD_DIR/bin/streamd"
