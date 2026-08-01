#!/bin/bash
set -euo pipefail

if [[ -n "${GITHUB_RUN_NUMBER:-}" ]]; then
    RUN_ID="ci-${GITHUB_RUN_NUMBER}"
else
    RUN_ID="$(date -u +'%Y%m%dT%H%M%SZ')"
fi
export RUN_ID

source "$(dirname "$0")/lib.sh"

: "${OPENWRT_VERSION:?OPENWRT_VERSION is required}"
: "${INSTALL_PACKAGES:?INSTALL_PACKAGES is required}"

cleanup() {
    local pid
    for pidfile in /tmp/serve.pid /tmp/qemu.pid; do
        [[ -f "$pidfile" ]] || continue
        pid=$(cat "$pidfile")
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
    done
}
trap cleanup EXIT

cd "$(dirname "$0")"

_stage() {
    local name="$1"; shift
    local start=$SECONDS
    log "stage=${name} status=start"
    "$@"
    log "stage=${name} status=success duration_seconds=$((SECONDS - start))"
}

_stage validate ./validate.sh
_stage serve    ./serve.sh
_stage boot     ./boot.sh
_stage smoke    ./smoke.sh

echo
echo "PASS"
