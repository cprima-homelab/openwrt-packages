#!/usr/bin/env bash
# Sourced by all test/openwrt scripts. Safe to source without RUN_ID pre-set.

RUN_ID="${RUN_ID:-$(date -u +'%Y%m%dT%H%M%SZ')}"
export RUN_ID

log() {
    printf '%s run=%s %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$RUN_ID" "$*"
}

# Derive apk or ipk from the major version component of OPENWRT_RELEASE.
derive_package_format() {
    local release="${OPENWRT_RELEASE:?OPENWRT_RELEASE is required}"
    case "${release%%.*}" in
      24) echo "ipk" ;;
      25) echo "apk" ;;
      *)  echo "Cannot derive PACKAGE_FORMAT from OPENWRT_RELEASE=${release}" >&2; return 1 ;;
    esac
}
