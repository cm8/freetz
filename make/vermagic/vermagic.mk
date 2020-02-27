$(call PKG_INIT_BIN, master)
$(PKG)_SOURCE:=$(pkg)-$($(PKG)_VERSION).tar.xz
$(PKG)_SITE:=git@https://github.com/D1W0U/vermagic

$(PKG)_SOURCE_FILE:=$($(PKG)_DIR)/$(pkg).c
$(PKG)_BINARY:=$($(PKG)_DIR)/$(pkg)
$(PKG)_TARGET_BINARY:=$($(PKG)_DEST_DIR)/usr/bin/$(pkg)
$(PKG)_CATEGORY:=Debug helpers

$(PKG_SOURCE_DOWNLOAD)
$(PKG_UNPACKED)
$(PKG_CONFIGURED_NOP)

$($(PKG)_BINARY): $($(PKG)_DIR)/.configured
	$(FREETZ_LD_RUN_PATH) \
		$(TARGET_CC) \
		$(TARGET_CFLAGS) \
		-DUCLIBC_RUNTIME_PREFIX=\"/\" \
		$(VERMAGIC_SOURCE_FILE) -o $@

$($(PKG)_TARGET_BINARY): $($(PKG)_BINARY)
	$(INSTALL_BINARY_STRIP)

$(pkg):

$(pkg)-precompiled: $($(PKG)_TARGET_BINARY)

$(pkg)-clean:
	$(RM) $(VERMAGIC_DIR)$(VERMAGIC_BINARY)

$(pkg)-uninstall:
	$(RM) $(VERMAGIC_TARGET_BINARY)

$(PKG_FINISH)
