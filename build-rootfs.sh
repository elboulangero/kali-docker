#!/bin/bash

set -e

distro=$1
architecture=$2
mirror=${3:-http://http.kali.org/kali}

rootfsDir=rootfs-$distro-$architecture
debootstrap=${DEBOOTSTRAP:-debootstrap}

rootfs_chroot() {
    PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
        chroot "$rootfsDir" "$@"
}


if [ ! -e /usr/share/debootstrap/scripts/$distro ]; then
    echo "ERROR: debootstrap has no script for $distro"
    echo "ERROR: use a newer debootstrap"
    exit 1
fi

if [ ! -e /usr/share/keyrings/kali-archive-keyring.gpg ]; then
    echo "ERROR: you need /usr/share/keyrings/kali-archive-keyring.gpg"
    echo "ERROR: install kali-archive-keyring"
    exit 1
fi

rm -rf "$rootfsDir" "$architecture.$distro.tar.xz"

qemu-debootstrap --variant=minbase --components=main,contrib,non-free \
    --arch="$architecture" --include=kali-archive-keyring \
    "$distro" "$rootfsDir" "$mirror"

rootfs_chroot apt-get -y --no-install-recommends install kali-defaults

rootfs_chroot apt-get clean

# Inspired by /usr/share/docker.io/contrib/mkimage/debootstrap
cat > "$rootfsDir/usr/sbin/policy-rc.d" <<-'EOF'
	#!/bin/sh
	exit 101
EOF
chmod +x "$rootfsDir/usr/sbin/policy-rc.d"

echo 'force-unsafe-io' > "$rootfsDir"/etc/dpkg/dpkg.cfg.d/docker-apt-speedup

aptGetClean='"rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true";'
cat > "$rootfsDir"/etc/apt/apt.conf.d/docker-clean <<-EOF
	DPkg::Post-Invoke { ${aptGetClean} };

	Dir::Cache::pkgcache "";
	Dir::Cache::srcpkgcache "";
EOF

echo 'Acquire::Languages "none";' >"$rootfsDir"/etc/apt/apt.conf.d/docker-no-languages

cat > "$rootfsDir"/etc/apt/apt.conf.d/docker-gzip-indexes <<-'EOF'
	Acquire::GzipIndexes "true";
	Acquire::CompressionTypes::Order:: "gz";
EOF

echo 'Apt::AutoRemove::SuggestsImportant "false";' >"$rootfsDir"/etc/apt/apt.conf.d/docker-autoremove-suggests

rm -rf "$rootfsDir"/var/lib/apt/lists/*
mkdir -p "$rootfsDir"/var/lib/apt/lists/partial
find "$rootfsDir"/var/log -depth -type f -print0 | xargs -0 truncate -s 0

echo "Creating ${architecture}.${distro}.tar.xz"
tar -I 'pixz -1' -C "$rootfsDir" -pcf "${architecture}.${distro}".tar.xz .

if [ -z "$CI_JOB_TOKEN" ]; then
    chmod 775 "${architecture}.${distro}".tar.xz
    rm -rf "${architecture}"
fi

if [ "$distro" = "kali-last-snapshot" ]; then
    awk -F= '$1=="VERSION" { print $2 ;}' "$rootfsDir"/usr/lib/os-release | tr -d '"' > release.version
fi
