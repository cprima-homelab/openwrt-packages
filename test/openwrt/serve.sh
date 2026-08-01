#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

: "${OPENWRT_RELEASE:?OPENWRT_RELEASE is required}"
: "${OPENWRT_ARCH:?OPENWRT_ARCH is required}"

PORT="${FEED_PORT:-8080}"
ARCH="${OPENWRT_ARCH}"
FEED=/harness/feed
PACKAGE_FORMAT="$(derive_package_format)"

case "$PACKAGE_FORMAT" in
  apk) ARCH_INDEX="${OPENWRT_RELEASE}/${ARCH}/packages.adb" ;;
  ipk) ARCH_INDEX="${OPENWRT_RELEASE}/${ARCH}/Packages.gz" ;;
esac

python3 -m http.server "$PORT" --directory "$FEED" \
    > /tmp/feed-stable.log 2>&1 &
echo $! > /tmp/serve.pid

for i in $(seq 1 5); do
    if curl -fsS "http://127.0.0.1:${PORT}/${ARCH_INDEX}" >/dev/null 2>&1; then
        log "stage=feed-server status=ready port=${PORT} index=${ARCH_INDEX}"
        exit 0
    fi
    sleep 1
done

log "stage=feed-server status=fail port=${PORT}"
cat /tmp/feed-stable.log >&2
exit 1
