#!/bin/bash
# vim: ai:ts=8:sw=8:noet
set -eufCo pipefail
export SHELLOPTS
IFS=$'\t\n'

command -v docker >/dev/null 2>&1 || { echo 'please install docker'; exit 1; }

[ -z "${VERSION:-}" ] && echo "VERSION env is required" && exit 1;
[ -z "${IMAGE:-}" ] && echo "IMAGE env is required" && exit 1;


echo "Pushing image ${IMAGE}:${VERSION}..."
docker push ${IMAGE}:${VERSION}

if [ ! -z ${TAG_IMAGE_LATEST} ]; then
    echo "Pushing image ${IMAGE}:latest..."
    docker push ${IMAGE}:latest
fi