#!/bin/bash

set -e
set -u

IMAGE=$1
ARCHITECTURE=$2

# Retrieve variables from former docker-build.sh
# shellcheck source=/dev/null
. ./"$IMAGE-$ARCHITECTURE".conf

case "$ARCHITECTURE" in
    amd64) platform="linux/amd64"; machine="x86_64" ;;
    arm64) platform="linux/arm64"; machine="aarch64" ;;
    armhf) platform="linux/arm/7"; machine="armv7l" ;;
esac

if [ -n "${CI_JOB_TOKEN:-}" ]; then
    docker pull --platform "$platform" "$CI_REGISTRY_IMAGE/$IMAGE:$TAG"
fi

TEST_ARCH=$(docker run --rm --platform "$platform" "$CI_REGISTRY_IMAGE/$IMAGE:$TAG" uname -m)
if [ "$machine" == "$TEST_ARCH" ]; then
    echo "OK: Architecture correct"
else
    echo >&2 "ERROR: Architecture incorrect"
    exit 1
fi
