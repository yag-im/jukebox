ARG BASE_IMAGE

FROM ${BASE_IMAGE} AS runner

ENV DEBIAN_FRONTEND=noninteractive

ARG OS_TYPE
ARG RUNNER_VER
ARG RUNNER_VER_UBUNTU_PREFIX=-5build2
ARG RUNNER_VER_DEBIAN_PREFIX=-4+b1

# dosbox runner

RUN apt-get update
RUN apt list -a dosbox

# TODO: moving "+b1" prefix into the RUNNER_VER definition breaks docker tag naming rules ("plus" is a restricted character)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        dosbox=${RUNNER_VER}$(if [ "${OS_TYPE}" = "ubuntu" ]; then echo "${RUNNER_VER_UBUNTU_PREFIX}"; elif [ "${OS_TYPE}" = "debian" ]; then echo "${RUNNER_VER_DEBIAN_PREFIX}"; fi)
RUN rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/etc/init.d/init.sh"]
