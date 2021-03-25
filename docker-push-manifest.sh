#!/bin/bash

set -e
set -u

DISTRO=$1
ARCHITECTURES=$2

# Retrieve variables from former docker-build.sh
# We deal with all architectures at once, and we
# also expect only ONE image and version, just
# different architectures.
I=
V=
for arch in $ARCHITECTURES; do
    . ./"$DISTRO"-"$arch".conf
    I=${I:-$IMAGE}
    V=${V:-$VERSION}
    if [ "$I" != "$IMAGE" ]; then
        echo >&2 "ERROR: image mismatch, '$I' != '$IMAGE'"
        exit 1
    fi
    if [ "$V" != "$VERSION" ]; then
        echo >&2 "ERROR: version mismatch, '$V' != '$VERSION'"
        exit 1
    fi
done
IMAGE=$I
VERSION=$V

if [ -n "$CI_JOB_TOKEN" ]; then
    docker manifest push "$CI_REGISTRY_IMAGE/$IMAGE:$VERSION"
    docker manifest push "$CI_REGISTRY_IMAGE/$IMAGE":latest
fi

if [ -n "$DOCKER_HUB_ACCESS_TOKEN" ]; then
    docker manifest push "$DOCKER_HUB_REGISTRY_IMAGE/$IMAGE":latest
fi
