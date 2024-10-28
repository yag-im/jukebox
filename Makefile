ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SHELL := /bin/bash

include envs/build.env
include envs/run.env
export

ECR_REPO := $(AWS_ACCOUNT_ID_INFRA).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com/$(AWS_ECR_REPO)

DOCKER_BASE_IMAGE := $(WINDOW_SYSTEM)_$(VIDEO_ENC)
DOCKER_DOSBOX_IMAGE := $(DOCKER_BASE_IMAGE)_dosbox_$(DOSBOX_VER)_$(DOCKER_IMAGE_REV_TAG)
DOCKER_DOSBOX_STAGING_IMAGE := $(DOCKER_BASE_IMAGE)_dosbox-staging_$(DOSBOX_STAGING_VER)_$(DOCKER_IMAGE_REV_TAG)
DOCKER_DOSBOX_X_IMAGE := $(DOCKER_BASE_IMAGE)_dosbox-x_$(DOSBOX_X_VER)_$(DOCKER_IMAGE_REV_TAG)
DOCKER_SCUMMVM_IMAGE := $(DOCKER_BASE_IMAGE)_scummvm_$(SCUMMVM_VER)_$(DOCKER_IMAGE_REV_TAG)
DOCKER_WINE_IMAGE := $(DOCKER_BASE_IMAGE)_wine_$(WINE_VER)_$(DOCKER_IMAGE_REV_TAG)

DOCKER_BUILDER_BASE_IMAGE := $(DOCKER_GENESIS_IMAGE)
DOCKER_NETWORK := host
RND_PREFIX := $(shell LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10)

.PHONY: help
help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: build-base 
build-base: ## Build base jukebox image
	docker build \
		-t $(DOCKER_BASE_IMAGE) \
		--progress plain \
		--build-arg BUILDER_BASE_IMAGE=$(DOCKER_BUILDER_BASE_IMAGE) \
		--build-arg RUNNER_BASE_IMAGE=$(DOCKER_BUILDER_BASE_IMAGE) \
		--build-arg USERNAME=$(USERNAME) \
		--build-arg VIDEO_ENC=$(VIDEO_ENC) \
		--build-arg WINDOW_SYSTEM=$(WINDOW_SYSTEM) \
		-f runners/base/$(WINDOW_SYSTEM)/$(VIDEO_ENC)/Dockerfile \
		runners/base \
	#&& $(MAKE) publish-image DOCKER_IMAGE=$(DOCKER_BASE_IMAGE))

.PHONY: build-dosbox-staging
build-dosbox-staging: ## Build dosbox-staging jukebox image
	$(MAKE) build-base \
	&& docker build \
		-t $(DOCKER_DOSBOX_STAGING_IMAGE) \
		--progress plain \
		--build-arg BUILDER_BASE_IMAGE=$(DOCKER_BUILDER_BASE_IMAGE) \
		--build-arg RUNNER_BASE_IMAGE=$(DOCKER_BASE_IMAGE) \
		--build-arg DOSBOX_STAGING_VER=$(DOSBOX_STAGING_VER) \
		-f runners/dosbox-staging/Dockerfile \
		runners/dosbox-staging \
	#&& $(MAKE) publish-image DOCKER_IMAGE=$(DOCKER_DOSBOX_STAGING_IMAGE)

.PHONY: build-dosbox-x
build-dosbox-x: ## Build dosbox-x jukebox image
	$(MAKE) build-base \
	&& docker build \
		-t $(DOCKER_DOSBOX_X_IMAGE) \
		--progress plain \
		--build-arg BUILDER_BASE_IMAGE=$(DOCKER_BUILDER_BASE_IMAGE) \
		--build-arg RUNNER_BASE_IMAGE=$(DOCKER_BASE_IMAGE) \
		--build-arg DOSBOX_X_VER=$(DOSBOX_X_VER) \
		-f runners/dosbox-x/Dockerfile \
		runners/dosbox-x \
	#&& $(MAKE) publish-image DOCKER_IMAGE=$(DOCKER_DOSBOX_X_IMAGE)

.PHONY: build-dosbox
build-dosbox: ## Build dosbox jukebox image
	$(MAKE) build-base \
	&& docker build \
		-t $(DOCKER_DOSBOX_IMAGE) \
		--progress plain \
		--build-arg RUNNER_BASE_IMAGE=$(DOCKER_BASE_IMAGE) \
		--build-arg DOSBOX_VER=$(DOSBOX_VER) \
		-f runners/dosbox/Dockerfile \
		runners/dosbox \
	#&& $(MAKE) publish-image DOCKER_IMAGE=$(DOCKER_DOSBOX_IMAGE)

.PHONY: build-scummvm
build-scummvm: ## Build scummvm jukebox image
	$(MAKE) build-base \
	&& docker build \
		-t $(DOCKER_SCUMMVM_IMAGE) \
		--progress plain \
		--build-arg BUILDER_BASE_IMAGE=$(DOCKER_BUILDER_BASE_IMAGE) \
		--build-arg RUNNER_BASE_IMAGE=$(DOCKER_BASE_IMAGE) \
		--build-arg SCUMMVM_VER=$(SCUMMVM_VER) \
		-f runners/scummvm/Dockerfile \
		runners/scummvm \
	#&& $(MAKE) publish-image DOCKER_IMAGE=$(DOCKER_SCUMMVM_IMAGE)

