include $(TOPDIR)/rules.mk

PKG_NAME:=caddy
PKG_VERSION:=2.10.2
PKG_RELEASE:=1

# Both upstream Caddy and the gap-fill builder publish tarballs with the same
# naming convention: caddy_<version>_linux_<arch>.tar.gz (flat, binary at root).
# The only difference between sources is the base URL, set per-arch below.
CADDY_UPSTREAM_BASE:=https://github.com/caddyserver/caddy/releases/download/v$(PKG_VERSION)
CADDY_RELEASE_BASE:=https://github.com/cprima-homelab/openwrt-packages/releases/download/caddy-$(PKG_VERSION)-$(PKG_RELEASE)

# SHA256 hashes of the downloaded tarballs.
# Populate from:
#   dist/<version>/SHA256SUMS          (gap-fill: after: just build-caddy-app)
#   upstream release SHA256SUMS file   (upstream: from caddyserver/caddy releases page)
#
# DO NOT fetch SHA256SUMS at build time. The recipe is the verifier; fetching
# both binary and hash from the same mutable Release defeats verification.
# Git history of packages/caddy/ is the package provenance record.

# Upstream Caddy hashes (caddy_$(PKG_VERSION)_linux_<arch>.tar.gz)
# Source: github.com/caddyserver/caddy/releases/download/v$(PKG_VERSION)/caddy_$(PKG_VERSION)_checksums.txt
# Computed as SHA256 (OpenWrt PKG_HASH format) by streaming each tarball through sha256sum.
CADDY_HASH_amd64:=5c218bc34c9197369263da7e9317a83acdbd80ef45d94dca5eff76e727c67cdd
CADDY_HASH_arm64:=501e955fa634c5aab63247458c3ac655cfdd6cbf1e0436528f41248451c190ac
CADDY_HASH_armv5:=cce87ffc68f9e54b3797382955dff7a460135d0676aeb9d78965393a8a7dec4b
CADDY_HASH_armv6:=bc86e655b2661c6a90b7f5026d15743b9a1171070ac46e8202d7fa0c63056f01
CADDY_HASH_armv7:=e6c84396091451a23283f66c8ef3cbe296b5be3c34f9feecdb387000811996d6
CADDY_HASH_riscv64:=f2a28e3afd73d2611ae2a4e42a0cbafd9891f2922bc406fcdb4901c91ea8adeb

# Gap-fill hashes (caddy_$(PKG_VERSION)_linux_<arch>.tar.gz)
# Source: dist/caddy/$(PKG_VERSION)/SHA256SUMS  (produced by: just build-caddy-app)
CADDY_HASH_386:=f23a84fd4a3552c955ca3ca64a7c548ad8cbcbb4f232043b89fe124a14213ce2
CADDY_HASH_mips:=cc973b8dc3c189d34bb2fcf505a3210ad98d984f61d106ca2daa8243237a3aab
CADDY_HASH_mips_softfloat:=0b9e8c7c910afd3b2c366aab74a9ccb76a8000ad6a36e5968e8f97374f2f44b2
CADDY_HASH_mipsle:=4912ad8712e16731a028264e32680bc498a04d5bb077e81a1c5996d8c32c80a6
CADDY_HASH_mips64:=b1793bd6bea93293af44c0c9334838acc0991240b56a02a017181cd70f824b54
CADDY_HASH_mips64le:=784fa892cde62985e6b6738f8055c81f93b3a3017dd84062ec598ba2abdb1928
CADDY_HASH_loong64:=b2909fd621efe3afe6d77af9c7581c4b561b6c42355c3fde2f15f46bfee22496

# Map OpenWrt ARCH_PACKAGES → tarball arch suffix + hash + source URL.
# CADDY_GOARCH becomes the arch component of the tarball filename.
# CADDY_SOURCE_URL selects upstream or gap-fill; PKG_SOURCE is identical for both.
ifeq ($(ARCH),x86_64)
  CADDY_GOARCH:=linux_amd64            # [upstream]
  PKG_HASH:=$(CADDY_HASH_amd64)
  CADDY_SOURCE_URL:=$(CADDY_UPSTREAM_BASE)
else ifneq (,$(findstring i386_,$(ARCH)))
  CADDY_GOARCH:=linux_386              # [gap-fill]
  PKG_HASH:=$(CADDY_HASH_386)
  CADDY_SOURCE_URL:=$(CADDY_RELEASE_BASE)
