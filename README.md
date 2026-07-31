# openwrt-packages

Custom OpenWrt package feed.

Packages:

- `caddy` — Caddy web server with DNS-01 ACME support (cloudflare, inwx)
- `salt-agent-ubus` — rpcd ACL and user setup for Salt ubus JSON-RPC transport

## Feed usage

```bash
echo 'src-git cprima-homelab https://github.com/cprima-homelab/openwrt-packages.git' \
  >> feeds.conf.default

./scripts/feeds update cprima-homelab
./scripts/feeds install -a -p cprima-homelab
```

## Build

```bash
make package/caddy/compile V=s
make package/salt-agent-ubus/compile V=s
```

## Package versioning

`PKG_VERSION` tracks the upstream application version.
`PKG_RELEASE` tracks OpenWrt packaging changes independently.

```
2.10.0-1  →  2.10.1-1   upstream changed
2.10.0-1  →  2.10.0-2   packaging only changed
```
