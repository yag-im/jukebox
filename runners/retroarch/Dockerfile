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
    && 7z x RetroArch.7z -o${BUILD_DIR}

RUN wget https://buildbot.libretro.com/stable/${RUNNER_VER}/linux/x86_64/RetroArch_cores.7z \
    && 7z x RetroArch_cores.7z -o${BUILD_DIR}

# Philips CD-I origin: https://archive.org/download/RetroarchSystemFiles/Retroarch-System/
RUN wget "https://cdn.yag.im/runners/src/retroarch/Philips+-+CDi+(SAME+CDi).zip" \
    && unzip Philips+-+CDi+\(SAME+CDi\).zip -d ${BUILD_DIR}/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch/system

# Sega CD BIOSes origin: https://github.com/groenator/retroarch_system/tree/libretro/Sega%20-%20Mega%20CD%20-%20Sega%20CD
RUN wget -P ${BUILD_DIR}/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch/system \
    "https://raw.githubusercontent.com/groenator/retroarch_system/libretro/Sega%20-%20Mega%20CD%20-%20Sega%20CD/bios_CD_E.bin" \
    "https://raw.githubusercontent.com/groenator/retroarch_system/libretro/Sega%20-%20Mega%20CD%20-%20Sega%20CD/bios_CD_J.bin" \
    "https://raw.githubusercontent.com/groenator/retroarch_system/libretro/Sega%20-%20Mega%20CD%20-%20Sega%20CD/bios_CD_U.bin"

# Commodore Amiga Kickstart ROMs for the PUAE core
RUN wget -O ${BUILD_DIR}/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch/system/kick40068.A1200 \
    "https://raw.githubusercontent.com/BatoceraPLUS/Batocera.PLUS-bios/main/Kickstart%20v3.1%20r40.68%20%281993%29%28Commodore%29%28A1200%29%5B%21%5D.rom" \
    && wget -O ${BUILD_DIR}/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch/system/kick37350.A600 \
    "https://raw.githubusercontent.com/BatoceraPLUS/Batocera.PLUS-bios/main/Kickstart%20v2.05%20r37.350%20%281992%29%28Commodore%29%28A600HD%29%5B%21%5D.rom" \
    && wget -O ${BUILD_DIR}/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch/system/kick34005.A500 \
    "https://raw.githubusercontent.com/BatoceraPLUS/Batocera.PLUS-bios/main/Kickstart%20v1.3%20r34.5%20%281987%29%28Commodore%29%28A500-A1000-A2000-CDTV%29%5B%21%5D.rom" \
    && printf '%s\n' \
        "646773759326fbac3b2311fd8c8793ee  ${BUILD_DIR}/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch/system/kick40068.A1200" \
        "465646c9b6729f77eea5314d1f057951  ${BUILD_DIR}/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch/system/kick37350.A600" \
        "82a21c1890cae844b3df741f2762d48d  ${BUILD_DIR}/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch/system/kick34005.A500" \
        | md5sum --check

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
    libgpg-error0
RUN rm -rf /var/lib/apt/lists/*

COPY --from=builder ${BUILD_DIR}/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config /home/${USERNAME}/.config
COPY --from=builder ${BUILD_DIR}/RetroArch-Linux-x86_64/squashfs-root /opt/retroarch
COPY files/retroarch.cfg /home/${USERNAME}/.config/retroarch/retroarch.cfg

# Genesis Plus GX
# disable auto game focus so keyboard-to-RetroPad mapping works (genesis_plus_gx doesn't handle raw keyboard input)
COPY ["files/genesis_plus_gx/Genesis Plus GX.cfg", "/home/${USERNAME}/.config/retroarch/config/Genesis Plus GX/Genesis Plus GX.cfg"]
# use 3-button MD pad (safer default; 6-button breaks some Sega CD games)
COPY ["files/genesis_plus_gx/Genesis Plus GX.rmp", "/home/${USERNAME}/.config/retroarch/config/remaps/Genesis Plus GX/Genesis Plus GX.rmp"]

# PUAE (Commodore Amiga)
COPY files/puae/PUAE.opt /home/${USERNAME}/.config/retroarch/config/PUAE/PUAE.opt

# SAME_CDI
# SAME_CDI.opt: "same_cdi_mouse_enable" enabled and "input_exit_emulator" set to "nul"
COPY files/same_cdi/SAME_CDI.opt /home/${USERNAME}/.config/retroarch/config/SAME_CDI/SAME_CDI.opt
COPY files/same_cdi/cdimono1.cfg /home/${USERNAME}/.config/retroarch/saves/SAME_CDI/same_cdi/cfg/cdimono1.cfg
# default.cfg: disabling ESC and TAB hot keys
COPY files/same_cdi/default.cfg /home/${USERNAME}/.config/retroarch/saves/SAME_CDI/same_cdi/cfg/default.cfg

RUN ln -s /opt/retroarch/AppRun /usr/bin/retroarch

RUN mkdir -p /home/${USERNAME}/.config/retroarch/logs \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.config/retroarch

ENTRYPOINT ["/etc/init.d/init.sh"]
