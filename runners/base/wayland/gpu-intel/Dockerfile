ARG BASE_IMAGE

ARG BUILD_DIR=/tmp/build

FROM ${BASE_IMAGE} AS builder

ARG BUILD_DIR
ARG BUILD_NUM_WORKERS=8
ARG SRC_DIR=/tmp/src
ARG VIDEO_ENC
ARG WINDOW_SYSTEM
# default log level: INFO
ARG STREAMD_LOG_LEVEL=2

ENV DEBIAN_FRONTEND=noninteractive
ENV PKG_CONFIG_PATH=$BUILD_DIR/lib/x86_64-linux-gnu/pkgconfig/:$BUILD_DIR/share/pkgconfig/

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        automake \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        git \
        pkg-config

WORKDIR $SRC_DIR

COPY files/patches ./patches

COPY files/build_gpu_intel_deps.sh .
RUN ./build_gpu_intel_deps.sh ${WINDOW_SYSTEM}

COPY wayland/files/build_wayland_deps.sh .
RUN ./build_wayland_deps.sh

COPY files/build_gstreamer.sh .
RUN ./build_gstreamer.sh ${BUILD_DIR}

# streamd will try to find gstreamer package while building
RUN cp -r $BUILD_DIR/* /usr

RUN git clone --depth 1 --single-branch --branch main https://github.com/yag-im/streamd.git
RUN cd streamd && ./build.sh --window-system ${WINDOW_SYSTEM} --video-enc ${VIDEO_ENC} --build-dir ${BUILD_DIR} --log-level ${STREAMD_LOG_LEVEL}

# runner
FROM ${BASE_IMAGE} AS runner

ARG BUILD_DIR
ARG USERNAME
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        dbus-daemon \
        hwdata \
        less \
        libcairo-dev \
        libdbus-glib-1-dev \
        libevdev-dev \
        libgbm-dev \
        libgirepository1.0-dev \
        libgles-dev \
        libglib2.0-dev \
        libinih-dev \
        libmtdev-dev \
        libpango1.0-dev \
        libpipewire-0.3-dev \
        libpixman-1-dev \
        libpulse-dev \
        libseat-dev \
        libsrtp2-dev \
        libudev-dev \
        libxkbcommon-dev \
        openssl \
        procps \
        rtkit \
        vim \
        wlr-randr \
        xdg-desktop-portal \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# TODO: sync /run/user/$USER_UID with XDG_RUNTIME_DIR
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && mkdir -p /run/user/$USER_UID \
    && chmod 0700 /run/user/$USER_UID \
    && chown $USERNAME /run/user/$USER_UID

COPY --from=builder $BUILD_DIR /usr

COPY wayland/files/run_ws.sh /home/$USERNAME
COPY wayland/files/restart_streamd.sh /home/$USERNAME
RUN mkdir -p /usr/share/xdg-desktop-portal-wlr
COPY wayland/files/xdg-desktop-portal-wlr.conf /usr/share/xdg-desktop-portal-wlr/config

RUN chown -R $USERNAME:$USERNAME /home/$USERNAME

# tmp dropme
# warning: firefox depends on intel-media-va-driver which replaces iHD driver and crashes the pipeline
# RUN apt update && apt-get install -y firefox-esr intel-media-va-driver-

COPY files/init.sh /etc/init.d/init.sh

ENV USERNAME=$USERNAME
ENV USER_UID=$USER_UID

ENTRYPOINT ["/etc/init.d/init.sh"]

# apt install intel-gpu-tools
# intel_gpu_top
# vainfo --display drm --device /dev/dri/renderD128
