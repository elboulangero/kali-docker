#!/bin/bash -e

DISTRO=$1
architecture=$2

CI_REGISTRY_IMAGE="${CI_REGISTRY_IMAGE:-kalilinux}"
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BUILD_VERSION=$(date -u +"%Y-%m-%d")
VCS_URL=$(git config --get remote.origin.url)
VCS_REF=$(git rev-parse --short HEAD)
RELEASE_DESCRIPTION="$DISTRO"

  case "${architecture}" in
    amd64) plataform="linux/amd64" ;;
    arm64) plataform="linux/arm64" ;;
    armhf) plataform="linux/arm/7" ;;
  esac

  # Add repository kali experimental/bleeding-edge in TARBALL
  echo "deb http://http.kali.org/kali $DISTRO main contrib non-free" > "$DISTRO".list
  pixz -d -k "${architecture}".kali-rolling.tar.xz
  tar uf "${architecture}".kali-rolling.tar "$DISTRO".list \
    --transform "s/$DISTRO.list/.\/etc\/apt\/sources.list.d\/$DISTRO.list/"
  pixz -1 "${architecture}".kali-rolling.tar "${architecture}.${DISTRO}".tar.xz
  rm -f "${architecture}".kali-rolling.tar || true

  TARBALL="${architecture}.${DISTRO}.tar.xz"
  VERSION="${BUILD_VERSION}"
  IMAGE="$DISTRO"

  if [ -n "$CI_JOB_TOKEN" ]; then
    DOCKER_BUILD="docker buildx build --push --platform=$plataform"
  else
    DOCKER_BUILDKIT=1
    export DOCKER_BUILDKIT
    DOCKER_BUILD="docker build --platform=$plataform"
  fi

  $DOCKER_BUILD --progress=plain \
    -t "$CI_REGISTRY_IMAGE/$IMAGE:$VERSION-${architecture}" \
    --build-arg TARBALL="$TARBALL" \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg VERSION="$VERSION" \
    --build-arg VCS_URL="$VCS_URL" \
    --build-arg VCS_REF="$VCS_REF" \
    --build-arg RELEASE_DESCRIPTION="$RELEASE_DESCRIPTION" \
    .

  cat >"${architecture}-$DISTRO".conf <<END
CI_REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"
IMAGE="$IMAGE"
VERSION="$VERSION-${architecture}"
END
