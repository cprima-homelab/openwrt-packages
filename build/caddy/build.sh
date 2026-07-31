#!/bin/sh
set -eu

: "${OPENWRT_ARCH:?OPENWRT_ARCH is required (e.g. x86_64, aarch64_cortex-a53)}"
: "${CADDY_VERSION:?CADDY_VERSION is required (e.g. v2.10.2)}"

case "$OPENWRT_ARCH" in
    x86_64)
        GOARCH=amd64
        ;;
    aarch64_*)
        GOARCH=arm64
        ;;
    arm_*)
        GOARCH=arm
        GOARM=7
        export GOARM
        ;;
    mips_*)
        GOARCH=mips
        ;;
    mipsle_*)
        GOARCH=mipsle
        ;;
    *)
        echo "Unsupported OpenWrt architecture: ${OPENWRT_ARCH}" >&2
        exit 1
        ;;
esac

export GOARCH

echo "Building Caddy ${CADDY_VERSION} for ${OPENWRT_ARCH} (GOARCH=${GOARCH})"

xcaddy build "${CADDY_VERSION}" \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/caddy-dns/inwx \
    --output /out/caddy

echo "Built: $(ls -lh /out/caddy)"
