#!/usr/bin/env bash

set -o allexport
    source ../envs/build.env
    source .env
set +o allexport

pull_docker_images() {
    docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_dosbox:${DOSBOX_VER} \
        && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_dosbox-x:${DOSBOX_X_VER} \
        && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_dosbox-staging:${DOSBOX_STAGING_VER} \
        && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_scummvm:${SCUMMVM_VER} \
        && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_wine:${WINE_VER}
}

pull_local_all() {
    pull_docker_images
}

pull_local_mk_all() {
    # note: vagrant VM nodes support only cpu encoder
    VIDEO_ENC=cpu
    PORTS=("2201" "2202")
    for port in "${PORTS[@]}"; do
        ssh -i ~/.vagrant.d/insecure_private_keys/vagrant.key.rsa vagrant@127.0.0.1 -p $port \
            "$(declare -f pull_docker_images); pull_docker_images"
    done
}

pull_cloud_dev_all() {
    HOST_IPS=("192.168.12.2" "192.168.13.2")
    for host_ip in "${HOST_IPS[@]}"; do
        ssh -i ${BASTION_SECRETS_DIR}/dev/id_ed25519 -o ProxyCommand="ssh -p 2207 -W %h:%p infra@bastion.dev.yag.im" debian@$host_ip \
            "$(declare -f pull_docker_images); pull_docker_images"
    done
}

pull_cloud_prod_all() {
    HOST_IPS=("192.168.12.2" "192.168.13.2")
    for host_ip in "${HOST_IPS[@]}"; do
        ssh -i ${BASTION_SECRETS_DIR}/prod/id_ed25519 -o ProxyCommand="ssh -p 2207 -W %h:%p infra@bastion.yag.im" debian@$host_ip \
            "$(declare -f pull_docker_images); pull_docker_images"
    done
}

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 {local_all|local_mk_all|cloud_dev_all|cloud_prod_all}"
    exit 1
fi

case $1 in
    local_all)
        pull_local_all
        ;;
    local_mk_all)
        pull_local_mk_all
        ;;
    cloud_dev_all)
        pull_cloud_dev_all
        ;;
    cloud_prod_all)
        pull_cloud_prod_all
        ;;
    *)
        echo "Invalid argument: $1"
        echo "Usage: $0 {local_all|local_mk_all|cloud_dev_all|cloud_prod_all}"
        exit 1
        ;;
esac
