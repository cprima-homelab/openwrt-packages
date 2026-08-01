#!/bin/bash
set -euo pipefail

: "${OPENWRT_VERSION:?OPENWRT_VERSION is required}"
: "${EXPECTED_PACKAGES:?EXPECTED_PACKAGES is required}"

cleanup() {
    local pid
    for pidfile in /tmp/serve.pid /tmp/qemu.pid; do
        if [ -f "$pidfile" ]; then
            pid=$(cat "$pidfile")
            kill "$pid" 2>/dev/null || true
            wait "$pid" 2>/dev/null || true
        fi
    done
}
trap cleanup EXIT

cd "$(dirname "$0")"

echo "==> Validating repository..."
./validate.sh

echo "==> Starting HTTP server..."
if [[ -z "${FEED_BASE_URL:-}" ]]; then
    ./serve.sh
else
    echo "    FEED_BASE_URL set — skipping local serve"
fi

echo "==> Booting OpenWrt ${OPENWRT_VERSION}..."
./boot.sh

echo "==> Running smoke tests..."
./smoke.sh

echo
echo "PASS"
