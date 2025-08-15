ARG BASE_IMAGE

FROM ${BASE_IMAGE} AS runner

ENV DEBIAN_FRONTEND=noninteractive

ARG RUNNER_VER
ARG RUNNER_VER_UBUNTU_PREFIX=-5build2
ARG RUNNER_VER_DEBIAN_PREFIX=-5+b1

# dosbox runner

# RUN apt-get update
# RUN apt list -a dosbox

# TODO: moving "+b1" prefix into the RUNNER_VER definition breaks docker tag naming rules ("plus" is a restricted character)
RUN OS_RELEASE_ID=$(source /etc/os-release && echo "$ID") \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        dosbox=${RUNNER_VER}$(if [ "${OS_RELEASE_ID}" = "ubuntu" ]; then echo "${RUNNER_VER_UBUNTU_PREFIX}"; elif [ "${OS_RELEASE_ID}" = "debian" ]; then echo "${RUNNER_VER_DEBIAN_PREFIX}"; fi)
RUN rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/etc/init.d/init.sh"]
