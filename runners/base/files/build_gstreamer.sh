#!/usr/bin/env bash

set -eux

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 BUILD_DIR [--gpu-nvidia | --gpu-intel]"
    exit 1
fi

# gpl: required by x264/5 codecs
# libnice: required by webrtc
# opus: required by libnice
# rtpmanager: required by gst-plugins-rs
# webrtc: required by gst-plugins-rs
# tls/dtls: required by libnice:streamer
# sctp: required by webrtc
# pango: required for time/text overlays

BUILD_BIN_PREFIX=$1
GSTREAMER_VERSION=1.26.5
GST_PLUGINS_RS_VERSION=add_send_webrtc_stats_20250813

apt-get update \
    && apt-get install --no-install-recommends -y \
      build-essential curl pkg-config cmake libssl-dev libunwind-dev libdw-dev \
      libpango1.0-dev libpulse-dev libsrtp2-dev pip flex bison ninja-build \
      xserver-xorg-video-dummy x11-xserver-utils libxkbcommon-dev \
      libdrm-dev \
      procps

pip install tomli meson --break-system-packages

# rustc is required to build gst-plugins-rs
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
rustup update
cargo install --locked cargo-c

git clone --depth=1 --single-branch --branch "$GSTREAMER_VERSION"  https://github.com/GStreamer/gstreamer.git
# fix 100ms delay A/V sync issue in chrome
patch gstreamer/subprojects/gst-plugins-good/gst/rtpmanager/rtpsource.c patches/rtpsource.c.patch
git clone --depth=1 --single-branch --branch "$GST_PLUGINS_RS_VERSION"  https://gitlab.freedesktop.org/rayrapetyan/gst-plugins-rs.git gstreamer/subprojects/gst-plugins-rs

cd gstreamer

NVIDIA_OPTION=$([[ "$@" =~ "--gpu-nvidia" ]] && echo "-Dgst-plugins-bad:nvcodec=enabled" || echo "")
INTEL_OPTION=$([[ "$@" =~ "--gpu-intel" ]] && echo "-Dgst-plugins-bad:qsv=enabled -Dgst-plugins-bad:va=enabled" || echo "")

meson setup \
    --wipe \
    -Dbuildtype=release \
    -Dprefix=$BUILD_BIN_PREFIX \
    -Dauto_features=disabled \
    -Dgpl=enabled \
    -Dtools=enabled \
    -Dlibnice=enabled \
    -Dlibnice:gstreamer=enabled \
    -Dbase=enabled \
    -Dgst-plugins-base:app=enabled \
    -Dgst-plugins-base:audioconvert=enabled \
    -Dgst-plugins-base:audioresample=enabled \
    -Dgst-plugins-base:opus=enabled \
    -Dgst-plugins-base:pango=enabled \
    -Dgst-plugins-base:tools=enabled \
    -Dgst-plugins-base:videoconvertscale=enabled \
    -Dgst-plugins-base:videorate=enabled \
    -Dgst-plugins-base:videotestsrc=enabled \
    -Dgst-plugins-base:x11=enabled \
    -Dgst-plugins-base:xshm=enabled \
    -Dgood=enabled \
    -Dgst-plugins-good:effectv=enabled \
    -Dgst-plugins-good:pulse=enabled \
    -Dgst-plugins-good:rtp=enabled \
    -Dgst-plugins-good:rtpmanager=enabled \
    -Dgst-plugins-good:ximagesrc=enabled \
    -Dgst-plugins-good:ximagesrc-xfixes=enabled \
    -Dgst-plugins-good:ximagesrc-xshm=enabled \
    -Dbad=enabled \
    -Dgst-plugins-bad:dtls=enabled \
    -Dgst-plugins-bad:sctp=enabled \
    -Dgst-plugins-bad:srtp=enabled \
    -Dgst-plugins-bad:videoparsers=enabled \
    -Dgst-plugins-bad:webrtc=enabled \
    $NVIDIA_OPTION \
    $INTEL_OPTION \
    -Dugly=enabled \
    -Dgst-plugins-ugly:x264=enabled \
    -Dtls=enabled \
    -Drs=enabled \
    -Dgst-plugins-rs:rtp=enabled \
    -Dwebrtc=enabled \
    -Dtests=disabled \
    -Dexamples=disabled \
    build \
&& ninja -C build \
&& meson install -C build
