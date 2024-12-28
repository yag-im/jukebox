#!/usr/bin/env bash

set -o allexport
    source ../envs/build.env
set +o allexport

DOCKER_REPO=ghcr.io/yag-im/jukebox

pull_local_all() {
    VIDEO_ENC=cpu
    ssh -i ~/.vagrant.d/insecure_private_keys/vagrant.key.rsa vagrant@127.0.0.1 -p 2201 \
        "docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_dosbox:${DOSBOX_VER} \
            && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_dosbox-x:${DOSBOX_X_VER} \
            && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_dosbox-staging:${DOSBOX_STAGING_VER} \
            && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_scummvm:${SCUMMVM_VER} \
            && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_wine:${WINE_VER} \
        "
    ssh -i ~/.vagrant.d/insecure_private_keys/vagrant.key.rsa vagrant@127.0.0.1 -p 2202 \
        "docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_dosbox:${DOSBOX_VER} \
            && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_dosbox-x:${DOSBOX_X_VER} \
            && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_dosbox-staging:${DOSBOX_STAGING_VER} \
            && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_scummvm:${SCUMMVM_VER} \
            && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_wine:${WINE_VER} \
        "
}

pull_dev_all() {
    VIDEO_ENC=gpu-intel
    ssh -i /ara/devel/acme/yag/infra/tofu/modules/bastion/files/secrets/dev/id_ed25519 -o ProxyCommand="ssh -p 2207 -W %h:%p infra@bastion.dev.yag.im" debian@192.168.13.2 \
        "docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_dosbox:${DOSBOX_VER} \
            && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_dosbox-x:${DOSBOX_X_VER} \
            && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_dosbox-staging:${DOSBOX_STAGING_VER} \
            && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_scummvm:${SCUMMVM_VER} \
            && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_wine:${WINE_VER} \
        "
}

pull_prod_all() {
    VIDEO_ENC=gpu-intel
    HOST_IPS=("192.168.12.2" "192.168.13.2")
    for host_ip in "${HOST_IPS[@]}"; do
        ssh -i /ara/devel/acme/yag/infra/tofu/modules/bastion/files/secrets/prod/id_ed25519 -o ProxyCommand="ssh -p 2207 -W %h:%p infra@bastion.yag.im" debian@$host_ip \
        "docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_dosbox:${DOSBOX_VER} \
            && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_dosbox-x:${DOSBOX_X_VER} \
            && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_dosbox-staging:${DOSBOX_STAGING_VER} \
            && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_scummvm:${SCUMMVM_VER} \
            && docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_wine:${WINE_VER} \
        "
    done
}

# pull_local_all

# note: vagrant VM nodes support only cpu encoder
# ssh -i ~/.vagrant.d/insecure_private_keys/vagrant.key.rsa vagrant@127.0.0.1 -p 2201 "AWS_PROFILE=ecr-ro docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_cpu_wine:${WINE_VER}"
# ssh -i ~/.vagrant.d/insecure_private_keys/vagrant.key.rsa vagrant@127.0.0.1 -p 2202 "AWS_PROFILE=ecr-ro docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_cpu_wine:${WINE_VER}"

# pull_dev_all
# ssh -i /ara/devel/acme/yag/infra/tofu/modules/bastion/files/secrets/dev/id_ed25519 -o ProxyCommand="ssh -p 2207 -W %h:%p infra@bastion.dev.yag.im" debian@192.168.13.2 "AWS_PROFILE=ecr-ro docker pull $DOCKER_REPO/${WINDOW_SYSTEM}_${VIDEO_ENC}_dosbox-x:${DOSBOX_X_VER}"

pull_prod_all
