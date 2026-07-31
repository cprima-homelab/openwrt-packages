set shell := ["pwsh", "-c"]

openwrt_arch := "x86_64"
caddy_version := "v2.10.2"

# Build Caddy binary for a given OpenWrt architecture (development utility)
build-caddy arch=openwrt_arch:
    docker compose -f build/caddy/compose.yaml run --rm `
        -e OPENWRT_ARCH={{arch}} `
        -e CADDY_VERSION={{caddy_version}} `
        build

# Run the full test suite (validate + QEMU smoke test)
test:
    docker compose run --rm openwrt-test

# Run static validation only (no QEMU)
validate:
    docker compose run --rm openwrt-test ./validate.sh

# Build the harness image
build:
    docker compose build

# Run with KVM acceleration (Linux only)
test-kvm:
    docker compose -f compose.yaml -f compose.kvm.yaml run --rm openwrt-test

# Remove cached OpenWrt disk images
clean-cache:
    docker volume rm openwrt-packages_openwrt-image-cache

# Remove build artifacts
clean:
    Remove-Item -Recurse -Force dist -ErrorAction SilentlyContinue
