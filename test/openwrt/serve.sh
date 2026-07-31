#!/bin/bash
set -euo pipefail

: "${OPENWRT_RELEASE:?OPENWRT_RELEASE is required}"

PORT=8080
FEED=/harness/feed
ARCH_INDEX="${OPENWRT_RELEASE}/x86_64/packages.adb"

python3 -m http.server "$PORT" --directory "$FEED" \
    > /tmp/serve.log 2>&1 &
echo $! > /tmp/serve.pid

sleep 1

if ! curl -fsS "http://127.0.0.1:${PORT}/${ARCH_INDEX}" > /dev/null; then
    echo "FAIL: HTTP server not serving ${ARCH_INDEX} on port ${PORT}" >&2
    cat /tmp/serve.log >&2
    exit 1
fi

echo "HTTP server ready on :${PORT} serving ${FEED}"
