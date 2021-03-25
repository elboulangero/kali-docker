#!/bin/bash

set -e
set -u

DISTROS="${*:-kali-rolling}"
EXTRA_DISTROS=""
ARCHS="amd64"

#DISTROS="kali-rolling kali-dev kali-last-snapshot"
#EXTRA_DISTROS="kali-experimental kali-bleeding-edge"
#ARCHS="amd64 arm64 armhf"

echo "Distributions: $DISTROS"
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
