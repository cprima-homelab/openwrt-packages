#!/usr/bin/env bash
set -euo pipefail

# Download and extract the OpenWrt SDK on first run; subsequent runs use the cached volume.
if [ ! -f /builder/Makefile ]; then
    echo "[build/openwrt] SDK not found — running setup.sh..."
    cd /builder
    bash /builder/setup.sh
fi

cd /builder

# Generate a default SDK config if not present (avoids interactive menuconfig).
[ -f .config ] || make defconfig V=s

# Link salt-* and luci-* packages from /src/packages/ into the SDK tree.
# caddy is excluded: it is a Stage 2 download-and-package job, not a compile job.
for pkg in /src/packages/salt-* /src/packages/luci-*; do
    [ -d "$pkg" ] || continue
    target="/builder/package/$(basename "$pkg")"
    [ -L "$target" ] && rm "$target"
    ln -sf "$pkg" "$target"
done

# Derive make targets.
targets=()
for pkg in /src/packages/salt-* /src/packages/luci-*; do
    [ -d "$pkg" ] || continue
    targets+=("package/$(basename "$pkg")/compile")
done

echo "[build/openwrt] Building: ${targets[*]}"
make "${targets[@]}" V=s

# Copy APKs from bin/packages/<arch>/ preserving the arch subdirectory.
# bin/targets/ contains runtime libs already on the device — skip them.
find /builder/bin/packages -name '*.apk' -o -name '*.ipk' | while IFS= read -r f; do
    arch=$(echo "$f" | sed 's|.*/packages/\([^/]*\)/.*|\1|')
    mkdir -p "/out/$arch"
    cp "$f" "/out/$arch/"
done
echo "[build/openwrt] Done. Output written to /out/"
