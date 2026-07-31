include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-salt-openwrt
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Christian Prior-Mamulyan <cprior@gmail.com>
PKG_LICENSE:=Apache-2.0

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-salt-openwrt
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI app for Salt agent configuration
  DEPENDS:=+luci-base +salt-openwrt
  PKGARCH:=all
endef

define Package/luci-app-salt-openwrt/description
  Configure Salt agent mode (audit/oneshot/autoverified/humanreviewed),
  enable/disable, rollback timeout, and view last run status from the
  LuCI web interface.
endef

define Build/Compile
endef

define Package/luci-app-salt-openwrt/install
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./files/usr/share/luci/menu.d/luci-app-salt-openwrt.json \
		$(1)/usr/share/luci/menu.d/luci-app-salt-openwrt.json

	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/usr/share/rpcd/acl.d/luci-app-salt-openwrt.json \
		$(1)/usr/share/rpcd/acl.d/luci-app-salt-openwrt.json

	$(INSTALL_DIR) $(1)/usr/share/ucitrack
	$(INSTALL_DATA) ./files/usr/share/ucitrack/luci-app-salt-openwrt.json \
		$(1)/usr/share/ucitrack/luci-app-salt-openwrt.json

	$(INSTALL_DIR) $(1)/www/luci-static/resources/view
	$(INSTALL_DATA) ./files/www/luci-static/resources/view/salt-openwrt.js \
		$(1)/www/luci-static/resources/view/salt-openwrt.js
endef

$(eval $(call BuildPackage,luci-app-salt-openwrt))
