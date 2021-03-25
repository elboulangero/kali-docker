#!/bin/bash

set -e

DISTRO=$1
ARCHITECTURE=$2

CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE:-kalilinux}

# Retrieve variables from former docker-build.sh
. ./"$ARCHITECTURE"-"$DISTRO".conf

case "$ARCHITECTURE" in
    amd64) platform="linux/amd64"; machine="x86_64" ;;
    arm64) platform="linux/arm64"; machine="aarch64" ;;
    armhf) platform="linux/arm/7"; machine="armv7l" ;;
esac

if [ -n "$CI_JOB_TOKEN" ]; then
    docker pull --platform "$platform" "$CI_REGISTRY_IMAGE/$IMAGE:$VERSION"
fi

TEST_ARCH=$(docker run --rm "$CI_REGISTRY_IMAGE/$IMAGE:$VERSION" uname -m)
if [ "$machine" == "$TEST_ARCH" ]; then
    echo "OK: Architecture correct"
else
    echo "ERROR: Architecture incorrect"
    exit 1
fi
