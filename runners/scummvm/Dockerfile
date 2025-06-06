ARG BASE_IMAGE

ARG BUILD_DIR=/tmp/build

# scummvm binaries builder
FROM ${BASE_IMAGE} AS builder

ARG BUILD_DIR
ARG NUM_BUILD_WORKERS=8
ARG OS_TYPE
ARG RUNNER_VER
ARG SRC_DIR=/tmp/src

ENV DEBIAN_FRONTEND=noninteractive

# deps: https://wiki.scummvm.org/index.php?title=Compiling_ScummVM/GCC
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        automake \
        build-essential \
        ca-certificates \
        git \
        nasm libsdl2-dev libsdl2-net-dev liba52-dev  libmpeg2-4-dev libogg-dev libvorbis-dev libflac-dev libmad0-dev \
        libpng-dev libtheora-dev libfaad-dev libfluidsynth-dev libfreetype6-dev zlib1g-dev libfribidi-dev libgif-dev \
        libglew-dev libcurl4-openssl-dev libgtk-3-dev libspeechd-dev libsndio-dev \
        $(if [ "${OS_TYPE}" = "ubuntu" ]; then echo "libjpeg-turbo8-dev"; elif [ "${OS_TYPE}" = "debian" ]; then echo "libjpeg62-turbo-dev"; fi)
RUN rm -rf /var/lib/apt/lists/*

WORKDIR ${SRC_DIR}

RUN git clone --depth 1 --single-branch --branch v${RUNNER_VER} https://github.com/scummvm/scummvm.git
RUN cd ./scummvm \
    && ./configure --enable-all-engines \
    && make -j${NUM_BUILD_WORKERS} \
    && mkdir -p ${BUILD_DIR} \
    && make DESTDIR=${BUILD_DIR} install

# scummvm runner
FROM ${BASE_IMAGE} AS runner

ARG BUILD_DIR
ARG OS_TYPE

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nasm libsdl2-dev libsdl2-net-dev liba52-dev libmpeg2-4-dev libogg-dev libvorbis-dev libflac-dev libmad0-dev \
        libpng-dev libtheora-dev libfaad-dev libfluidsynth-dev libfreetype6-dev zlib1g-dev libfribidi-dev libgif-dev \
        libglew-dev libcurl4-openssl-dev libgtk-3-dev libspeechd-dev libsndio-dev \
        $(if [ "${OS_TYPE}" = "ubuntu" ]; then echo "libjpeg-turbo8-dev"; elif [ "${OS_TYPE}" = "debian" ]; then echo "libjpeg62-turbo-dev"; fi)
RUN rm -rf /var/lib/apt/lists/*

COPY --from=builder ${BUILD_DIR} /

ENTRYPOINT ["/etc/init.d/init.sh"]
