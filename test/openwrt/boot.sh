#!/bin/bash
set -euo pipefail

: "${OPENWRT_VERSION:?OPENWRT_VERSION is required}"

CACHE_DIR="${CACHE_DIR:-/cache}"
SSH_PORT=2222
IMG_NAME="openwrt-${OPENWRT_VERSION}-x86-64"
CACHED_IMG="${CACHE_DIR}/${IMG_NAME}.img"
IMAGE_URL="https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/x86/64/openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-combined.img.gz"

mkdir -p "$CACHE_DIR"

if [ ! -f "$CACHED_IMG" ]; then
    echo "Downloading OpenWrt ${OPENWRT_VERSION} image..."
    curl -fL "$IMAGE_URL" -o /tmp/openwrt.img.gz
    gzip -dc /tmp/openwrt.img.gz > "${CACHED_IMG}.tmp"
    mv "${CACHED_IMG}.tmp" "$CACHED_IMG"
    rm -f /tmp/openwrt.img.gz
    echo "Image cached at ${CACHED_IMG}"
else
    echo "Using cached image ${CACHED_IMG}"
fi

rm -f /tmp/vm.qcow2
qemu-img create -f qcow2 -b "$CACHED_IMG" -F raw /tmp/vm.qcow2

QEMU_ARGS=(-m 256M)
if [ -e /dev/kvm ]; then
    QEMU_ARGS+=(-accel kvm)
    echo "KVM acceleration enabled"
fi

# -machine pc is the simplest option known to work with OpenWrt x86 combined images.
# Verify before switching to q35 or virtio-blk.
qemu-system-x86_64 \
    -machine pc \
    "${QEMU_ARGS[@]}" \
    -drive if=ide,file=/tmp/vm.qcow2,format=qcow2 \
    -netdev user,id=n0,hostfwd=tcp::${SSH_PORT}-:22 \
    -device e1000,netdev=n0 \
    -nographic \
    > /tmp/qemu.log 2>&1 &
echo $! > /tmp/qemu.pid
echo "QEMU started (PID $(cat /tmp/qemu.pid))"

echo "Waiting for SSH port ${SSH_PORT}..."
for i in $(seq 1 60); do
    if nc -z 127.0.0.1 "$SSH_PORT" 2>/dev/null; then
        break
    fi
    if [ "$i" -eq 60 ]; then
        echo "Timeout waiting for VM to boot" >&2
        echo "--- QEMU log ---" >&2
        cat /tmp/qemu.log >&2
        exit 1
    fi
    sleep 2
done

# Wait for SSH service to be ready (port open != dropbear accepting connections yet)
for i in $(seq 1 10); do
    if sshpass -p "" ssh \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=3 \
        -o BatchMode=no \
        -p "$SSH_PORT" root@127.0.0.1 true 2>/dev/null; then
        echo "VM ready"
        exit 0
    fi
    sleep 3
done

echo "VM port open but SSH not responding" >&2
cat /tmp/qemu.log >&2
exit 1
