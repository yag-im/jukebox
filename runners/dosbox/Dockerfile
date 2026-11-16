ARG BASE_IMAGE

ARG PACKAGES_DIR=/tmp/packages

# dosbox binaries builder: rebuilds the distro source package (keeping distro patches) with our patches on top
FROM ${BASE_IMAGE} AS builder

ARG NUM_BUILD_WORKERS=8
ARG PACKAGES_DIR
ARG RUNNER_VER
# source package revisions (binary-only rebuild suffixes such as "+b1" don't exist for source packages)
ARG RUNNER_VER_UBUNTU_PREFIX=-5build2
ARG RUNNER_VER_DEBIAN_PREFIX=-5
ARG SRC_DIR=/tmp/src

ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/*.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        dpkg-dev

WORKDIR ${SRC_DIR}

# TODO: moving the revision prefix into the RUNNER_VER definition breaks docker tag naming rules ("plus" is a restricted character)
RUN export OS_RELEASE_ID=$( . /etc/os-release && echo "$ID") \
    && export SRC_VER=${RUNNER_VER}$(if [ "${OS_RELEASE_ID}" = "ubuntu" ]; then echo "${RUNNER_VER_UBUNTU_PREFIX}"; elif [ "${OS_RELEASE_ID}" = "debian" ]; then echo "${RUNNER_VER_DEBIAN_PREFIX}"; fi) \
    && apt-get build-dep -y --no-install-recommends dosbox=${SRC_VER} \
    && apt-get source dosbox=${SRC_VER}

# INT 33h/04h (set mouse position): ignore positions less than one mickey step away and keep the sub-pixel part
# otherwise, so games snapping/re-centring the pointer after each read don't lose small moves in one direction only
# (e.g. slow "down" moves stuck in strawberry magic)
COPY patches/*.patch .
RUN patch ./dosbox-${RUNNER_VER}/src/ints/mouse.cpp mouse.cpp.patch

RUN cd ./dosbox-${RUNNER_VER} \
    && DEB_BUILD_OPTIONS="parallel=${NUM_BUILD_WORKERS} nocheck" dpkg-buildpackage -b -uc -us \
    && mkdir -p ${PACKAGES_DIR} \
    && cp ../dosbox_*.deb ${PACKAGES_DIR}/

# dosbox runner
FROM ${BASE_IMAGE} AS runner

ARG PACKAGES_DIR

ENV DEBIAN_FRONTEND=noninteractive

COPY --from=builder ${PACKAGES_DIR} ${PACKAGES_DIR}

# hold the patched package so it doesn't get replaced by the distro one
RUN apt-get update \
    && apt-get install -y --no-install-recommends ${PACKAGES_DIR}/dosbox_*.deb \
    && apt-mark hold dosbox \
    && rm -rf ${PACKAGES_DIR} \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/etc/init.d/init.sh"]
