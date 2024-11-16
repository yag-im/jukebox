ARG RUNNER_BASE_IMAGE

FROM ${RUNNER_BASE_IMAGE} AS runner

ENV DEBIAN_FRONTEND=noninteractive

ARG RUNNER_VER

# dosbox runner

# TODO: moving "+b1" prefix into the RUNNER_VER definition breaks docker tag naming rules (plus is a restricted character)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \        
        dosbox=${RUNNER_VER}+b1
RUN rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/etc/init.d/init.sh"]
