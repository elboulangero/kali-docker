#!/bin/bash

set -e
set -u

DISTROS="${*:-kali-rolling}" # DISTROS="kali-rolling kali-dev kali-last-snapshot"
ARCHS="amd64" # ARCHS="amd64 arm64 armhf"

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
