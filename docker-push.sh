#!/bin/bash

set -e
set -u

DISTRO=$1
ARCHITECTURE=$2

# Retrieve variables from former docker-build.sh
# shellcheck source=/dev/null
. ./"$DISTRO"-"$ARCHITECTURE".conf

# Pull image
if [ -n "${CI_JOB_TOKEN:-}" ]; then
    docker pull "$CI_REGISTRY_IMAGE/$IMAGE:$TAG"
fi

# Update manifests for GitLab
docker manifest create \
    "$CI_REGISTRY_IMAGE/$IMAGE:$VERSION" \
    --amend "$CI_REGISTRY_IMAGE/$IMAGE:$TAG"
docker manifest create \
    "$CI_REGISTRY_IMAGE/$IMAGE":latest \
    --amend "$CI_REGISTRY_IMAGE/$IMAGE:$TAG"

# Push to Docher Hub registry
if [ -n "${DOCKER_HUB_ACCESS_TOKEN:-}" ]; then
    docker tag "$CI_REGISTRY_IMAGE/$IMAGE:$TAG" "$DOCKER_HUB_ORGANIZATION/$IMAGE:$ARCHITECTURE"
    docker push "$DOCKER_HUB_ORGANIZATION/$IMAGE:$ARCHITECTURE"

    # XXX: We don't push the versioned image because we are not
    # able to cleanup old images and "docker pull" will fetch all
    # versions of a given image...
    # Don't push
    #docker tag $CI_REGISTRY_IMAGE/$IMAGE:$TAG $DOCKER_HUB_REGISTRY_IMAGE/$IMAGE:$TAG
    #docker push $DOCKER_HUB_ORGANIZATION/$IMAGE:$TAG

    # This operation is currently failing with "The operation is unsupported.".
    #./docker-cleanup.sh $DOCKER_HUB_ORGANIZATION/$IMAGE
fi

# Update manifest for Docker Hub
docker manifest create \
    "$DOCKER_HUB_ORGANIZATION/$IMAGE":latest \
    --amend "$DOCKER_HUB_ORGANIZATION/$IMAGE:$ARCHITECTURE"
