#!/bin/bash

set -e

DISTRO=$1
ARCHITECTURE=$2
DOCKER_HUB_REGISTRY="docker.io"
DOCKER_HUB_REGISTRY_IMAGE="index.docker.io/$DOCKER_HUB_ORGANIZATION"

# Retrieve variables from former docker-build.sh
# shellcheck source=/dev/null
. ./"${ARCHITECTURE}"-"${DISTRO}".conf

if [ -n "$CI_JOB_TOKEN" ]; then
    docker pull "$CI_REGISTRY_IMAGE"/"${IMAGE:=}":"$VERSION"

    docker tag "$CI_REGISTRY_IMAGE"/${IMAGE}:"$VERSION" "$DOCKER_HUB_ORGANIZATION"/${IMAGE}:"$ARCHITECTURE"
    docker push "$DOCKER_HUB_ORGANIZATION"/${IMAGE}:"$ARCHITECTURE"
    docker rmi "$CI_REGISTRY_IMAGE"/${IMAGE}:"$VERSION"
else
    docker tag "$CI_REGISTRY_IMAGE"/$IMAGE:"$VERSION" "$CI_REGISTRY_IMAGE"/$IMAGE:latest
fi

# XXX Enable docker manifest part again?
# XXX According to the doc, it requires DOCKER_CLI_EXPERIMENTAL=enabled

exit

if [ -n "$CI_JOB_TOKEN" ]; then
    IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "$DOCKER_HUB_ORGANIZATION" | tr '\n' ' ')
    # shellcheck disable=SC2086
    docker manifest create "$DOCKER_HUB_ORGANIZATION"/${IMAGE}:latest $IMAGES
    docker manifest push -p "$DOCKER_HUB_REGISTRY_IMAGE"/${IMAGE}:latest
    for img in $IMAGES; do
	docker rmi "$img"
    done
fi
