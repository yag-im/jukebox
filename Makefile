ROOT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
SHELL := /bin/bash

include envs/build.env
include envs/run.env
export

DOCKER_BASE_IMAGE_PREFIX := $(WINDOW_SYSTEM)_$(VIDEO_ENC)
DOCKER_BASE_IMAGE_TAG := $(DOCKER_BASE_IMAGE_PREFIX)_base
DOCKER_DOSBOX_IMAGE := $(DOCKER_BASE_IMAGE_PREFIX)_dosbox:$(DOSBOX_VER)
DOCKER_DOSBOX_STAGING_IMAGE := $(DOCKER_BASE_IMAGE_PREFIX)_dosbox-staging:$(DOSBOX_STAGING_VER)
DOCKER_DOSBOX_X_IMAGE := $(DOCKER_BASE_IMAGE_PREFIX)_dosbox-x:$(DOSBOX_X_VER)
DOCKER_RETROARCH_IMAGE := $(DOCKER_BASE_IMAGE_PREFIX)_retroarch:$(RETROARCH_VER)
DOCKER_SCUMMVM_IMAGE := $(DOCKER_BASE_IMAGE_PREFIX)_scummvm:$(SCUMMVM_VER)
DOCKER_WINE_IMAGE := $(DOCKER_BASE_IMAGE_PREFIX)_wine:$(WINE_VER)

DOCKER_NETWORK := host
RND_PREFIX := $(shell LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10)

ifeq ($(VIDEO_ENC),gpu-nvidia)
    DOCKER_GENESIS_IMAGE := $(NVIDIA_DOCKER_GENESIS_IMAGE)
endif

.PHONY: help
help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: build-base 
build-base: ## Build base jukebox image
	@if [ "$(VIDEO_ENC)" = "gpu-nvidia" ]; then \
		EXTRA_ARGS="\
			--build-arg CUDA_VER_MAJOR=$(NVIDIA_CUDA_VER_MAJOR) \
			--build-arg CUDA_VER_MINOR=$(NVIDIA_CUDA_VER_MINOR) \
		"; \
	else \
		EXTRA_ARGS=""; \
	fi; \
	docker build \
		-t $(DOCKER_BASE_IMAGE_TAG) \
		--progress plain \
		--build-arg BASE_IMAGE=$(DOCKER_GENESIS_IMAGE) \
		--build-arg USERNAME=$(USERNAME) \
		--build-arg VIDEO_ENC=$(VIDEO_ENC) \
		--build-arg WINDOW_SYSTEM=$(WINDOW_SYSTEM) \
		--build-arg STREAMD_LOG_LEVEL=$(STREAMD_LOG_LEVEL) \
		$$EXTRA_ARGS \
		-f runners/base/$(WINDOW_SYSTEM)/$(VIDEO_ENC)/Dockerfile \
		runners/base

.PHONY: build-dosbox-staging
build-dosbox-staging: ## Build dosbox-staging jukebox image
	$(MAKE) build-base \
	&& docker build \
		-t $(DOCKER_DOSBOX_STAGING_IMAGE) \
		--progress plain \
		--build-arg BASE_IMAGE=$(DOCKER_BASE_IMAGE_TAG) \
		--build-arg RUNNER_VER=$(DOSBOX_STAGING_VER) \
		-f runners/dosbox-staging/Dockerfile \
		runners/dosbox-staging

.PHONY: build-dosbox-x
build-dosbox-x: ## Build dosbox-x jukebox image
	$(MAKE) build-base \
	&& docker build \
		-t $(DOCKER_DOSBOX_X_IMAGE) \
		--progress plain \
		--build-arg BASE_IMAGE=$(DOCKER_BASE_IMAGE_TAG) \
		--build-arg RUNNER_VER=$(DOSBOX_X_VER) \
		-f runners/dosbox-x/Dockerfile \
		runners/dosbox-x

.PHONY: build-dosbox
build-dosbox: ## Build dosbox jukebox image
	$(MAKE) build-base \
	&& docker build \
		-t $(DOCKER_DOSBOX_IMAGE) \
		--progress plain \
		--build-arg BASE_IMAGE=$(DOCKER_BASE_IMAGE_TAG) \
		--build-arg RUNNER_VER=$(DOSBOX_VER) \
		-f runners/dosbox/Dockerfile \
		runners/dosbox

.PHONY: build-scummvm
build-scummvm: ## Build scummvm jukebox image
	$(MAKE) build-base \
	&& docker build \
		-t $(DOCKER_SCUMMVM_IMAGE) \
		--progress plain \
		--build-arg BASE_IMAGE=$(DOCKER_BASE_IMAGE_TAG) \
		--build-arg RUNNER_VER=$(SCUMMVM_VER) \
		-f runners/scummvm/Dockerfile \
		runners/scummvm

.PHONY: build-wine
build-wine: ## Build wine jukebox image
	$(MAKE) build-base \
	&& docker build \
		-t $(DOCKER_WINE_IMAGE) \
		--progress plain \
		--build-arg BASE_IMAGE=$(DOCKER_BASE_IMAGE_TAG) \
		--build-arg RUNNER_BRANCH=$(WINE_BRANCH) \
		--build-arg RUNNER_VER=$(WINE_VER) \
		-f runners/wine/Dockerfile \
		runners/wine

.PHONY: build-retroarch
build-retroarch: ## Build retroarch jukebox image
	$(MAKE) build-base \
	&& docker build \
		-t $(DOCKER_RETROARCH_IMAGE) \
		--progress plain \
		--build-arg BASE_IMAGE=$(DOCKER_BASE_IMAGE_TAG) \
		--build-arg RUNNER_VER=$(RETROARCH_VER) \
		--build-arg USERNAME=$(USERNAME) \
		-f runners/retroarch/Dockerfile \
		runners/retroarch

.PHONY: build-all ## Build all jukebox images
build-all:
	$(MAKE) build-wine
	$(MAKE) build-scummvm
	$(MAKE) build-dosbox
	$(MAKE) build-dosbox-x
	$(MAKE) build-dosbox-staging
	$(MAKE) build-retroarch

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
			--device=/dev/dri/renderD128 \
			--device=/dev/dri/card0 \
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
		DOCKER_RUN_NAME=$(DOCKER_BASE_IMAGE_PREFIX)-$(STREAM_WORKER_NUM) \
		DOCKER_IMAGE=$(DOCKER_BASE_IMAGE_TAG) \
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

.PHONY: run-retroarch
run-retroarch: ## Run retroarch jukebox
	$(MAKE) run-retroarch \
		DOCKER_RUN_NAME=$(DOCKER_RETROARCH_IMAGE)-$(STREAM_WORKER_NUM) \
		DOCKER_IMAGE=$(DOCKER_RETROARCH_IMAGE) \
		YAG_VOLUME=$(YAG_VOLUME)