include $(TOPDIR)/rules.mk

PKG_NAME:=caddy
PKG_VERSION:=2.10.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Christian Prior-Mamulyan <cprior@gmail.com>
PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE

# Caddy is built via xcaddy to include DNS provider plugins.
# Standard Go toolchain from OpenWrt SDK + xcaddy host tool.
PKG_BUILD_DEPENDS:=golang/host

# DNS plugins baked into the binary at build time
CADDY_DNS_PLUGINS:= \
	github.com/caddy-dns/cloudflare \
	github.com/caddy-dns/inwx

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/caddy
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Caddy web server with DNS-01 ACME support
  URL:=https://caddyserver.com
  DEPENDS:=@(aarch64||arm)
endef

define Package/caddy/description
  Caddy is an automatic HTTPS web server. This build includes DNS provider
  plugins for DNS-01 ACME certificate challenges (Cloudflare, INWX), making
  it suitable as a TLS-terminating reverse proxy on OpenWrt devices.
endef

define Package/caddy/conffiles
/etc/caddy/Caddyfile
endef

define Build/Compile
	$(eval XCADDY_WITH := $(foreach p,$(CADDY_DNS_PLUGINS),--with $(p)))
	GOOS=linux \
	GOARCH=$(GOARCH) \
	GOARM=$(GOARM) \
	xcaddy build v$(PKG_VERSION) \
		$(XCADDY_WITH) \
		--output $(PKG_BUILD_DIR)/caddy
endef

define Package/caddy/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/caddy $(1)/usr/bin/caddy

	$(INSTALL_DIR) $(1)/etc/caddy
	$(INSTALL_CONF) ./files/Caddyfile $(1)/etc/caddy/Caddyfile

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/caddy.init $(1)/etc/init.d/caddy
endef

$(eval $(call BuildPackage,caddy))
