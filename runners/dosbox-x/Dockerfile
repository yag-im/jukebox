ARG BASE_IMAGE

ARG BUILD_DIR=/tmp/build

# dosbox-x binaries builder
FROM ${BASE_IMAGE} AS builder

ARG BUILD_DIR
ARG NUM_BUILD_WORKERS=8
ARG RUNNER_VER
ARG SRC_DIR=/tmp/src
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        automake \
        build-essential \
        ca-certificates \
        git \
        libncurses-dev nasm libsdl-net1.2-dev libsdl2-net-dev libpcap-dev libslirp-dev libfluidsynth-dev \
        libavformat-dev libavcodec-dev libavcodec-extra libswscale-dev libfreetype-dev libxkbfile-dev libxrandr-dev
RUN rm -rf /var/lib/apt/lists/*

WORKDIR ${SRC_DIR}

RUN git clone --depth 1 --single-branch --branch dosbox-x-v${RUNNER_VER} https://github.com/joncampbell123/dosbox-x.git

# --disable-debug resolves a bug "Shift+A is a new built-in hotkey that toggles mute on the AWE" introduced by ac3f80e14
RUN cd ./dosbox-x \
    && ./build-sdl2 --disable-debug \
    && make DESTDIR=${BUILD_DIR} install

# dosbox-x runner
FROM ${BASE_IMAGE} AS runner
ARG BUILD_DIR

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \        
        libncurses-dev libsdl-net1.2-dev libsdl2-net-dev libpcap-dev libslirp-dev \
        libfluidsynth-dev \
        libavformat-dev libavcodec-dev libavcodec-extra libswscale-dev libfreetype-dev libxkbfile-dev libxrandr-dev
RUN rm -rf /var/lib/apt/lists/*

COPY --from=builder ${BUILD_DIR} /

ENV ENABLE_RELATIVE_MOUSE_MOVES=false

ENTRYPOINT ["/etc/init.d/init.sh"]
