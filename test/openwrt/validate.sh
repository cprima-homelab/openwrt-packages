#!/bin/bash
# Artifact preflight: checks that expected packages are present in the feed.
# Does NOT verify that packages.adb indexes them — that is caught by the QEMU smoke test.
set -euo pipefail

: "${EXPECTED_PACKAGES:?EXPECTED_PACKAGES is required}"
: "${OPENWRT_RELEASE:?OPENWRT_RELEASE is required}"

FEED=/harness/feed
ARCH_DIR="${FEED}/${OPENWRT_RELEASE}/x86_64"
fail=0

if [ ! -f "${ARCH_DIR}/packages.adb" ]; then
    echo "FAIL: ${ARCH_DIR}/packages.adb not found" >&2
    fail=1
fi

shopt -s nullglob

for pkg in $EXPECTED_PACKAGES; do
    matches=("${ARCH_DIR}/${pkg}"-*.apk)
    if (( ${#matches[@]} == 0 )); then
        echo "FAIL: no .apk found for package '${pkg}' in ${ARCH_DIR}/" >&2
        fail=1
    else
        echo "  ok: ${matches[*]}"
    fi
done

[ "$fail" -eq 0 ] || exit 1
echo "Preflight passed"