else ifneq (,$(findstring aarch64,$(ARCH)))
  CADDY_GOARCH:=linux_arm64            # [upstream]
  PKG_HASH:=$(CADDY_HASH_arm64)
  CADDY_SOURCE_URL:=$(CADDY_UPSTREAM_BASE)
else ifeq ($(ARCH),arm_arm926ej-s)
  CADDY_GOARCH:=linux_armv5            # [upstream] verify coverage
  PKG_HASH:=$(CADDY_HASH_armv5)
  CADDY_SOURCE_URL:=$(CADDY_UPSTREAM_BASE)
else ifeq ($(ARCH),arm_arm1176jzf-s_vfp)
  CADDY_GOARCH:=linux_armv6            # [upstream] verify coverage
  PKG_HASH:=$(CADDY_HASH_armv6)
  CADDY_SOURCE_URL:=$(CADDY_UPSTREAM_BASE)
else ifneq (,$(findstring arm_,$(ARCH)))
  CADDY_GOARCH:=linux_armv7            # [upstream] all remaining arm_*
  PKG_HASH:=$(CADDY_HASH_armv7)
  CADDY_SOURCE_URL:=$(CADDY_UPSTREAM_BASE)
else ifeq ($(ARCH),riscv64_generic)
  CADDY_GOARCH:=linux_riscv64          # [upstream]
  PKG_HASH:=$(CADDY_HASH_riscv64)
  CADDY_SOURCE_URL:=$(CADDY_UPSTREAM_BASE)
else ifeq ($(ARCH),loongarch64_generic)
  CADDY_GOARCH:=linux_loong64          # [gap-fill]
  PKG_HASH:=$(CADDY_HASH_loong64)
  CADDY_SOURCE_URL:=$(CADDY_RELEASE_BASE)
else ifeq ($(ARCH),mips_mips32)
  CADDY_GOARCH:=linux_mips_softfloat   # [gap-fill] softfloat
  PKG_HASH:=$(CADDY_HASH_mips_softfloat)
  CADDY_SOURCE_URL:=$(CADDY_RELEASE_BASE)
else ifneq (,$(findstring mips64el_,$(ARCH)))
  CADDY_GOARCH:=linux_mips64le         # [gap-fill]
  PKG_HASH:=$(CADDY_HASH_mips64le)
  CADDY_SOURCE_URL:=$(CADDY_RELEASE_BASE)
else ifneq (,$(findstring mips64_,$(ARCH)))
  CADDY_GOARCH:=linux_mips64           # [gap-fill]
  PKG_HASH:=$(CADDY_HASH_mips64)
  CADDY_SOURCE_URL:=$(CADDY_RELEASE_BASE)
else ifneq (,$(findstring mipsel_,$(ARCH)))
  CADDY_GOARCH:=linux_mipsle           # [gap-fill]
  PKG_HASH:=$(CADDY_HASH_mipsle)
  CADDY_SOURCE_URL:=$(CADDY_RELEASE_BASE)
else ifneq (,$(findstring mips_,$(ARCH)))
  CADDY_GOARCH:=linux_mips             # [gap-fill] hardfloat
  PKG_HASH:=$(CADDY_HASH_mips)
  CADDY_SOURCE_URL:=$(CADDY_RELEASE_BASE)
endif

PKG_SOURCE:=caddy_$(PKG_VERSION)_$(CADDY_GOARCH).tar.gz
PKG_SOURCE_URL:=$(CADDY_SOURCE_URL)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/caddy
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Fast, multi-platform web server with automatic HTTPS
  URL:=https://caddyserver.com
endef

define Package/caddy/description
  Caddy web server with automatic HTTPS. Includes DNS challenge providers for
  Cloudflare and INWX. Upstream architectures use official Caddy releases;
  gap-fill architectures (mips, mipsle, mips64, mips64le, loong64, 386) use
  cprima-homelab/openwrt-packages Stage 1 builds.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(TAR) -xzf $(DL_DIR)/$(PKG_SOURCE) -C $(PKG_BUILD_DIR) caddy
endef

define Build/Compile
endef

define Package/caddy/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/caddy $(1)/usr/bin/caddy
endef

$(eval $(call BuildPackage,caddy))
