# Feed release

## Packages

<!-- List package versions included in this release, e.g.:
- caddy 2.10.2-r1
- luci-app-salt-openwrt 0.1.0-r1
- salt-agent-ubus 0.1.0-r1
-->

## Signing key

IPK (OpenWrt 24.10):

```
untrusted comment: public key 4226e3691a70c759
RWRCJuNpGnDHWU34dPLw+UX7ScYD+KA0sO3cZBCK+zyH9J9z4D0aPiS/
```

Install on device:

```sh
mkdir -p /etc/opkg/keys
cat > /etc/opkg/keys/4226e3691a70c759 <<'EOF'
untrusted comment: public key 4226e3691a70c759
RWRCJuNpGnDHWU34dPLw+UX7ScYD+KA0sO3cZBCK+zyH9J9z4D0aPiS/
EOF
```

## Feed configuration

Replace `<tag>` with this release tag.

**OpenWrt 25.12 (APK):**

```sh
echo "https://github.com/cprima-homelab/openwrt-packages/releases/download/<tag>/packages.adb" \
  > /etc/apk/repositories.d/cprima-homelab.list
apk update
```

**OpenWrt 24.10 (IPK):**

```sh
echo "src/gz cprima-homelab https://github.com/cprima-homelab/openwrt-packages/releases/download/<tag>" \
  >> /etc/opkg/customfeeds.conf
opkg update
```

## Build provenance

<!-- CI fills these in:
- Git commit: <sha>
- Build date: <date>
- Workflow run: <url>
-->
