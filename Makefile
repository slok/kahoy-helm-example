
OSTYPE := $(shell uname)
VERSION ?= $(shell git describe --tags --always)


IMAGE_NAME := slok/kahoy-helm-example

DOCKER_RUN_CMD := docker run --env ostype=$(OSTYPE) -v ${PWD}:/src --rm ${IMAGE_NAME}
BUILD_IMAGE_CMD := IMAGE=${IMAGE_NAME} DOCKER_FILE_PATH=./Dockerfile VERSION=${VERSION} TAG_IMAGE_LATEST=true ./scripts/build-image.sh
PUBLISH_IMAGE_CMD := IMAGE=${IMAGE_NAME} VERSION=${VERSION} TAG_IMAGE_LATEST=true ./scripts/publish-image.sh


help: ## Show this help.
	@echo "Help"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[36m%-20s\033[93m %s\n", $$1, $$2}'

.PHONY: default
default: help

.PHONY: build-image
build-image: ## Builds docker image.
	@$(BUILD_IMAGE_CMD)

.PHONY: publish-image
publish-image: ## Publishes the production docker image.
	@$(PUBLISH_IMAGE_CMD)

.PHONY: gen
gen: ## Generates manifests.
	@$(DOCKER_RUN_CMD) /bin/sh -c './scripts/generate.sh'

.PHONY: dry-run-staging
dry-run-staging: gen ## Executes dry-run on staging env apps.
	ENVIRONMENT=staging MANIFESTS_PATH=./_gen/staging ./scripts/deploy.sh

.PHONY: dry-run-production
dry-run-production: gen ## Executes dry-run on prod env apps.
	ENVIRONMENT=production MANIFESTS_PATH=./_gen/production ./scripts/deploy.sh