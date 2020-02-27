$(call PKG_INIT_BIN, 0.9)
$(PKG)_TARGET_BINARY := $($(PKG)_DEST_DIR)/usr/bin/$(pkg)

$(PKG_UNPACKED)

.PHONY: $($(PKG)_TARGET_BINARY)
$($(PKG)_TARGET_BINARY):
	chmod 755 $@

$(pkg)-precompiled: $($(PKG)_TARGET_BINARY)

$(pkg)-clean:

$(pkg)-uninstall:
	$(RM) $(ZIMRECOMPRESS_TARGET_BINARY)

$(PKG_FINISH)
