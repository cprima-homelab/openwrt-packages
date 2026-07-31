#!/bin/bash
set -euo pipefail

PORT=8080
DIST=/harness/dist

python3 -m http.server "$PORT" --directory "$DIST" \
    > /tmp/serve.log 2>&1 &
echo $! > /tmp/serve.pid

sleep 1

if ! curl -fsS "http://127.0.0.1:${PORT}/packages.adb" > /dev/null; then
    echo "FAIL: HTTP server not serving packages.adb on port ${PORT}" >&2
    cat /tmp/serve.log >&2
    exit 1
fi

echo "HTTP server ready on :${PORT} serving ${DIST}"
