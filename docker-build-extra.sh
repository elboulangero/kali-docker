#!/bin/bash

set -e
set -u

DISTRO=$1
ARCHITECTURE=$2

CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE:-"kalilinux"}

# Build the same version as for kali-rolling
# shellcheck source=/dev/null
VERSION=$(. ./kali-rolling-"$ARCHITECTURE".conf; echo "$VERSION")
IMAGE=$DISTRO

case "$ARCHITECTURE" in
    amd64) platform="linux/amd64" ;;
    arm64) platform="linux/arm64" ;;
    armhf) platform="linux/arm/7" ;;
esac

TAG=$VERSION-$ARCHITECTURE

export DOCKER_BUILDKIT=1
docker build \
    --build-arg CI_REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"\
    --build-arg TAG="$TAG" \
    --file extra/"$IMAGE" \
    --platform "$platform" \
    --progress plain \
    --pull \
    --tag "$CI_REGISTRY_IMAGE/$IMAGE:$TAG" \
    .

if [ -n "${CI_JOB_TOKEN:-}" ]; then
    # Push the image so that subsequent jobs can fetch it
    docker push "$CI_REGISTRY_IMAGE/$IMAGE:$TAG"
fi

cat >"$DISTRO-$ARCHITECTURE".conf <<END
CI_REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"
IMAGE="$IMAGE"
TAG="$TAG"
VERSION="$VERSION"
END
