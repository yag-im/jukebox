ARG BASE_IMAGE

ARG BUILD_DIR=/tmp/build

# retroarch builder
FROM ${BASE_IMAGE} AS builder

ARG BUILD_DIR
ARG NUM_BUILD_WORKERS=8
ARG RUNNER_VER
ARG SRC_DIR=/tmp/src
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        7zip \
        ca-certificates \
        unzip \
        wget
RUN rm -rf /var/lib/apt/lists/*

WORKDIR ${SRC_DIR}
RUN mkdir -p ${BUILD_DIR}

RUN wget https://buildbot.libretro.com/stable/${RUNNER_VER}/linux/x86_64/RetroArch.7z \
    && 7zz x RetroArch.7z -o${BUILD_DIR}

RUN wget https://buildbot.libretro.com/stable/${RUNNER_VER}/linux/x86_64/RetroArch_cores.7z \
    && 7zz x RetroArch_cores.7z -o${BUILD_DIR}

# Philips CD-I origin: https://archive.org/download/RetroarchSystemFiles/Retroarch-System/
RUN wget "https://cdn.yag.im/runners/src/retroarch/Philips+-+CDi+(SAME+CDi).zip" \
    && unzip Philips+-+CDi+\(SAME+CDi\).zip -d ${BUILD_DIR}/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch/system

# docker doesn't support AppImage-s, so extracting binaries (into squashfs-root)
WORKDIR ${BUILD_DIR}/RetroArch-Linux-x86_64
RUN chmod +x RetroArch-Linux-x86_64.AppImage \
    && ./RetroArch-Linux-x86_64.AppImage --appimage-extract

# retroarch runner
FROM ${BASE_IMAGE} AS runner
ARG BUILD_DIR
ARG USERNAME

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        vim
RUN rm -rf /var/lib/apt/lists/*

COPY --from=builder ${BUILD_DIR}/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config /home/${USERNAME}/.config
COPY --from=builder ${BUILD_DIR}/RetroArch-Linux-x86_64/squashfs-root /opt/retroarch
COPY files/retroarch.cfg /home/${USERNAME}/.config/retroarch/retroarch.cfg

# SAME_CDI.opt has "same_cdi_mouse_enable" enabled and input_exit_emulator set to "nul"
COPY files/same_cdi/SAME_CDI.opt /home/${USERNAME}/.config/retroarch/config/SAME_CDI/SAME_CDI.opt
COPY files/same_cdi/cdimono1.cfg /home/${USERNAME}/.config/retroarch/saves/SAME_CDI/same_cdi/cfg/cdimono1.cfg
# disabling ESC and TAB hot keys in default.cfg
COPY files/same_cdi/default.cfg /home/${USERNAME}/.config/retroarch/saves/SAME_CDI/same_cdi/cfg/default.cfg

RUN ln -s /opt/retroarch/AppRun /usr/bin/retroarch

RUN chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config/retroarch

ENTRYPOINT ["/etc/init.d/init.sh"]
