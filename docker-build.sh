#!/bin/bash

set -e
set -u

IMAGE=$1
ARCHITECTURE=$2
TARBALL=$IMAGE-$ARCHITECTURE.tar.xz
VERSIONFILE=$IMAGE-$ARCHITECTURE.release.version

CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE:-"kalilinux"}
PROJECT_URL=${CI_PROJECT_URL:-"https://gitlab.com/kalilinux/build-scripts/kali-docker"}
BUILD_DATE=${CI_JOB_STARTED_AT:-$(date -u +"%Y-%m-%dT%H:%M:%SZ")}
BUILD_VERSION=$(date -u +"%Y.%m.%d")
VCS_REF=${CI_COMMIT_SHORT_SHA:-$(git rev-parse --short HEAD)}

case "$ARCHITECTURE" in
    amd64) platform="linux/amd64" ;;
    arm64) platform="linux/arm64" ;;
    armhf) platform="linux/arm/7" ;;
esac

case "$IMAGE" in
    kali-last-release)
        VERSION=$(cat "$VERSIONFILE")
        RELEASE_DESCRIPTION="$VERSION"
        ;;
    *)
        VERSION="$BUILD_VERSION"
        RELEASE_DESCRIPTION="$IMAGE"
        ;;
esac

TAG=$VERSION-$ARCHITECTURE

export DOCKER_BUILDKIT=1
docker build \
    --build-arg TARBALL="$TARBALL" \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg VERSION="$VERSION" \
    --build-arg PROJECT_URL="$PROJECT_URL" \
    --build-arg VCS_REF="$VCS_REF" \
    --build-arg RELEASE_DESCRIPTION="$RELEASE_DESCRIPTION" \
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
