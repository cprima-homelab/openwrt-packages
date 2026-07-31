#!/usr/bin/env bash
# Regenerate the package index for every arch directory under FEED_RELEASE_DIR.
# Detects APK (25.12+) vs IPK (24.10) by presence of .apk/.ipk files.
#
# APK usage (25.12):
#   APK_BIN=/path/to/sdk/host/bin/apk \
#   [APK_SIGN_KEY=/path/to/private.pem] \
#   scripts/build-feed-index.sh dist/feed/25.12/
#
# IPK usage (24.10):
#   MKHASH=/path/to/sdk/host/bin/mkhash \
#   MKINDEX=/path/to/sdk/scripts/ipkg-make-index.sh \
#   [USIGN=/path/to/sdk/host/bin/usign] \
#   [IPK_SIGN_KEY=/path/to/private.key] \
#   scripts/build-feed-index.sh dist/feed/24.10/

set -euo pipefail

FEED_RELEASE_DIR="${1:?Usage: $0 <feed_release_dir>}"

reindex_apk() {
    local arch_dir="$1"
    local APK_BIN="${APK_BIN:?Set APK_BIN to the OpenWrt SDK host/bin/apk}"
    local APK_SIGN_KEY="${APK_SIGN_KEY:-}"

    mapfile -t apks < <(find "$arch_dir" -maxdepth 1 -name '*.apk')
    [[ ${#apks[@]} -eq 0 ]] && return

    rm -f "$arch_dir/packages.adb"

    if [[ -n "$APK_SIGN_KEY" ]]; then
        "$APK_BIN" mkndx \
            --allow-untrusted \
            --sign-key "$APK_SIGN_KEY" \
            --output "$arch_dir/packages.adb" \
            "${apks[@]}"
    else
        "$APK_BIN" mkndx \
            --allow-untrusted \
            --output "$arch_dir/packages.adb" \
            "${apks[@]}"
    fi
    echo "  $(basename "$arch_dir"): ${#apks[@]} APK packages indexed → packages.adb"
}

reindex_ipk() {
    local arch_dir="$1"
    local MKHASH="${MKHASH:?Set MKHASH to the OpenWrt SDK host/bin/mkhash}"
    local MKINDEX="${MKINDEX:?Set MKINDEX to the OpenWrt SDK scripts/ipkg-make-index.sh}"
    local USIGN="${USIGN:-}"
    local IPK_SIGN_KEY="${IPK_SIGN_KEY:-}"

    local count
    count=$(find "$arch_dir" -maxdepth 1 -name '*.ipk' | wc -l)
    [[ "$count" -eq 0 ]] && return

    rm -f "$arch_dir/Packages" "$arch_dir/Packages.gz" "$arch_dir/Packages.sig" "$arch_dir/Packages.manifest"

    (
        cd "$arch_dir"
        MKHASH="$MKHASH" "$MKINDEX" . 2>/dev/null > Packages.manifest
        grep -vE '^(Maintainer|LicenseFiles|Source|Require)' Packages.manifest > Packages
        rm -f Packages.manifest
        gzip -9nc Packages > Packages.gz
        if [[ -n "$USIGN" && -n "$IPK_SIGN_KEY" ]]; then
            "$USIGN" -S -m Packages -s "$IPK_SIGN_KEY" -x Packages.sig
        fi
    )
    echo "  $(basename "$arch_dir"): $count IPK packages indexed → Packages / Packages.gz"
}

for arch_dir in "$FEED_RELEASE_DIR"/*/; do
    [[ -d "$arch_dir" ]] || continue

    apk_count=$(find "$arch_dir" -maxdepth 1 -name '*.apk' | wc -l)
    ipk_count=$(find "$arch_dir" -maxdepth 1 -name '*.ipk' | wc -l)

    if [[ "$apk_count" -gt 0 ]]; then
        reindex_apk "$arch_dir"
    elif [[ "$ipk_count" -gt 0 ]]; then
        reindex_ipk "$arch_dir"
    else
        echo "  $(basename "$arch_dir"): no packages found, skipping"
    fi
done
