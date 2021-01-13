#!/bin/bash -e

DISTRO=$1
architectures=( $ARCHS )

for architecture in "${architectures[@]}"; do

  # Retrieve variables from former docker-build.sh
  . ./${architecture}-${DISTRO}.conf

  if [ -n "$CI_JOB_TOKEN" ]; then
    echo "$CI_JOB_TOKEN" | docker login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY"
    docker pull $CI_REGISTRY_IMAGE/${IMAGE}:$VERSION

    DOCKER_HUB_REGISTRY="docker.io"
    DOCKER_HUB_REGISTRY_IMAGE="index.docker.io/$DOCKER_HUB_ORGANIZATION"
    echo "$DOCKER_HUB_ACCESS_TOKEN" | docker login -u "$DOCKER_HUB_USER" --password-stdin "$DOCKER_HUB_REGISTRY"
    docker tag $CI_REGISTRY_IMAGE/${IMAGE}:$VERSION $DOCKER_HUB_ORGANIZATION/${IMAGE}:$architecture
    docker push $DOCKER_HUB_ORGANIZATION/${IMAGE}:$architecture

  else
    docker tag $CI_REGISTRY_IMAGE/$IMAGE:$VERSION $CI_REGISTRY_IMAGE/$IMAGE:latest
  fi

done

if [ -n "$CI_JOB_TOKEN" ]; then
  IMAGES=$(docker images | grep $DOCKER_HUB_ORGANIZATION | head | awk '{print $1 ":" $2}' | tr '\n' ' ')
  docker manifest create $DOCKER_HUB_ORGANIZATION/${IMAGE}:latest $IMAGES
  docker manifest push -p $DOCKER_HUB_ORGANIZATION/${IMAGE}:latest
  docker rmi $IMAGES
fi
