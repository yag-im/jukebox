#!/usr/bin/env bash

set -eux

BUILD_NUM_WORKERS=8
BUILD_DIR="/tmp/build"
SRC_DIR="/tmp/src"

cd "$SRC_DIR"

# dep: wayland-protocols
WAYLAND_PROTOCOLS_VERSION="1.32"
git clone --depth=1 --single-branch --branch "$WAYLAND_PROTOCOLS_VERSION" https://gitlab.freedesktop.org/wayland/wayland-protocols.git \
    && cd wayland-protocols \
    && meson setup \
        --prefix="$BUILD_DIR" \
        -Dtests=false \
        build \
    && ninja -C build install

cd "$SRC_DIR"

# dep: mesa-drm
LIBDRM_VERSION="2.4.118"
git clone --depth=1 --single-branch --branch "libdrm-$LIBDRM_VERSION" https://gitlab.freedesktop.org/mesa/drm.git \
    && cd drm \
    && meson setup \
        --prefix="$BUILD_DIR" \
        -Dtests=false \
        -Dvalgrind=disabled \
        -Dman-pages=disabled \
        build \
    && ninja -C build install

cd "$SRC_DIR"

# dep: libinput
LIBINPUT_VERSION="1.24.0"
apt-get install -y --no-install-recommends \
    libevdev-dev \
    libgtk-4-dev \
    libmtdev-dev \
    libudev-dev
git clone --depth=1 --single-branch --branch "$LIBINPUT_VERSION" https://gitlab.freedesktop.org/libinput/libinput.git \
    && cd libinput \
    && meson setup \
        --prefix="$BUILD_DIR" \
        -Dlibwacom=false \
        -Dtests=false \
        build \
    && ninja -C build install

cd "$SRC_DIR"

# dep: libdisplay-info
LIBDISPLAY_VERSION="0.1.1"
apt-get install -y \
    hwdata
git clone --depth=1 --single-branch --branch "$LIBDISPLAY_VERSION" https://gitlab.freedesktop.org/emersion/libdisplay-info \
    && cd libdisplay-info \
    && meson setup \
        --prefix="$BUILD_DIR" \
    build \
    && ninja -C build install

cd "$SRC_DIR"

# dep: wlroots
WLROOTS_VERSION="0.16.2"
apt-get install -y \
    hwdata \
    libseat-dev \
    libgbm-dev
# COPY deps/wlroots wlroots
git clone --depth=1 --single-branch --branch "$WLROOTS_VERSION" https://gitlab.freedesktop.org/wlroots/wlroots.git \
    && cd wlroots \
    && meson setup \
        --prefix="$BUILD_DIR" \
        -Dxwayland=disabled \
        -Dexamples=false \
        -Dbackends=drm,libinput \
        -Drenderers=gles2 \
        -Dallocators=gbm \
    build \
    && ninja -C build install

cd "$SRC_DIR"

# dep: xdg-desktop-portal-wlr
XDPW_VERSION="0.7.0"
apt-get install -y --no-install-recommends \
    libgbm-dev \
    libinih-dev \
    libpipewire-0.3-dev \
    libsystemd-dev
git clone --depth=1 --single-branch --branch "v$XDPW_VERSION" https://github.com/emersion/xdg-desktop-portal-wlr \
    && cd xdg-desktop-portal-wlr \
    && meson setup \
        --prefix="$BUILD_DIR" \
        -Dsystemd=disabled \
        -Dman-pages=disabled \
        build \
    && ninja -C build install

cd "$SRC_DIR"

# dep: labwc
LABWC_VERSION="0.6.5"
apt-get install -y --no-install-recommends \
    hwdata \
    libcairo-dev \
    libglib2.0-dev \
    libpango1.0-dev \
    libpixman-1-dev \
    libseat-dev \
    libudev-dev \
    libxkbcommon-dev
git clone --depth=1 --single-branch --branch "$LABWC_VERSION" https://github.com/labwc/labwc.git \
    && cd labwc \
    && meson setup \
        --wrap-mode=nodownload \
        --prefix="$BUILD_DIR" \
        -Dman-pages=disabled \
        -Dxwayland=disabled \
        -Dsvg=disabled \
        -Dnls=disabled \
        build \
    && ninja -C build install

cd "$SRC_DIR"

# dep: pipewire
# TODO: updating pipewire to 1.0.1+ and wireplumber to 0.5+ breaks pulseaudio, so check periodically for a fix
PIPEWIRE_VERSION="1.0.0"
apt-get install -y --no-install-recommends \
    libdbus-glib-1-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libpulse-dev
git clone --depth=1 --single-branch --branch "$PIPEWIRE_VERSION" https://gitlab.freedesktop.org/pipewire/pipewire.git
# COPY deps/pipewire pipewire
cd pipewire \
    && sed -i 's/head/0\.4\.17/g' subprojects/wireplumber.wrap \
    && meson setup \
        --prefix="$BUILD_DIR" \
        -Dexamples=disabled \
        -Dman=disabled \
        -Dtests=disabled \
        -Dgstreamer=enabled \
        -Dsystemd=disabled \
        -Dselinux=disabled \
        -Dpipewire-alsa=disabled \
        -Dpipewire-jack=disabled \
        -Dpipewire-v4l2=disabled \
        -Dalsa=disabled \
        -Djack=disabled \
        -Dlibcamera=disabled \
        -Dlibpulse=enabled \
        -Dlibusb=disabled \
        -Dsession-managers="[ 'wireplumber' ]" \
        -Dx11=disabled \
        build \
    && ninja -C build install
