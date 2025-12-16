ARG BASE_IMAGE

ARG BUILD_DIR=/tmp/build

# dosbox-staging binaries builder
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
        pip ninja-build \
        ccache libasound2-dev libatomic1 libpng-dev libsdl2-dev libsdl2-image-dev libsdl2-net-dev libopusfile-dev \
        libfluidsynth-dev libslirp-dev libspeexdsp-dev libxi-dev
RUN rm -rf /var/lib/apt/lists/*

WORKDIR ${SRC_DIR}

RUN git clone --depth 1 --single-branch --branch v${RUNNER_VER} https://github.com/dosbox-staging/dosbox-staging.git

RUN pip install meson --break-system-packages

# with opengl dosbox crashes with: SDL: could not initialize video: Couldn't find matching GLX visual
# with use_zlib_ng dosbox crashes with: Illegal instruction (due to the CPUs diff in build and runtime)
RUN cd ./dosbox-staging \
    && meson setup \
        -Dbuildtype=release \
        -Dprefix=$BUILD_DIR \
        -Duse_mt32emu=false \
        -Duse_zlib_ng=false \
        -Duse_opengl=false \
        build \
    && ninja -C build \
    && meson install -C build

# dosbox-staging runner
FROM ${BASE_IMAGE} AS runner
ARG BUILD_DIR

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \        
        libasound2-dev libatomic1 libpng-dev libsdl2-dev libsdl2-image-dev libsdl2-net-dev libopusfile-dev \
        libfluidsynth-dev libslirp-dev libspeexdsp-dev libxi-dev
RUN rm -rf /var/lib/apt/lists/*

COPY --from=builder ${BUILD_DIR} /usr

ENTRYPOINT ["/etc/init.d/init.sh"]
