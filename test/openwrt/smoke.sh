#!/bin/bash
set -euo pipefail

: "${EXPECTED_PACKAGES:?EXPECTED_PACKAGES is required}"
: "${OPENWRT_RELEASE:?OPENWRT_RELEASE is required}"

SSH_PORT=2222
# 10.0.2.2 is QEMU's default gateway — reaches the host HTTP server inside the container.
REPO_URL="http://10.0.2.2:8080/${OPENWRT_RELEASE}/x86_64/packages.adb"

ssh_vm() {
    sshpass -p "" ssh \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=10 \
        -o BatchMode=no \
        -p "$SSH_PORT" root@127.0.0.1 \
        "$@"
}

echo "Configuring APK repository..."
ssh_vm "echo '${REPO_URL}' > /etc/apk/repositories.d/harness.list"

# SPIKE: verify correct flag for installing from an unsigned packages.adb on OpenWrt 25.12.
# `apk -U add <pkg>` is the documented form; confirm -U permits unsigned repos
# before treating this as settled. Do not add a separate `apk -U update` —
# the documented pattern is install-only, not update-then-install.
echo "Installing packages: ${EXPECTED_PACKAGES}..."
# shellcheck disable=SC2086
ssh_vm "apk -U add $EXPECTED_PACKAGES"

# Executable assertions are explicit per-package.
# Package name and binary name are separated because they can differ.
echo "Asserting caddy..."
ssh_vm "command -v caddy"
ssh_vm "caddy version"

echo "Asserting salt-agent-ubus..."
ssh_vm "command -v salt-agent-ubus"
ssh_vm "salt-agent-ubus --version"

echo "Smoke tests passed"
