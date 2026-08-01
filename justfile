set shell := ["pwsh", "-c"]

# Build Caddy gap-fill binaries for all versions and targets (Stage 1)
build-caddy-app:
    docker compose -f build/caddy/compose.yaml run --build --rm build

# Build OpenWrt packages (salt-*, luci-*) using the official SDK (Stage 2)
# release: OpenWrt major.minor (25.12 or 24.10)
# release_full: patch version used to pin the SDK download
build-packages release="25.12" release_full="25.12.5":
    New-Item -ItemType Directory -Force -Path "dist/packages/{{release}}" | Out-Null
    $env:OPENWRT_RELEASE = "{{release}}"; $env:OPENWRT_RELEASE_FULL = "{{release_full}}"; docker compose -f build/openwrt/compose.yaml run --rm build

# Build packages, sync, and index into dist/feed/ in one step.
# CI calls this; developers can call individual steps or this combined recipe.
package-feed release="25.12" release_full="25.12.5" extra_arches="":
    just build-packages release={{release}} release_full={{release_full}}
    just sync-feed release={{release}} extra_arches="{{extra_arches}}"
    just index-feed release={{release}}

# Run the full test suite (validate + QEMU smoke test).
# feed_base_url: if set, skips local HTTP server and tests against that URL instead.
#   Local:  (unset) → serves dist/feed/ on 10.0.2.2:8080
#   CI:     feed_base_url="https://github.com/.../releases/download/feed-25.12.5-x86_64"
test feed_base_url="":
    $env:FEED_BASE_URL = "{{feed_base_url}}"; docker compose -f test/openwrt/compose.yaml run --rm test

# Publish dist/feed/<release>/<arch>/ as a GitHub Release (flat asset namespace).
# Tag defaults to feed-<release_full>-<arch>; append -r2 etc. for re-publishes.
# Requires GH_TOKEN or gh auth login. Safe to re-run: skips create if tag exists.
publish-release release="25.12" release_full="25.12.5" arch="x86_64" tag="":
    #!/usr/bin/env bash
    set -euo pipefail
    TAG="{{tag}}"
    [[ -z "$TAG" ]] && TAG="feed-{{release_full}}-{{arch}}"
    gh release view "$TAG" >/dev/null 2>&1 || \
        gh release create "$TAG" --title "$TAG" --notes-file RELEASE.md
    gh release upload "$TAG" "dist/feed/{{release}}/{{arch}}"/* --clobber

# Placeholder for future GitHub Pages documentation publishing (not the feed).
publish-pages:
    @echo "Pages publishing not yet implemented"

# Run static validation only (no QEMU)
validate:
    docker compose -f test/openwrt/compose.yaml run --rm test ./validate.sh

# Build the test harness image
build-test:
    docker compose -f test/openwrt/compose.yaml build

# Run with KVM acceleration (Linux only)
test-kvm:
    docker compose -f test/openwrt/compose.yaml -f test/openwrt/compose.kvm.yaml run --rm test

# Sync built APKs/IPKs into the feed. _all packages are fanned out to extra_arches.
# 25.12: extra_arches="aarch64_cortex-a53 mipsel_24kc ..."
# 24.10: same pattern; x86_64 SDK build produces _all IPKs that work on every arch.
sync-feed release="25.12" extra_arches="":
    bash scripts/sync-apks.sh dist/packages/{{release}}/ dist/feed/{{release}}/ {{extra_arches}}

# Regenerate package index for each arch under dist/feed/<release>/
# APK (25.12): signs packages.adb  — set APK_SIGN_KEY to PEM content in your shell
# IPK (24.10): signs Packages.sig  — set IPK_SIGN_KEY to key content in your shell
# Both keys are optional; omit to produce an unsigned index.
index-feed release="25.12":
    $env:OPENWRT_RELEASE = "{{release}}"; docker compose -f build/openwrt/compose.yaml run --rm index

# Serve the feed locally for testing on http://localhost:<port>/
# Device-side: echo "http://<host-ip>:<port>/25.12/$(cat /etc/apk/arch)/packages.adb" > /etc/apk/repositories.d/local-test.list
serve-feed port="8080":
    python -m http.server {{port}} --directory dist/feed/

# Generate ECDSA P-256 APK signing key pair (OpenWrt 25.12 / APK format).
# Private key → keys/apk-private.pem  (move to T:/netops/ and delete from here)
# Public  key → cprima-homelab-openwrt-packages.pem  (commit to repo)
generate-apk-key:
    mkdir -p keys
    openssl ecparam -name prime256v1 -genkey -noout -out keys/apk-private.pem
    openssl ec -in keys/apk-private.pem -pubout -out cprima-homelab-openwrt-packages.pem
    @echo ""
    @echo "Public key  → cprima-homelab-openwrt-packages.pem (commit this)"
    @echo "Private key → keys/apk-private.pem  (move to T:/netops/, then delete)"

# Generate usign Ed25519 IPK signing key pair (OpenWrt 24.10 / IPK format).
# Private key → keys/ipk-private.key  (move to T:/netops/ and delete from here)
# Public  key → cprima-homelab-openwrt-packages.pub  (commit to repo)
generate-ipk-key:
    mkdir -p keys
    docker run --rm \
        -v "{{justfile_directory()}}/keys:/keys" \
        -v "{{justfile_directory()}}:/out" \
        alpine:3 sh -c " \
            apk add --no-cache cmake build-base git && \
            git clone --depth=1 https://git.openwrt.org/project/usign.git && \
            cd usign && cmake . && make && \
            ./usign -G -s /keys/ipk-private.key -p /out/cprima-homelab-openwrt-packages.pub"
    @echo ""
    @echo "Public key  → cprima-homelab-openwrt-packages.pub (commit this)"
    @echo "Private key → keys/ipk-private.key  (move to T:/netops/, then delete)"

# Remove cached OpenWrt disk images
clean-cache:
    docker volume rm openwrt-packages_openwrt-image-cache

# Remove cached OpenWrt SDK for a specific release (default: 25.12)
# Frees ~700 MB per release. Use before switching releases to avoid holding both SDKs at once.
clean-sdk-cache release="25.12":
    docker volume rm openwrt-packages_openwrt-sdk-{{release}}

# Remove build artifacts
clean:
    Remove-Item -Recurse -Force dist -ErrorAction SilentlyContinue
