#!/usr/bin/env bash

set -u

if  [[ $EUID > 0 ]]
  then echo "Please run as root"
  exit
fi

# change dri devices permissions first
FILES=$(find /dev/dri -type c -print 2>/dev/null)
for i in $FILES
do
    VIDEO_GID=$(stat -c '%g' "${i}")
    VIDEO_UID=$(stat -c '%u' "${i}")
    # check if user matches device
    if id -u ${USERNAME} | grep -qw "${VIDEO_UID}"; then
        echo "**** permissions for ${i} are good ****"
    else
        # check if group matches and that device has group rw
        if id -G ${USERNAME} | grep -qw "${VIDEO_GID}" && [ $(stat -c '%A' "${i}" | cut -b 5,6) = "rw" ]; then
            echo "**** permissions for ${i} are good ****"
        # check if device needs to be added to video group
        elif ! id -G ${USERNAME} | grep -qw "${VIDEO_GID}"; then
            # check if video group needs to be created
            VIDEO_NAME=$(getent group "${VIDEO_GID}" | awk -F: '{print $1}')
            if [ -z "${VIDEO_NAME}" ]; then
                VIDEO_NAME="video$(head /dev/urandom | tr -dc 'a-z0-9' | head -c4)"
                groupadd "${VIDEO_NAME}"
                groupmod -g "${VIDEO_GID}" "${VIDEO_NAME}"
                echo "**** creating video group ${VIDEO_NAME} with id ${VIDEO_GID} ****"
            fi
            echo "**** adding ${i} to video group ${VIDEO_NAME} with id ${VIDEO_GID} ****"
            usermod -a -G "${VIDEO_NAME}" ${USERNAME}
        fi
        # check if device has group rw
        if [ $(stat -c '%A' "${i}" | cut -b 5,6) != "rw" ]; then
            echo -e "**** The device ${i} does not have group read/write permissions, attempting to fix inside the container. ****"
            chmod g+rw "${i}"
        fi
    fi
done

# dbus part requiring root permissions, the rest of dbus is started under the ${USERNAME} from supervisord
if [ ! -d /var/run/dbus ]; then
  mkdir -p /var/run/dbus
fi
if [ -f /var/run/dbus/pid ]; then
  rm -f /var/run/dbus/pid
fi

su --preserve-environment "${USERNAME}" <<EOF

export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_UID/dbus

# intel
export LIBVA_DRIVER_NAME=iHD

/home/${USERNAME}/run_ws.sh

echo "run_ws.sh execution has been completed"

EOF

echo "finished execution, exiting and closing container"

# su --preserve-environment "${USERNAME}" -c "/home/${USERNAME}/run_ws.sh"
