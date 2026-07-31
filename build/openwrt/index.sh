#!/usr/bin/env bash
set -euo pipefail

RELEASE="${OPENWRT_RELEASE:-25.12}"

# Keys arrive as env var content (not file paths) to avoid bind-mounting host paths.
# Materialise them to temp files inside the container.
APK_SIGN_KEY_FILE=""
IPK_SIGN_KEY_FILE=""

if [[ -n "${APK_SIGN_KEY:-}" ]]; then
    APK_SIGN_KEY_FILE=$(mktemp)
    printf '%s' "$APK_SIGN_KEY" > "$APK_SIGN_KEY_FILE"
    chmod 600 "$APK_SIGN_KEY_FILE"
fi

if [[ -n "${IPK_SIGN_KEY:-}" ]]; then
    IPK_SIGN_KEY_FILE=$(mktemp)
    printf '%s' "$IPK_SIGN_KEY" > "$IPK_SIGN_KEY_FILE"
    chmod 600 "$IPK_SIGN_KEY_FILE"
fi

if [[ "$RELEASE" == "24.10" ]]; then
    MKHASH=/builder/staging_dir/host/bin/mkhash
    MKINDEX=/builder/scripts/ipkg-make-index.sh
    USIGN=/builder/staging_dir/host/bin/usign
    exec env \
        MKHASH="$MKHASH" \
        MKINDEX="$MKINDEX" \
        USIGN="$USIGN" \
        IPK_SIGN_KEY="$IPK_SIGN_KEY_FILE" \
        bash /src/build-feed-index.sh "/feed/${RELEASE}/"
else
    APK_BIN=/builder/staging_dir/host/bin/apk
    exec env \
        APK_BIN="$APK_BIN" \
        APK_SIGN_KEY="$APK_SIGN_KEY_FILE" \
        bash /src/build-feed-index.sh "/feed/${RELEASE}/"
fi
