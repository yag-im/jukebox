# check CUDA version on the host machine using: `nvidia-smi` before upgrading base image version
ARG IMAGE=nvidia/cuda:11.4.3-devel-ubuntu20.04

FROM $IMAGE AS builder

ENV DEBIAN_FRONTEND=noninteractive

ARG BUILD_BIN_PREFIX=/packages
ARG BUILD_TYPE=release
ARG BUILD_NUM_WORKERS=8

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
      x11-apps \
      wget curl ca-certificates pulseaudio libcairo2 libxcb1 libxrandr2 libxv1 libopus0 libvpx6 \
      git build-essential pkg-config cmake libcap2 libcap-dev \
      libssl-dev libcurl4-openssl-dev liblog4cplus-dev \
      libxrandr-dev libxtst-dev libboost-dev \
      # gstreamer build deps:
      libpango1.0-dev libpulse-dev libsrtp2-dev pip flex bison ninja-build \
   && apt-get clean -y \
   && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH=/root/.cargo/bin:${PATH}

RUN pip install meson tomli
RUN cargo install cargo-c

WORKDIR /src

# COPY gstreamer/subprojects/packages $BUILD_BIN_PREFIX
# RUN git clone --depth 1 --single-branch --branch main https://gitlab.freedesktop.org/gstreamer/gstreamer.git

COPY gstreamer /src/gstreamer
RUN rm -rf /src/gstreamer/build

RUN cd gstreamer \
    && meson setup \
        --wipe \
        -Dbuildtype=$BUILD_TYPE \
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
        -Dgst-plugins-good:pulse=enabled \
        -Dgst-plugins-good:rtp=enabled \
        -Dgst-plugins-good:rtpmanager=enabled \
        -Dgst-plugins-good:ximagesrc=enabled \
        -Dgst-plugins-good:ximagesrc-xfixes=enabled \
        -Dgst-plugins-good:ximagesrc-xshm=enabled \
        -Dgst-plugins-good:ximagesrc-navigation=enabled \
        -Dbad=enabled \
        -Dgst-plugins-bad:dtls=enabled \
        -Dgst-plugins-bad:sctp=enabled \
        -Dgst-plugins-bad:srtp=enabled \
        -Dgst-plugins-bad:videoparsers=enabled \
        -Dgst-plugins-bad:webrtc=enabled \
        -Dgst-plugins-bad:nvcodec=enabled \
        -Dtls=enabled \
        -Drs=enabled \
        -Dgst-plugins-rs:rtp=enabled \
        -Dwebrtc=enabled \
        -Dtests=disabled \
        -Dexamples=disabled \
        build \
    && ninja -C build \
    && meson install -C build

FROM $IMAGE AS runner

ARG BUILD_BIN_PREFIX=/packages

ENV DEBIAN_FRONTEND=noninteractive

ARG USERNAME
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates openssl \
        xserver-xorg-video-dummy x11-xserver-utils \
        pulseaudio \
        supervisor \
        openbox xfce4-terminal firefox procps \
        libsrtp2-dev \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# create non-root user TODO: drop sudo
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/bash \
    && usermod -aG sudo,audio,video,pulse $USERNAME \
    && mkdir -p /run/user/$USER_UID \
    && chmod 0700 /run/user/$USER_UID \
    && chown $USERNAME /run/user/$USER_UID

RUN mkdir -p /home/$USERNAME/.config/pulse/ \
    && echo "default-server=unix:/tmp/pulseaudio.socket" > /home/$USERNAME/.config/pulse/client.conf

RUN chown -R $USERNAME:$USERNAME /home/$USERNAME

COPY files/run_streamer.sh /home/$USERNAME
COPY files/dbus /usr/bin/dbus
COPY files/default.pa /etc/pulse/default.pa

COPY conf/xorg.conf /home/$USERNAME/xorg.conf
COPY conf/supervisord.conf /home/$USERNAME/supervisord.conf
COPY conf/openbox.xml /home/$USERNAME/openbox.xml

COPY --from=builder $BUILD_BIN_PREFIX /usr
RUN ldconfig

# app clones mount point
RUN mkdir /opt/yag && chown -R $USERNAME /opt/yag

ENV USERNAME=$USERNAME

CMD ["/usr/bin/supervisord", "-c", "/etc/gamer/supervisord.conf"]
