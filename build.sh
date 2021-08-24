#!/bin/bash

set -e
set -u

DISTROS="${1:-kali-rolling}"
EXTRA_DISTROS="${2:-}"
ARCHS="${3:-amd64}"

[ "$DISTROS" == all ] && DISTROS="kali-rolling kali-dev kali-last-snapshot"
[ "$EXTRA_DISTROS" == all ] && EXTRA_DISTROS="kali-experimental kali-bleeding-edge"
[ "$ARCHS" == all ] && ARCHS="amd64 arm64 armhf"

echo "Distributions: $DISTROS"
echo "Extra distros: $EXTRA_DISTROS"
echo "Architectures: $ARCHS"

for distro in $DISTROS; do
    for arch in $ARCHS; do
        echo "========================================"
        echo "Building image $distro/$arch"
        echo "========================================"
        sudo ./build-rootfs.sh "$distro" "$arch"
        sudo ./docker-build.sh "$distro" "$arch"
        sudo ./docker-test.sh  "$distro" "$arch"
        sudo ./docker-push.sh  "$distro" "$arch"
    done
    sudo ./docker-push-manifest.sh "$distro" "$arch"
done

for distro in $EXTRA_DISTROS; do
    for arch in $ARCHS; do
        echo "========================================"
        echo "Building image $distro/$arch"
        echo "========================================"
        sudo ./docker-build-extra.sh "$distro" "$arch"
        sudo ./docker-test.sh "$distro" "$arch"
        sudo ./docker-push.sh "$distro" "$arch"
    done
    sudo ./docker-push-manifest.sh "$distro" "$arch"
done
