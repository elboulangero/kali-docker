#!/bin/bash -e

DISTROS="${*:-kali-rolling}" # DISTROS="kali-rolling kali-dev kali-last-snapshot"
ARCHS="amd64" # ARCHS="amd64 arm64 armhf"

for distro in $DISTROS; do
  echo "Building images for $distro"
  ARCHS="$ARCHS" sudo -E ./build-rootfs.sh "$distro"
  ARCHS="$ARCHS" ./docker-build.sh "$distro"
  ARCHS="$ARCHS" ./docker-push.sh "$distro"
done
