#!/usr/bin/env bash
# Copy built APKs/IPKs into the feed, replacing old versions of the same package.
# Packages with arch suffix '_all' are fanned out to every extra arch listed after
# the first two positional arguments.
#
# Usage:
#   scripts/sync-apks.sh <src_dir> <feed_release_dir> [extra_arch ...]
#
#   src_dir:          dist/packages/<release>/ — contains <arch>/ subdirectories
#   feed_release_dir: dist/feed/<release>/
#   extra_arch:       additional arch dirs to receive _all packages
#                     (e.g. aarch64_cortex-a53 mipsel_24kc)

set -euo pipefail

SRC_DIR="${1:?Usage: $0 <src_dir> <feed_release_dir> [extra_arch ...]}"
FEED_RELEASE_DIR="${2:?}"
shift 2
EXTRA_ARCHES=("$@")

is_all_pkg() {
    local filename="$1"
    # _all.ipk  or  -noarch.apk / _all-*.apk patterns
    [[ "$filename" == *_all.ipk ]] || [[ "$filename" == *_all-*.apk ]] || [[ "$filename" == *-noarch.apk ]]
}

place_pkg() {
    local pkg_file="$1" arch_dst="$2"
    local filename ext pkg_stem
    filename=$(basename "$pkg_file")
    ext="${filename##*.}"
    mkdir -p "$arch_dst"

    if [[ "$ext" == "apk" ]]; then
        pkg_stem=$(echo "$filename" | sed 's/-[0-9].*//')
        rm -f "$arch_dst/${pkg_stem}"-*.apk
    else
        pkg_stem="${filename%%_[0-9]*}"
        rm -f "$arch_dst/${pkg_stem}"_*.ipk
    fi

    cp "$pkg_file" "$arch_dst/"
}

for arch_src in "$SRC_DIR"/*/; do
    [[ -d "$arch_src" ]] || continue
    arch=$(basename "$arch_src")
    arch_dst="$FEED_RELEASE_DIR/$arch"

    while IFS= read -r pkg_file; do
        filename=$(basename "$pkg_file")
        place_pkg "$pkg_file" "$arch_dst"
        echo "  $filename → $arch/"

        if is_all_pkg "$filename"; then
            for extra in "${EXTRA_ARCHES[@]+"${EXTRA_ARCHES[@]}"}"; do
                [[ "$extra" == "$arch" ]] && continue
                place_pkg "$pkg_file" "$FEED_RELEASE_DIR/$extra"
                echo "  $filename → $extra/  (all)"
            done
        fi
    done < <(find "$arch_src" -maxdepth 1 \( -name '*.apk' -o -name '*.ipk' \))
done
