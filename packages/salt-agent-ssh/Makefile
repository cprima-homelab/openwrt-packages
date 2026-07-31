include $(TOPDIR)/rules.mk

PKG_NAME:=salt-agent-ssh
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Christian Prior-Mamulyan <cprior@gmail.com>
PKG_LICENSE:=Apache-2.0

include $(INCLUDE_DIR)/package.mk

define Package/salt-agent-ssh
  SECTION:=admin
  CATEGORY:=Administration
  TITLE:=Salt agent for OpenWrt SSH transport
  DEPENDS:=+openssh-server
  PKGARCH:=all
endef

define Package/salt-agent-ssh/description
  Configures an OpenWrt device for Salt management via salt-ssh.
  Not yet implemented — stub establishing the naming pattern alongside
  salt-agent-ubus.
endef

define Build/Compile
endef

define Package/salt-agent-ssh/install
endef

$(eval $(call BuildPackage,salt-agent-ssh))
