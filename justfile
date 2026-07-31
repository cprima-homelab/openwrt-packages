set shell := ["pwsh", "-c"]

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
