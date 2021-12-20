#!/bin/bash

set -e
set -u

IMAGE=$1
ARCHITECTURES=$2

# Retrieve variables from former docker-build.sh.
# We deal with all architectures at once, and of course
# we expect the version to be the same each time.
V=
for arch in $ARCHITECTURES; do
    . ./"$IMAGE-$arch".conf
    V=${V:-$VERSION}
    if [ "$V" != "$VERSION" ]; then
        echo >&2 "ERROR: version mismatch, '$V' != '$VERSION'"
        exit 1
    fi
done
VERSION=$V

if [ -n "${CI_JOB_TOKEN:-}" ]; then
    docker manifest push --purge "$CI_REGISTRY_IMAGE/$IMAGE:$VERSION"
    docker manifest push --purge "$CI_REGISTRY_IMAGE/$IMAGE":latest
fi

if [ -n "${DOCKER_HUB_ACCESS_TOKEN:-}" ]; then
    docker manifest push --purge "$DOCKER_HUB_ORGANIZATION/$IMAGE":latest
fi
