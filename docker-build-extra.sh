#!/bin/bash

set -e
set -u

IMAGE=$1
ARCHITECTURE=$2

CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE:-"kalilinux"}

# Extra images are based on kali-rolling
CONFFILE=kali-rolling-"$ARCHITECTURE".conf
# shellcheck source=/dev/null
VERSION=$(. ./"$CONFFILE"; echo "$VERSION")

TAG=$VERSION-$ARCHITECTURE

podman build --squash \
    --arch "$ARCHITECTURE" \
    --build-arg CI_REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"\
    --build-arg TAG="$TAG" \
    --file extra/"$IMAGE" \
    --tag "$CI_REGISTRY_IMAGE/$IMAGE:$TAG" \
    .

if [ -n "${CI_JOB_TOKEN:-}" ]; then
    # Push the image so that subsequent jobs can fetch it
    podman push "$CI_REGISTRY_IMAGE/$IMAGE:$TAG"
fi

cat >"$IMAGE-$ARCHITECTURE".conf <<END
CI_REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"
TAG="$TAG"
VERSION="$VERSION"
END
