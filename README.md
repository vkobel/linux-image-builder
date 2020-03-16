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
In order to add network support to your VM you can add a TAP device to your host and use virtio-net in qemu. Note that mentions to `eth0` need to be adapted to reflect your actual setup. If you plan to run multiple VMs you will need one TAP device for each.

On your host:
```bash
# create a TAP device
sudo ip tuntap add tap0 mode tap
# assign it an IP
sudo ip addr add 172.16.0.1/24 dev tap0
# bring it up
sudo ip link set tap0 up
# ensure your host can act as a router (forwarding packets)
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
# enable NAT/MASQUERADE for traffic out of your local interface
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
# accept packets from existing connections 
sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# forward traffic from your TAP device to your local interface
sudo iptables -A FORWARD -i tap0 -o eth0 -j ACCEPT
```

Then you can launch qemu with referring your new TAP device:
```console
qemu-system-x86_64 -drive file=test.ext4,if=virtio,format=raw --nographic \ 
   -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
   -device virtio-net,netdev=net0
```

Finally, from your VM, setup the new interface (feel free to adapt it to better fit your needs):
```console
ip addr add 172.16.0.2/24 dev eth0
ip link set eth0 up
ip route add default via 172.16.0.1 dev eth0
```

## Extra steps to build the components
### Build the Linux kernel (deps/linux/arch/x86/boot/bzImage)
1. Clone the Linux kernel source code: `git clone https://github.com/torvalds/linux.git`.
2. Checkout the version you want to use: `git checkout v5.6-rc1`.
3. Run `make menuconfig` to have the nice TUI (or you can use my `.config` file from the config directory).
4. Run `make -j$(nproc || echo -n 1)` to compile the kernel.
5. The compressed kernel image can be usually found in `linux/arch/x86/boot/bzImage`, this is the one to point the script to for the "kernel bzImage".

### Build the initramfs with Busybox (deps/initramfs)
1. Clone the Busybox repository: `git clone git://git.busybox.net/busybox`
2. Chekout the version you want to target (here the latest stable at time of writing): `git checkout 1_31_stable`
3. Run `make menuconfig` to have the nice TUI, and activate the `Settings -> Build static binary (no shared libs)` option. This sets the flag `CONFIG_STATIC=y` in the `.config` file.
4. Run `make install -j$(nproc || echo -n 1)` to compile Busybox, and make it produce the nice root filesystem we are expecting under the `busybox/_install` folder.

### Build the root filesystem from a Docker image (deps/alpine-root-dir)
TODO

### Install the Syslinux bootloader (deps/syslinux)
TODO
