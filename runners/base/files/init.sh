#!/usr/bin/env bash

set -u

if  [[ $EUID > 0 ]]
  then echo "Please run as root"
  exit
fi

# change mounted devices permissions first
DEVICES=$(find /dev/dri -type c -print 2>/dev/null || true)
[ -c /dev/kvm ] && DEVICES="$DEVICES /dev/kvm"

for i in $DEVICES; do
    DEV_GID=$(stat -c '%g' "${i}")
    DEV_UID=$(stat -c '%u' "${i}")
    DEV_MODE=$(stat -c '%A' "${i}" | cut -b 5,6)

    echo "Checking permissions for ${i}..."

    # check if user matches device owner
    if id -u "${USERNAME}" | grep -qw "${DEV_UID}"; then
        echo "**** permissions for ${i} are good (user owns device) ****"
        continue
    fi

    # check if group matches and device has group rw
    if id -G "${USERNAME}" | grep -qw "${DEV_GID}" && [ "${DEV_MODE}" = "rw" ]; then
        echo "**** permissions for ${i} are good (user in group with rw access) ****"
        continue
    fi

    # check if device group exists, create if missing
    DEV_GROUP=$(getent group "${DEV_GID}" | awk -F: '{print $1}')
    if ! id -G "${USERNAME}" | grep -qw "${DEV_GID}"; then
        if [ -z "${DEV_GROUP}" ]; then
            DEV_GROUP="devgrp$(head /dev/urandom | tr -dc 'a-z0-9' | head -c4)"
            groupadd "${DEV_GROUP}"
            groupmod -g "${DEV_GID}" "${DEV_GROUP}"
            echo "**** creating group ${DEV_GROUP} with id ${DEV_GID} ****"
        fi
        echo "**** adding ${USERNAME} to group ${DEV_GROUP} with id ${DEV_GID} ****"
        usermod -a -G "${DEV_GROUP}" "${USERNAME}"
    fi

    # ensure group has rw permissions
    if [ "${DEV_MODE}" != "rw" ]; then
        echo "**** ${i} missing group rw permissions, fixing... ****"
        chmod g+rw "${i}"
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
