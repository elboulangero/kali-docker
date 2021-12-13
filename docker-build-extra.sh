#!/bin/bash

set -e
set -u

IMAGE=$1
ARCHITECTURE=$2

CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE:-"kalilinux"}

case "$ARCHITECTURE" in
    amd64) platform="linux/amd64" ;;
    arm64) platform="linux/arm64" ;;
    armhf) platform="linux/arm/7" ;;
esac

case "$IMAGE" in
    kali)
        # Based on kali-last-release
        VERSIONFILE=kali-last-release-"$ARCHITECTURE".release.version
        VERSION=$(cat "$VERSIONFILE")
        ;;
    *)
        # Based on kali-rolling
        CONFFILE=kali-rolling-"$ARCHITECTURE".conf
        # shellcheck source=/dev/null
        VERSION=$(. ./"$CONFFILE"; echo "$VERSION")
        ;;
esac

TAG=$VERSION-$ARCHITECTURE

export DOCKER_BUILDKIT=1
docker build \
    --build-arg CI_REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"\
    --build-arg TAG="$TAG" \
    --file extra/"$IMAGE" \
    --platform "$platform" \
    --progress plain \
    --tag "$CI_REGISTRY_IMAGE/$IMAGE:$TAG" \
    .

if [ -n "${CI_JOB_TOKEN:-}" ]; then
    # Push the image so that subsequent jobs can fetch it
    docker push "$CI_REGISTRY_IMAGE/$IMAGE:$TAG"
fi

cat >"$IMAGE-$ARCHITECTURE".conf <<END
CI_REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"
TAG="$TAG"
VERSION="$VERSION"
END
