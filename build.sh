#!/bin/bash

set -e
set -u

IMAGES="${1:-kali-rolling}"
ARCHS="${2:-amd64}"

BASE_IMAGES="kali-rolling kali-dev kali-last-snapshot"
EXTRA_IMAGES="kali-experimental kali-bleeding-edge"

[ "$IMAGES" == all ] && IMAGES="$BASE_IMAGES $EXTRA_IMAGES"
[ "$ARCHS" == all ] && ARCHS="amd64 arm64 armhf"

# ensure rolling is built first, as extra images depend on it
if echo "$IMAGES" | grep -qw kali-rolling; then
    IMAGES="kali-rolling ${IMAGES//kali-rolling/}"
fi

echo "Images ..... : $IMAGES"
echo "Architectures: $ARCHS"

RUN=$(test $(id -u) -eq 0 || echo sudo)

for image in $IMAGES; do
    if echo "$BASE_IMAGES" | grep -qw $image; then
        base_image=1
    elif echo "$EXTRA_IMAGES" | grep -qw $image; then
        base_image=0
    else
        echo "Invalid image name '$image'" >&2
        continue
    fi
    for arch in $ARCHS; do
        echo "========================================"
        echo "Building image $image/$arch"
        echo "========================================"
        if [ $base_image -eq 1 ]; then
            $RUN ./build-rootfs.sh "$image" "$arch"
            $RUN ./docker-build.sh "$image" "$arch"
        else
            $RUN ./docker-build-extra.sh "$image" "$arch"
        fi
        $RUN ./docker-test.sh  "$image" "$arch"
        $RUN ./docker-push.sh  "$image" "$arch"
    done
    $RUN ./docker-push-manifest.sh "$image" "$ARCHS"
done
