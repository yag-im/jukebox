#!/usr/bin/env bash

set -eu

if  [[ $EUID = 0 ]]
  then echo "Please do not run as root"
  exit
fi

# this script is called by root through the "su -" which preserves all env vars, including HOME for root, so need to
# redefine it for USERNAME
export HOME=/home/${USERNAME}

COLOR_BITS=${COLOR_BITS:-24}
STREAMD_MAX_RESTARTS=3
XORG_CONF_PATH=/home/$USERNAME/xorg.conf
RUN_MIDI_SYNTH=${RUN_MIDI_SYNTH:-false}

set_xorg_params() {
  local width=$1
  local height=$2
  local fps=$3
  local color_bits=$4

  # https://arachnoid.com/modelines/
  local modeline_values=""

  # 320x200 is not supported by Xorg?
  #if [[ "$width" -eq 320 ]] && [[ "$height" -eq 200 ]]; then
  #  modeline_values="4.19 320 304 328 336 200 201 204 208"
  if [[ "$width" -eq 640 ]] && [[ "$height" -eq 400 ]]; then
    modeline_values="19.52 640 648 712 784 400 401 404 415"
  elif [[ "$width" -eq 640 ]] && [[ "$height" -eq 480 ]]; then
    modeline_values="23.86 640 656 720 800 480 481 484 497"
  elif [[ "$width" -eq 800 ]] && [[ "$height" -eq 600 ]]; then
    modeline_values="38.22 800 832 912 1024 600 601 604 622"
  elif [[ "$width" -eq 1024 ]] && [[ "$height" -eq 768 ]]; then
    modeline_values="64.11 1024 1080 1184 1344 768 769 772 795"
  elif [[ "$width" -eq 1920 ]] && [[ "$height" -eq 1080 ]]; then
    modeline_values="172.80 1920 2040 2248 2576 1080 1081 1084 1118"
  else
    echo "Resolution not supported"
    return 1
  fi

  local mode="\"${width}x${height}_${fps}.00\""

  sed -i "s/{MONITOR_MODELINE}/$mode $modeline_values -HSync +Vsync/g" ${XORG_CONF_PATH}
  sed -i "s/{SCREEN_MODE}/$mode/g" ${XORG_CONF_PATH}
  sed -i "s/{COLOR_BITS}/$color_bits/g" ${XORG_CONF_PATH}
}

dbus-daemon --nofork --print-pid --config-file=/usr/share/dbus-1/session.conf --address=${DBUS_SESSION_BUS_ADDRESS} &

set_xorg_params ${SCREEN_WIDTH} ${SCREEN_HEIGHT} ${FPS} ${COLOR_BITS}

/usr/bin/X ${DISPLAY} +extension GLX +extension RANDR +extension RENDER +extension MIT-SHM -config ${XORG_CONF_PATH} &
until timeout 1s xset q &>/dev/null; do
  echo "waiting for the X server at DISPLAY ${DISPLAY}..."
  sleep 1
done

/usr/bin/pulseaudio --disallow-module-loading --log-level=2 --disallow-exit --exit-idle-time=-1 --high-priority=yes --realtime=yes &

# check Modeline and Modes in xorg.conf
# xrandr --output DUMMY0 --mode "${SCREEN_WIDTH}x${SCREEN_HEIGHT}_${FPS}.00"

/usr/bin/openbox --config-file /home/${USERNAME}/openbox.xml &
# do not remove this sleep! openbox must start before we can run our app
sleep 1

if [ "$RUN_MIDI_SYNTH" = true ]; then
  # TODO: using "-a pulseaudio" produces distorted sound
  fluidsynth -l -s -i -a alsa -m alsa_seq -g 1 -o midi.autoconnect=1 /usr/share/sounds/sf2/default-GM.sf2 &
fi

# Commands below run app and streamd.
# Whenever app exits - main script should exit too.
# When streamd exits - main script should exit only if exit status was 0 and retry N times if it wasn't.
# Non-zero streamd exit status comes from the restart_streamd.sh script (e.g. on a container resume operation).

# /opt/yag/ is a mounted folder with app files
/opt/yag/run.sh &
# firefox -new-tab https://youtube.com &
run_app_pid=$!

function run_streamd {
  # restart streamd if it fails and break only when it returns 0 (success)
  i=0
  while [ $i -lt $STREAMD_MAX_RESTARTS ]; do
    set -o allexport
      source /home/${USERNAME}/ws.env
    set +o allexport
    if ! streamd; then 
      sleep 3
      let i=i+1
    else
      break
    fi
  done
  trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
  exit 0
}

sleep 1

# these variables may change after e.g. unpause() call, so they should be re-exported in a loop
echo -e "WS_CONN_ID=$WS_CONN_ID\nWS_CONSUMER_ID=$WS_CONSUMER_ID" > /home/${USERNAME}/ws.env

run_streamd &

wait $run_app_pid

echo "app has exited gracefully"

exit 0
