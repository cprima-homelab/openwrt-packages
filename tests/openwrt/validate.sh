#!/bin/bash
# Artifact preflight: checks that expected files are present in dist/.
# Does NOT verify that packages.adb indexes them — that is caught by the QEMU smoke test.
set -euo pipefail

: "${EXPECTED_PACKAGES:?EXPECTED_PACKAGES is required}"

DIST=/harness/dist
fail=0

if [ ! -f "${DIST}/packages.adb" ]; then
    echo "FAIL: ${DIST}/packages.adb not found" >&2
    fail=1
fi

shopt -s nullglob

for pkg in $EXPECTED_PACKAGES; do
    matches=("${DIST}/${pkg}"-*.apk)
    if (( ${#matches[@]} == 0 )); then
        echo "FAIL: no .apk found for package '${pkg}' in ${DIST}/" >&2
        fail=1
    else
        echo "  ok: ${matches[*]}"
    fi
done

# Roadmap: verify each expected package name appears in packages.adb.
# A stale index + new .apk files would pass here but fail apk add.
# The QEMU smoke test catches this in practice; deferred to a later iteration.

[ "$fail" -eq 0 ] || exit 1
echo "Preflight passed"
