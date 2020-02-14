# linux-image-builder
Assemble a bootable a linux image based on a kernel, an initramfs and a root filesystem.

- Using `syslinux` as a bootloader
- `Busybox` as the small-footprint initramfs
- An `Alpine` filesystem extracted from a docker image as our main filesystem

```
   Bootable Disk Image
+----------------------+
|      BOOTLOADER      | +
+----------------------+ |
|     LINUX KERNEL     | |
+----------------------+ |
|      INITRAMFS       | |
+----------------------+ |
|        ROOTFS        | v
+----------------------+
```

## Usage
```console
usage: ./build-image.sh [output image] [kernel bzImage] [initramfs dir] [rootfs dir] [syslinux dir]
```

### Example usage
```console
./build-image.sh my-linux.ext4 \ 
   deps/linux/arch/x86/boot/bzImage \
   deps/initramfs \ 
   deps/alpine-root-dir \
   deps/syslinux
```

### Booting the image in QEMU
```console
qemu-system-x86_64 -drive file=my-linux.ext4,if=virtio,format=raw --nographic 
```

### Add TAP network support
TODO: add ip config for tap network + iptables + guest config

```console
qemu-system-x86_64 -drive file=test.ext4,if=virtio,format=raw --nographic \ 
   -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
   -device virtio-net,netdev=net0
```

## Extra steps to build the components
### Build the Linux kernel
1. Clone the linux kernel source code: `git clone https://github.com/torvalds/linux.git`.
2. Checkout the version you want to use: `git checkout v5.6-rc1`.
3. Run `make menuconfig` to have the nice TUI (or you can use my `.config` file from the config directory).
4. Run `make -j$(nproc || echo -n 1)` to compile the kernel.
5. The compressed kernel image can be usually found in `linux/arch/x86/boot/bzImage`, this is the one to point the script to for the "kernel bzImage".

### Build the initramfs with Busybox
TODO

### Build the root filesystem from a Docker image
TODO

### Install the Syslinux bootloader
TODO
