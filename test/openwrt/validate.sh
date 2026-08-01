#!/bin/bash
# Artifact preflight: checks that expected packages are present in the feed.
set -euo pipefail

source "$(dirname "$0")/lib.sh"

: "${INSTALL_PACKAGES:?INSTALL_PACKAGES is required}"
: "${OPENWRT_RELEASE:?OPENWRT_RELEASE is required}"
: "${OPENWRT_ARCH:?OPENWRT_ARCH is required}"

PACKAGE_FORMAT="$(derive_package_format)"
FEED=/harness/feed
ARCH_DIR="${FEED}/${OPENWRT_RELEASE}/${OPENWRT_ARCH}"
fail=0
index_ok=false

shopt -s nullglob

case "$PACKAGE_FORMAT" in
  apk)
    if [[ -f "${ARCH_DIR}/packages.adb" ]]; then
        index_ok=true
        log "validate index=packages.adb status=found"
    else
        log "validate index=packages.adb status=missing" >&2
        fail=1
    fi
    for pkg in $INSTALL_PACKAGES; do
        matches=("${ARCH_DIR}/${pkg}"-*.apk)
        if (( ${#matches[@]} > 0 )); then
            log "validate package=${pkg} status=found file=${matches[0]##*/}"
        else
            log "validate package=${pkg} status=missing" >&2
            fail=1
        fi
    done
    ;;
  ipk)
    if [[ -f "${ARCH_DIR}/Packages.gz" ]]; then
        index_ok=true
        log "validate index=Packages.gz status=found"
    else
        log "validate index=Packages.gz status=missing" >&2
        fail=1
    fi
    for pkg in $INSTALL_PACKAGES; do
        matches=("${ARCH_DIR}/${pkg}"_*.ipk)
        if (( ${#matches[@]} > 0 )); then
            log "validate package=${pkg} status=found file=${matches[0]##*/}"
        else
            log "validate package=${pkg} status=missing" >&2
            fail=1
        fi
    done
    ;;
esac

pkg_count=0
for _p in $INSTALL_PACKAGES; do pkg_count=$((pkg_count+1)); done
log "validation_result=$( [[ "$fail" -eq 0 ]] && echo success || echo failed ) format=${PACKAGE_FORMAT} arch=${OPENWRT_ARCH} packages_expected=${pkg_count} index_present=${index_ok}"

[[ "$fail" -eq 0 ]] || exit 1
