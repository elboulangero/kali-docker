#!/bin/bash

set -e

DISTRO=$1
ARCHITECTURE=$2
TARBALL=$ARCHITECTURE.$DISTRO.tar.xz

CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE:-kalilinux}
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BUILD_VERSION=$(date -u +"%Y.%m.%d")
VCS_URL=$(git config --get remote.origin.url)
VCS_REF=$(git rev-parse --short HEAD)

case "$ARCHITECTURE" in
    amd64) platform="linux/amd64" ;;
    arm64) platform="linux/arm64" ;;
    armhf) platform="linux/arm/7" ;;
esac

case "$DISTRO" in
    kali-last-snapshot)
	IMAGE=kali
	VERSION=$(cat $ARCHITECTURE.$DISTRO.release.version)
	RELEASE_DESCRIPTION="$VERSION"
	;;
    *)
	IMAGE="$DISTRO"
	VERSION="$BUILD_VERSION"
	RELEASE_DESCRIPTION="$DISTRO"
	;;
esac

if [ -n "$CI_JOB_TOKEN" ]; then
    DOCKER_CLI_EXPERIMENTAL=enabled
    export DOCKER_CLI_EXPERIMENTAL
    DOCKER_BUILD="docker buildx build --output=type=image,push=false"
else
    DOCKER_BUILDKIT=1
    export DOCKER_BUILDKIT
    DOCKER_BUILD="docker build"
fi

TAG=$VERSION-$ARCHITECTURE

$DOCKER_BUILD \
    --build-arg TARBALL="$TARBALL" \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg VERSION="$VERSION" \
    --build-arg VCS_URL="$VCS_URL" \
    --build-arg VCS_REF="$VCS_REF" \
    --build-arg RELEASE_DESCRIPTION="$RELEASE_DESCRIPTION" \
    --platform "$platform" \
    --progress plain \
    --pull \
    --tag "$CI_REGISTRY_IMAGE/$IMAGE:$TAG" \
    .

if [ -n "$CI_JOB_TOKEN" ]; then
    # Push the image so that subsequent jobs can fetch it
    docker push "$CI_REGISTRY_IMAGE/$IMAGE:$TAG"
fi

cat >"$ARCHITECTURE-$DISTRO".conf <<END
CI_REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"
IMAGE="$IMAGE"
TAG="$TAG"
VERSION="$VERSION"
END
