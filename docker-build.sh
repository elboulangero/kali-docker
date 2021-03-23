#!/bin/bash

set -e

DISTRO=$1
ARCHITECTURE=$2
TARBALL=$ARCHITECTURE.$DISTRO.tar.xz

CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE:-kalilinux}
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BUILD_VERSION=$(date -u +"%Y-%m-%d")
VCS_URL=$(git config --get remote.origin.url)
VCS_REF=$(git rev-parse --short HEAD)

case "$ARCHITECTURE" in
    amd64) plataform="linux/amd64" ;;
    arm64) plataform="linux/arm64" ;;
    armhf) plataform="linux/arm/7" ;;
esac

case "$DISTRO" in
    kali-last-snapshot)
	IMAGE=kali
	VERSION=$(cat ./release.version)
	RELEASE_DESCRIPTION="$VERSION"
	;;
    *)
	IMAGE="$DISTRO"
	VERSION="$BUILD_VERSION"
	RELEASE_DESCRIPTION="$DISTRO"
	;;
esac

if [ -n "$CI_JOB_TOKEN" ]; then
    DOCKER_BUILD="docker buildx build --push --platform=$plataform"
else
    DOCKER_BUILDKIT=1
    export DOCKER_BUILDKIT
    DOCKER_BUILD="docker build"
fi

$DOCKER_BUILD --progress=plain \
    -t "$CI_REGISTRY_IMAGE/$IMAGE:$VERSION-$ARCHITECTURE" \
    --build-arg TARBALL="$TARBALL" \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg VERSION="$VERSION" \
    --build-arg VCS_URL="$VCS_URL" \
    --build-arg VCS_REF="$VCS_REF" \
    --build-arg RELEASE_DESCRIPTION="$RELEASE_DESCRIPTION" \
    .

cat >"$ARCHITECTURE-$DISTRO".conf <<END
CI_REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"
IMAGE="$IMAGE"
VERSION="$VERSION-$ARCHITECTURE"
END
