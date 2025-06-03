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

ARG CUDA_VER_MAJOR
ARG CUDA_VER_MINOR

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
        pkg-config

WORKDIR $SRC_DIR

COPY files/patches ./patches

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
# TODO: sync-up with an appstor hardcoded user IDs (search for 1000 in the yag-infra project)
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG USER_UBUNTU=ubuntu

ARG CUDA_VER_MAJOR
ARG CUDA_VER_MINOR

ENV DEBIAN_FRONTEND=noninteractive

# libnvidia-encode is requred by gstreamer pipeline at runtime
# TODO: sync libnvidia-encode-560 with nvidia-smi version on the host
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        xserver-xorg-video-dummy x11-xserver-utils \
        pulseaudio \
        openssl \
        openbox \
        procps \
        xterm \
        libsrtp2-dev \
        libnvidia-encode-560 \
        fluidsynth fluid-soundfont-gm \
        cuda-nvrtc-${CUDA_VER_MAJOR}-${CUDA_VER_MINOR} \
        # firefox \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# TODO: sync /run/user/$USER_UID with XDG_RUNTIME_DIR
# in the nvidia base image UID 1000 is already occupied by ubuntu user, so just renaming it as id must be preserved for appstor mount needs
RUN usermod -md /home/$USERNAME -l $USERNAME $USER_UBUNTU \
    && groupmod -n $USERNAME $USER_UBUNTU \
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

# without modified LD_LIBRARY_PATH, pipeline fails with: 
# libcuda.so.1: cannot open shared object file: No such file or directory
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-${CUDA_VER_MAJOR}.${CUDA_VER_MINOR}/compat
RUN ln -s /usr/local/cuda/lib64/libnvrtc.so.${CUDA_VER_MAJOR} /usr/local/cuda/lib64/libnvrtc.so

ENTRYPOINT ["/etc/init.d/init.sh"]
