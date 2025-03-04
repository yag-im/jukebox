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

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        automake \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        git \
        libdrm-dev \
        libx11-dev \
        libx11-xcb-dev \
        libxcb-dri3-dev \
        libxext-dev \
        libxtst-dev \
        libxfixes-dev \
        linux-perf \
        pkg-config

WORKDIR $SRC_DIR

COPY files/patches ./patches

COPY files/build_gpu_intel_deps.sh .
RUN ./build_gpu_intel_deps.sh ${WINDOW_SYSTEM}

COPY files/build_gstreamer.sh .
RUN ./build_gstreamer.sh ${BUILD_DIR} --${VIDEO_ENC}

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

# warning: firefox depends on intel-media-va-driver which replaces iHD driver and crashes the pipeline
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        xserver-xorg-video-dummy x11-xserver-utils \
        pulseaudio \
        openssl \
        openbox \
        dbus-daemon \
        procps \
        xterm \
        libsrtp2-dev \
        fluidsynth fluid-soundfont-gm \
        # firefox-esr intel-media-va-driver- \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# TODO: sync /run/user/$USER_UID with XDG_RUNTIME_DIR
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && usermod -aG audio,video,pulse $USERNAME \
    && mkdir -p /run/user/$USER_UID \
    && chmod 0700 /run/user/$USER_UID \
    && chown $USERNAME /run/user/$USER_UID

RUN mkdir -p /home/$USERNAME/.config/pulse/ \
    && echo "default-server=unix:/tmp/pulseaudio.socket" > /home/$USERNAME/.config/pulse/client.conf

# sudo block
# RUN apt-get update \
#     && apt-get install -y sudo \
#     && usermod -aG sudo $USERNAME \
#     && echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers

RUN chown -R $USERNAME:$USERNAME /home/$USERNAME

# TODO: sync with XDG_RUNTIME_DIR
RUN mkdir -p /tmp/x11 && chown -R $USERNAME /tmp/x11
RUN mkdir -p /usr/share/pulse && chown -R $USERNAME /usr/share/pulse

COPY --from=builder $BUILD_DIR /usr

COPY x11/files/run_ws.sh /home/$USERNAME
COPY x11/files/restart_streamd.sh /home/$USERNAME
COPY x11/files/default.pa /etc/pulse/default.pa
COPY x11/files/xorg.conf /home/$USERNAME/xorg.conf
COPY x11/files/openbox.xml /home/$USERNAME/openbox.xml
COPY x11/files/daemon.conf /etc/pulse/daemon.conf

COPY files/init.sh /etc/init.d/init.sh

ENV USERNAME=$USERNAME
ENV USER_UID=$USER_UID

ENTRYPOINT ["/etc/init.d/init.sh"]

# apt install intel-gpu-tools
# intel_gpu_top
# vainfo --display drm --device /dev/dri/renderD128
