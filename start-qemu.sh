#/bin/bash

# First arg is always a full, self-sufficient disk image
drive=${1}

# if set, the second arg is the kernel
extra_opts=()
if [ "${2}" ]; then
    extra_args=( -kernel ${2} -append "root=/dev/vda rw console=ttyS0" )
fi

qemu-system-x86_64 -m 256M \
    -drive file=$drive,if=virtio,format=raw \
    --nographic \
    -netdev tap,id=net0,script=qemu-iface/ifup.sh,downscript=qemu-iface/ifdown.sh \
    -device virtio-net,netdev=net0 \
    -enable-kvm \
    "${extra_args[@]}"
