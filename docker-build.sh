#!/bin/sh

set -e

DISTRO=$1
TARBALL=$1.tar.xz
CHROOT=rootfs-$1

CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE:-kalilinux}
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BUILD_VERSION=$(date -u +"%Y-%m-%d")
VCS_URL=$(git config --get remote.origin.url)
VCS_REF=$(git rev-parse --short HEAD)

case "$DISTRO" in
    kali-last-snapshot)
	IMAGE=kali
	mkdir -p $CHROOT
	tar -C $CHROOT -xf $TARBALL
	VERSION=$(. $CHROOT/etc/os-release; echo $VERSION)
	;;
    *)
	IMAGE=$DISTRO
	VERSION=$BUILD_VERSION
	;;
esac

docker build --pull -t $CI_REGISTRY_IMAGE/$IMAGE:$VERSION \
    --build-arg TARBALL=$TARBALL \
    --build-arg BUILD_DATE=$BUILD_DATE \
    --build-arg VERSION=$VERSION \
    --build-arg VCS_URL=$VCS_URL \
    --build-arg VCS_REF=$VCS_REF .

cat >$DISTRO.conf <<END
CI_REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"
IMAGE="$IMAGE"
VERSION="$VERSION"
END
