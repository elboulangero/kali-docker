#!/bin/bash

set -e
set -u

IMAGE=$1
ARCHITECTURES=$2
TAGS=

# Retrieve variables from former docker-build.sh
FIRST_ARCH=$(echo "$ARCHITECTURES" | cut -d' ' -f1)
. ./"$IMAGE-$FIRST_ARCH".conf

# In this script, we process all architecture-variants of an image,
# and they all come with a .conf file.  All the variables in these
# conf files should have the same value, except for TAG. Let's make
# sure that it's the case. Then we'll load all values for TAG.
if [ "$FIRST_ARCH" != "$ARCHITECTURES" ]; then
    UNEXPECTED_LINES=$(for arch in $ARCHITECTURES; do \
        cat "$IMAGE-$arch".conf; done | sort | uniq -u | grep -v "^TAG=" || :)
    if [ "$UNEXPECTED_LINES" ]; then
        echo "ERROR: Unexpected values in '$IMAGE-*.conf':" >&2
        echo "$UNEXPECTED_LINES" >&2
        exit 1
    fi
    # shellcheck disable=SC2153
    TAGS=$(for arch in $ARCHITECTURES; do \
        . ./"$IMAGE-$arch".conf && echo "$TAG"; done)
else
    TAGS="$TAG"
fi

# Push manifests to the staging registry.
#
# Images are already on the registry, all we need to do is
# create the manifest, populate it, and push it.

if [ "$REGISTRY" != localhost ]; then
    # Short variable name for readability
    IMG="$REGISTRY_IMAGE/$IMAGE"

    # Pull the images
    for tag in $TAGS; do
        podman pull "$IMG:$tag"
    done

    # Create and push the versioned manifest
    podman manifest create "$IMG:$VERSION"
    for tag in $TAGS; do
        podman manifest add "$IMG:$VERSION" "$IMG:$tag"
    done
    podman manifest push -f v2s2 "$IMG:$VERSION" docker://"$IMG:$VERSION"

    # Create and push the 'latest' manifest
    podman tag "$IMG:$VERSION" "$IMG":latest
    podman manifest push -f v2s2 "$IMG":latest docker://"$IMG":latest
fi

# Publish images to the Docker Hub.
#
# We don't push the versioned images because we are not
# able to cleanup old images. So we push only a 'latest'
# manifest, and images tagged per architecture, meaning
# that we replace what's already on the Docker Hub.

if [ -n "${DOCKER_HUB_ORGANIZATION:-}" ]; then
    # Create a list of (arch, tag) couples
    ARCH_TAG=$(for arch in $ARCHITECTURES; do \
        . ./"$IMAGE-$arch".conf && echo "$arch" "$TAG"; done)

    # Tag each image for Docker Hub.
    while read -r arch tag; do
        podman tag "$REGISTRY_IMAGE/$IMAGE:$tag" \
            "$DOCKER_HUB_ORGANIZATION/$IMAGE:$arch"
    done <<< "$ARCH_TAG"

    # Short variable name for readability
    IMG="$DOCKER_HUB_ORGANIZATION/$IMAGE"

    # Create and push the 'latest' manifest
    # NB: the 'manifest add' command below fails if we don't push
    # images beforehand. It's not very clear why, the error message
    # doesn't say, the doc doesn't say either.
    podman manifest create "$IMG":latest
    for arch in $ARCHITECTURES; do
        podman push -f v2s2 "$IMG:$arch"
        podman manifest add "$IMG":latest "$IMG:$arch"
    done
    podman manifest push -f v2s2 "$IMG":latest docker://"$IMG":latest
fi
