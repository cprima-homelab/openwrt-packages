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
CADDY_HASH_amd64:=0000000000000000000000000000000000000000000000000000000000000000
CADDY_HASH_arm64:=0000000000000000000000000000000000000000000000000000000000000000
CADDY_HASH_armv5:=0000000000000000000000000000000000000000000000000000000000000000
CADDY_HASH_armv6:=0000000000000000000000000000000000000000000000000000000000000000
CADDY_HASH_armv7:=0000000000000000000000000000000000000000000000000000000000000000
CADDY_HASH_riscv64:=0000000000000000000000000000000000000000000000000000000000000000

# Gap-fill hashes (caddy_$(PKG_VERSION)_linux_<arch>.tar.gz)
CADDY_HASH_386:=0000000000000000000000000000000000000000000000000000000000000000
CADDY_HASH_mips:=0000000000000000000000000000000000000000000000000000000000000000
CADDY_HASH_mips_softfloat:=0000000000000000000000000000000000000000000000000000000000000000
CADDY_HASH_mipsle:=0000000000000000000000000000000000000000000000000000000000000000
CADDY_HASH_mips64:=0000000000000000000000000000000000000000000000000000000000000000
CADDY_HASH_mips64le:=0000000000000000000000000000000000000000000000000000000000000000
CADDY_HASH_loong64:=0000000000000000000000000000000000000000000000000000000000000000

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
