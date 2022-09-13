#!/bin/bash

set -e
set -u

IMAGE=$1
ARCHITECTURE=$2

# Retrieve variables from former docker-build.sh
# NB: extra images are based on kali-rolling
BASE=kali-rolling
. ./"$BASE-$ARCHITECTURE".conf

podman build --squash \
    --arch "$ARCHITECTURE" \
    --build-arg REGISTRY_IMAGE="$REGISTRY_IMAGE"\
    --build-arg TAG="$TAG" \
    --file extra/"$IMAGE" \
    --tag "$REGISTRY_IMAGE/$IMAGE:$TAG" \
    .

if [ "$REGISTRY" != localhost ]; then
    # Push the image so that subsequent jobs can fetch it
    podman push "$REGISTRY_IMAGE/$IMAGE:$TAG"
fi

cp "$BASE-$ARCHITECTURE".conf "$IMAGE-$ARCHITECTURE".conf
