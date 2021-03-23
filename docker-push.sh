#!/bin/bash

set -e

DISTRO=$1
ARCHITECTURE=$2
DOCKER_HUB_REGISTRY="docker.io"
DOCKER_HUB_REGISTRY_IMAGE="index.docker.io/$DOCKER_HUB_ORGANIZATION"

# Retrieve variables from former docker-build.sh
# shellcheck source=/dev/null
. ./"$ARCHITECTURE"-"$DISTRO".conf

if [ -n "$CI_JOB_TOKEN" ]; then
    docker pull "$CI_REGISTRY_IMAGE"/"$IMAGE":"$VERSION"
fi
docker tag "$CI_REGISTRY_IMAGE"/$IMAGE:"$VERSION" "$CI_REGISTRY_IMAGE"/$IMAGE:latest

# Push to GitLab registry
if [ -n "$CI_JOB_TOKEN" ]; then
    docker push $CI_REGISTRY_IMAGE/$IMAGE:$VERSION
    docker push $CI_REGISTRY_IMAGE/$IMAGE:latest
fi

# Push to Docher Hub registry
if [ -n "$DOCKER_HUB_ACCESS_TOKEN" ]; then
    docker tag "$CI_REGISTRY_IMAGE"/$IMAGE:$VERSION "$DOCKER_HUB_ORGANIZATION"/$IMAGE:"$ARCHITECTURE"
    docker push "$DOCKER_HUB_ORGANIZATION"/$IMAGE:"$ARCHITECTURE"

    # XXX: We don't push the versioned image because we are not
    # able to cleanup old images and "docker pull" will fetch all
    # versions of a given image...
    # Don't push
    #docker tag $CI_REGISTRY_IMAGE/$IMAGE:$VERSION $DOCKER_HUB_REGISTRY_IMAGE/$IMAGE:$VERSION
    #docker push $DOCKER_HUB_REGISTRY_IMAGE/$IMAGE:$VERSION
    # This operation is currently failing with "The operation
    # is unsupported.".
    #./docker-cleanup.sh $DOCKER_HUB_ORGANIZATION/$IMAGE
fi

# XXX Enable docker manifest part again?
# XXX According to the doc, it requires DOCKER_CLI_EXPERIMENTAL=enabled

exit

if [ -n "$CI_JOB_TOKEN" ]; then
    IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "$DOCKER_HUB_ORGANIZATION" | tr '\n' ' ')
    # shellcheck disable=SC2086
    docker manifest create "$DOCKER_HUB_ORGANIZATION"/$IMAGE:latest $IMAGES
    docker manifest push -p "$DOCKER_HUB_REGISTRY_IMAGE"/$IMAGE:latest
    for img in $IMAGES; do
	docker rmi "$img"
    done
fi
