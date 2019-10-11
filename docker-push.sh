#!/bin/sh

set -e

DISTRO=$1
VERSION=$(. ./$DISTRO.conf; echo $VERSION)
CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE:-kalilinux}

case "$DISTRO" in
    kali-last-snapshot)
	IMAGE=kali
	;;
    *)
	IMAGE=$DISTRO
	;;
esac

# $CI_REGISTRY_IMAGE/$IMAGE:$VERSION has been built by docker-build.sh

# Overwrite the "latest" version too
docker tag $CI_REGISTRY_IMAGE/$IMAGE:$VERSION $CI_REGISTRY_IMAGE/$IMAGE:latest

# Try to push tags
if [ -n "$CI_JOB_TOKEN" ]; then
    # In GitLab, push must work !
    docker push $CI_REGISTRY_IMAGE/$IMAGE:$VERSION
    docker push $CI_REGISTRY_IMAGE/$IMAGE:latest
else
    echo "Trying to push to $CI_REGISTRY_IMAGE ... might fail if not logged in"
    docker push $CI_REGISTRY_IMAGE/$IMAGE:$VERSION || true
    docker push $CI_REGISTRY_IMAGE/$IMAGE:latest || true
fi
