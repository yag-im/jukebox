ARG BASE_IMAGE

# qemu runner
FROM ${BASE_IMAGE} AS runner
ARG BUILD_DIR
ARG USERNAME

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        qemu-system-gui \
        qemu-system-modules-spice \
        qemu-system-x86 \
        qemu-utils
RUN rm -rf /var/lib/apt/lists/*

RUN usermod -aG kvm $USERNAME

ENTRYPOINT ["/etc/init.d/init.sh"]
