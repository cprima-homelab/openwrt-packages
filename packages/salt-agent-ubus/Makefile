include $(TOPDIR)/rules.mk

PKG_NAME:=salt-agent-ubus
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

PKG_MAINTAINER:=Christian Prior-Mamulyan <cprior@gmail.com>
PKG_LICENSE:=Apache-2.0

include $(INCLUDE_DIR)/package.mk

define Package/salt-agent-ubus
  SECTION:=admin
  CATEGORY:=Administration
  TITLE:=Salt agent for OpenWrt ubus JSON-RPC transport
  DEPENDS:=+rpcd +uhttpd-mod-ubus
  PKGARCH:=all
endef

define Package/salt-agent-ubus/description
  Creates a salt-agent system user with rpcd login and installs ACL
  rules granting scoped access to UCI, network, and system ubus
  objects via the JSON-RPC API. Used by the saltext-ubus Salt extension
  to manage OpenWrt devices over HTTPS instead of SSH.
endef

define Build/Compile
endef

define Package/salt-agent-ubus/install
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/usr/share/rpcd/acl.d/salt-agent-ubus.json \
		$(1)/usr/share/rpcd/acl.d/salt-agent-ubus.json
endef

define Package/salt-agent-ubus/postinst
#!/bin/sh
# Post-install: create salt-agent system user and rpcd login

set -e

# Create system user if it does not exist
if ! grep -q "^salt-agent:" /etc/passwd; then
    # Find next free system uid (scan 999 down to 100)
    NEW_UID=""
    uid=999
    while [ "$$uid" -ge 100 ]; do
        if ! grep -q "^[^:]*:[^:]*:$${uid}:" /etc/passwd; then
            NEW_UID=$$uid
            break
        fi
        uid=$$((uid - 1))
    done

    if [ -z "$$NEW_UID" ]; then
        echo "salt-agent-ubus: ERROR no free uid in 100-999" >&2
        exit 1
    fi

    echo "salt-agent:x:$${NEW_UID}:$${NEW_UID}:salt-agent:/home/salt-agent:/bin/false" >> /etc/passwd
    echo "salt-agent:x:$${NEW_UID}:" >> /etc/group
    echo "salt-agent:!:0:0:99999:7:::" >> /etc/shadow
    mkdir -p /home/salt-agent
    echo "salt-agent-ubus: created system user 'salt-agent' (uid $${NEW_UID})"
    echo "salt-agent-ubus: run 'passwd salt-agent' to set a password"
fi

# Add rpcd login if it does not exist
FOUND=0
i=0
while uci -q get "rpcd.@login[$$i].username" >/dev/null 2>&1; do
    if [ "$$(uci -q get "rpcd.@login[$$i].username")" = "salt-agent" ]; then
        FOUND=1
        break
    fi
    i=$$((i + 1))
done

if [ "$$FOUND" = "0" ]; then
    uci add rpcd login >/dev/null
    uci set "rpcd.@login[-1].username=salt-agent"
    uci set "rpcd.@login[-1].password=$$(printf '$$p$$salt-agent')"
    uci add_list "rpcd.@login[-1].read=saltext-uci"
    uci add_list "rpcd.@login[-1].write=saltext-uci"
    uci commit rpcd
    echo "salt-agent-ubus: added rpcd login for 'salt-agent'"
fi

/etc/init.d/rpcd restart

exit 0
endef

define Package/salt-agent-ubus/postrm
#!/bin/sh
# Post-remove: remove rpcd login (keep system user for safety)

set -e

# Remove rpcd login for salt-agent
i=0
while uci -q get "rpcd.@login[$$i].username" >/dev/null 2>&1; do
    if [ "$$(uci -q get "rpcd.@login[$$i].username")" = "salt-agent" ]; then
        uci delete "rpcd.@login[$$i]"
        uci commit rpcd
        echo "salt-agent-ubus: removed rpcd login for 'salt-agent'"
        break
    fi
    i=$$((i + 1))
done

/etc/init.d/rpcd restart

# Note: system user 'salt-agent' in /etc/passwd is intentionally NOT removed.
# To fully remove: sed -i '/^salt-agent:/d' /etc/passwd /etc/shadow /etc/group
#                  rm -rf /home/salt-agent

exit 0
endef

$(eval $(call BuildPackage,salt-agent-ubus))
