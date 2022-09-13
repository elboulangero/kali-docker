#!/bin/bash

set -e
set -u

IMAGE=$1
ARCHITECTURE=$2
TARBALL=$IMAGE-$ARCHITECTURE.tar.gz
VERSIONFILE=$IMAGE-$ARCHITECTURE.release.version

if [ "${GITLAB_CI:-}" = true ]; then
    REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"
    PROJECT_URL="$CI_PROJECT_URL"
    BUILD_DATE="$CI_JOB_STARTED_AT"
    VCS_REF="$CI_COMMIT_SHORT_SHA"
else
    REGISTRY_IMAGE="localhost/kalilinux"
    PROJECT_URL="https://gitlab.com/kalilinux/build-scripts/kali-docker"
    BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    VCS_REF=$(git rev-parse --short HEAD)
fi

BUILD_VERSION=$(date -u +"%Y.%m.%d")
REGISTRY="${REGISTRY_IMAGE%%/*}"

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

podman build --squash \
    --arch "$ARCHITECTURE" \
    --build-arg TARBALL="$TARBALL" \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg VERSION="$VERSION" \
    --build-arg PROJECT_URL="$PROJECT_URL" \
    --build-arg VCS_REF="$VCS_REF" \
    --build-arg RELEASE_DESCRIPTION="$RELEASE_DESCRIPTION" \
    --tag "$REGISTRY_IMAGE/$IMAGE:$TAG" \
    .

if [ "$REGISTRY" != localhost ]; then
    # Push the image so that subsequent jobs can fetch it
    podman push "$REGISTRY_IMAGE/$IMAGE:$TAG"
fi

cat >"$IMAGE-$ARCHITECTURE".conf <<END
REGISTRY="$REGISTRY"
REGISTRY_IMAGE="$REGISTRY_IMAGE"
TAG="$TAG"
VERSION="$VERSION"
END
