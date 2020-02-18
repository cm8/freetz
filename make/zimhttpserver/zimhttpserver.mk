$(call PKG_INIT_BIN, endian)
$(PKG)_BINARY:=$($(PKG)_DIR)/zimHttpServer.pl
$(PKG)_SITE:=git@https://github.com/waynepiekarski/zimHttpServer32
$(PKG)_SOURCE:=$(pkg)-$($(PKG)_VERSION).tar.xz
$(PKG)_TARGET_BINARY:=$($(PKG)_DEST_DIR)/usr/bin/$(pkg)

$(PKG_SOURCE_DOWNLOAD)
$(PKG_UNPACKED)
$(PKG_CONFIGURED_NOP)

$($(PKG)_BINARY): $($(PKG)_DIR)/.configured

$($(PKG)_TARGET_BINARY): $($(PKG)_BINARY)
	chmod 755 $<
	$(INSTALL_FILE)

$(pkg)-precompiled: $($(PKG)_TARGET_BINARY)

$(pkg)-clean:

$(pkg)-uninstall:
	$(RM) $(ZIMHTTPSERVER_TARGET_BINARY)

$(PKG_FINISH)
