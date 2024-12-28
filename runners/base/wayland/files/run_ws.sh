#!/usr/bin/env bash

if  [[ $EUID = 0 ]]
  then echo "Please do not run as root"
  exit
fi

# this script is called by root through the "su -" which preserves all env vars, including HOME for root, so need to
# redefine it for USERNAME
export HOME=/home/${USERNAME}
export LABWC_DEBUG=${LABWC_DEBUG:-}
export PIPEWIRE_CONFIG_DIR=/usr/share/pipewire
export PIPEWIRE_MODULE_DIR=/usr/lib/x86_64-linux-gnu
export SDL_VIDEODRIVER=wayland
export SPA_PLUGIN_DIR=/usr/lib/x86_64-linux-gnu/spa-0.2
export WAYLAND_DISPLAY=wayland-0
export WIREPLUMBER_CONFIG_DIR=/usr/share/wireplumber
export WIREPLUMBER_DATA_DIR=/usr/share/wireplumber
# TODO: 0.4 shouldn't be hardcoded
export WIREPLUMBER_MODULE_DIR=/usr/lib/x86_64-linux-gnu/wireplumber-0.4
export WLR_BACKENDS=headless
export WLR_LIBINPUT_NO_DEVICES=1
export WLR_OUTPUT=HEADLESS-1
export WLR_RENDERER=gles2
export WLR_RENDER_DRM_DEVICE=/dev/dri/renderD${WLR_RENDER_DRM_DEVICE:-128}
export XDG_CONFIG_HOME=/usr/share
export XDG_CURRENT_DESKTOP=wlroots
export XDG_RUNTIME_DIR=/run/user/${USER_UID}
export XDPW_LOG_LEVEL=${XDPW_LOG_LEVEL:-ERROR}

CHECK_PERIOD=0.05
STREAMD_MAX_RESTARTS=100

dbus-daemon --nofork --print-pid --config-file=/usr/share/dbus-1/session.conf --address=${DBUS_SESSION_BUS_ADDRESS} &

labwc${LABWC_DEBUG} &

while [ ! -f ${XDG_RUNTIME_DIR}/wayland-0.lock ]
do
  sleep ${CHECK_PERIOD}
done

wlr-randr --output ${WLR_OUTPUT} --custom-mode ${SCREEN_WIDTH}x${SCREEN_HEIGHT} &

pipewire &

pipewire-pulse &

wireplumber &

while [ ! -f ${XDG_RUNTIME_DIR}/pipewire-0.lock ]
do
  sleep ${CHECK_PERIOD}
done

/usr/libexec/xdg-desktop-portal-wlr --replace --loglevel ${XDPW_LOG_LEVEL} &

# warning: disable CPU core binding for firefox as it requires more than 1 core for a smooth playback
# export MOZ_ENABLE_WAYLAND=1
# firefox -new-tab https://youtube.com &
/opt/yag/run.sh &

sleep 1

# restart streamd if it fails and break loop only when it returns 0 (success)
i=0
while [ $i -lt $STREAMD_MAX_RESTARTS ]; do
  set -o allexport
    source /home/${USERNAME}/ws.env
  set +o allexport
  streamd
  if [ $? -eq 0 ]; then
    break
  else
    sleep 3
    let i=i+1
  fi
done