.PHONY: build-wine
build-wine: ## Build wine jukebox image
	$(MAKE) build-base \
	&& docker build \
		-t $(DOCKER_WINE_IMAGE) \
		--progress plain \
		--build-arg BUILDER_BASE_IMAGE=$(DOCKER_BUILDER_BASE_IMAGE) \
		--build-arg RUNNER_BASE_IMAGE=$(DOCKER_BASE_IMAGE) \
		--build-arg DEBIAN_VER=$(DEBIAN_VER) \
		--build-arg WINE_BRANCH=$(WINE_BRANCH) \
		--build-arg WINE_VER=$(WINE_VER) \
		-f runners/wine/Dockerfile \
		runners/wine \
	#&& $(MAKE) publish-image DOCKER_IMAGE=$(DOCKER_WINE_IMAGE)

.PHONY: build-all ## Build all jukebox images
build-all:
	$(MAKE) build-wine
	$(MAKE) build-scummvm
	$(MAKE) build-dosbox
	$(MAKE) build-dosbox-x
	$(MAKE) build-dosbox-staging

.PHONY: run-jukebox
run-jukebox:
	@if [ "$(VIDEO_ENC)" = "cpu" ]; then \
		docker run \
			-it \
			--rm \
			--name=$(DOCKER_RUN_NAME) \
			--network=$(DOCKER_NETWORK) \
			--env-file=envs/run.env \
			--env-file=envs/secret.env \
			--device=/dev/snd/seq:/dev/snd/seq \
			--memory=104857600 \
			--cpus=1 \
			--cpuset-cpus="$(STREAM_WORKER_NUM)" \
			--volume=$(YAG_VOLUME):/opt/yag \
			$(DOCKER_IMAGE); \
	elif [ "$(VIDEO_ENC)" = "gpu-nvidia" ]; then \
		docker run \
			-it \
			--rm \
			--name=$(DOCKER_RUN_NAME) \
			--network=$(DOCKER_NETWORK) \
			--env-file=envs/run.env \
			--env-file=envs/secret.env \
			--device=/dev/snd/seq:/dev/snd/seq \
			--shm-size="2g" \
			--cpuset-cpus="$(STREAM_WORKER_NUM)" \
			--env NVIDIA_DRIVER_CAPABILITIES=all \
			--gpus=all \
			--volume=$(YAG_VOLUME):/opt/yag \
			$(DOCKER_IMAGE); \
	elif [ "$(VIDEO_ENC)" = "gpu-intel" ]; then \
		docker run \
			-it \
			--rm \
			--name=$(DOCKER_RUN_NAME) \
			--network=$(DOCKER_NETWORK) \
			--env-file=envs/run.env \
			--env-file=envs/secret.env \
			--device=/dev/dri/renderD129 \
			--device=/dev/dri/card1 \
			--device=/dev/snd/seq \
			--shm-size="2g" \
			--cpuset-cpus="$(STREAM_WORKER_NUM)" \
			--volume=$(YAG_VOLUME):/opt/yag \
			$(DOCKER_IMAGE); \
	else \
		echo 1>&2 "invalid VIDEO_ENC value"; \
	fi

.PHONY: run-base
run-base: ## Run base (available only for debugging purposes)
	$(MAKE) run-jukebox \
		DOCKER_RUN_NAME=$(DOCKER_BASE_IMAGE)-$(STREAM_WORKER_NUM) \
		DOCKER_IMAGE=$(DOCKER_BASE_IMAGE) \
		YAG_VOLUME=$(YAG_VOLUME)

.PHONY: run-dosbox-staging
run-dosbox-staging: ## Run dosbox-staging jukebox
	$(MAKE) run-jukebox \
		DOCKER_RUN_NAME=$(DOCKER_DOSBOX_STAGING_IMAGE)-$(STREAM_WORKER_NUM) \
		DOCKER_IMAGE=$(DOCKER_DOSBOX_STAGING_IMAGE) \
		YAG_VOLUME=$(YAG_VOLUME)

.PHONY: run-dosbox-x
run-dosbox-x: ## Run dosbox-x jukebox
	$(MAKE) run-jukebox \
		DOCKER_RUN_NAME=$(DOCKER_DOSBOX_X_IMAGE)-$(STREAM_WORKER_NUM) \
		DOCKER_IMAGE=$(DOCKER_DOSBOX_X_IMAGE) \
		YAG_VOLUME=$(YAG_VOLUME)

.PHONY: run-scummvm
run-scummvm: ## Run scummvm jukebox
	$(MAKE) run-jukebox \
		DOCKER_RUN_NAME=$(DOCKER_SCUMMVM_IMAGE)-$(STREAM_WORKER_NUM) \
		DOCKER_IMAGE=$(DOCKER_SCUMMVM_IMAGE) \
		YAG_VOLUME=$(YAG_VOLUME)

.PHONY: run-wine
run-wine: ## Run wine jukebox
	$(MAKE) run-jukebox \
		DOCKER_RUN_NAME=$(DOCKER_WINE_IMAGE)-$(STREAM_WORKER_NUM) \
		DOCKER_IMAGE=$(DOCKER_WINE_IMAGE) \
		YAG_VOLUME=$(YAG_VOLUME)

.PHONY: publish-image
publish-image: ## publish docker image
	docker image tag $(DOCKER_IMAGE) $(ECR_REPO):$(DOCKER_IMAGE)
	AWS_PROFILE=$(AWS_ECR_PROFILE) docker push $(ECR_REPO):$(DOCKER_IMAGE)

.PHONY: publish-all-latest
publish-all-latest:
	${MAKE} publish-image DOCKER_IMAGE=${DOCKER_DOSBOX_IMAGE}
	${MAKE} publish-image DOCKER_IMAGE=${DOCKER_DOSBOX_STAGING_IMAGE}
	${MAKE} publish-image DOCKER_IMAGE=${DOCKER_DOSBOX_X_IMAGE}
	${MAKE} publish-image DOCKER_IMAGE=${DOCKER_SCUMMVM_IMAGE}
	${MAKE} publish-image DOCKER_IMAGE=${DOCKER_WINE_IMAGE}
