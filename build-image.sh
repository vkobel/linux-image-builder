#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

TMP_DIR=$(mktemp -d)

trap clean EXIT
function clean {
    if grep -qs "$TMP_DIR " /proc/mounts; then
        sudo umount $TMP_DIR
    else
        echo "usage: $0 [output image] [kernel bzImage] [initramfs dir] [rootfs dir] [syslinux dir]"
    fi
    rm -rf $TMP_DIR
}

IMG=$1
LINUX_KERNEL=$2
INITRAMFS_DIR=$3
ROOTFS_DIR=$4
SYSLINUX_DIR=$5

[ ! -f "$LINUX_KERNEL" ] && exit 1
[ -z "$(ls -A $INITRAMFS_DIR)" ] && exit 1
[ -z "$(ls -A $ROOTFS_DIR)" ] && exit 1
[ -z "$(ls -A $SYSLINUX_DIR)" ] && exit 1

dd if=/dev/zero of=$IMG bs=1M count=50
mkfs.ext4 $IMG
sudo mount $IMG $TMP_DIR

# Copy the root file system from existing source
sudo cp -r $ROOTFS_DIR/* $TMP_DIR

# Copy the kernel from a compressed bzImage
sudo cp $LINUX_KERNEL $TMP_DIR/vmlinuz

# Create and copy the initramfs CPIO archive
cp config/init $INITRAMFS_DIR
mkdir -p $INITRAMFS_DIR/{bin,dev,etc,lib,lib64,mnt/root,proc,root,sbin,sys}
cd $INITRAMFS_DIR
find . -print0 | cpio --null --create --verbose --format=newc | sudo sh -c "gzip --best > $TMP_DIR/initramfs.cpio.gz"
cd -

# Copy and init the Syslinux bootloader
sudo mkdir -p $TMP_DIR/{boot,lib/modules}
sudo cp $SYSLINUX_DIR/bios/*.c32 $TMP_DIR/boot
sudo extlinux --install $TMP_DIR/boot
sudo cp config/syslinux.cfg $TMP_DIR/boot

echo Bootable image successfully created: $IMG!
exit 0
