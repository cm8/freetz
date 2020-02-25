$(call PKG_INIT_LIB, 5.3.0)
$(PKG)_DEPENDS_ON  += lua
$(PKG)_SOURCE      := lua-bit32_$($(PKG)_VERSION).orig.tar.gz
$(PKG)_SOURCE_MD5  := 3588a0acab43f4e0e537bfc93038a2ae
$(PKG)_SITE        := http://ftp.de.debian.org/debian/pool/main/l/lua-bit32

$(PKG)_NAME           := libluabit32
$(PKG)_BIN_PREFIX     := $($(PKG)_DIR)/$($(PKG)_NAME)
$(PKG)_BIN            := $($(PKG)_BIN_PREFIX).so
$(PKG)_BINMAJ         := $($(PKG)_BIN_PREFIX).so.1
$(PKG)_BINARY         := $($(PKG)_BIN_PREFIX).so.1.0.0

$(PKG)_STAGING_BINARY := $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib/$(notdir $($(PKG)_BINARY))
$(PKG)_STAGING_LUALNK := $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib/lua/bit32.so

$(PKG)_TARGET_BINARY  := $($(PKG)_TARGET_DIR)/$(notdir $($(PKG)_BINARY))
$(PKG)_TARGET_LUALNK  := $($(PKG)_DEST_USR_LIB)/lua/bit32.so

$(PKG_SOURCE_DOWNLOAD)
$(PKG_UNPACKED)
$(PKG_CONFIGURED_NOP)


$($(PKG)_BINARY): $($(PKG)_DIR)/.configured
	$(SUBMAKE) -C $(LUABIT32_DIR) \
		CC="$(TARGET_CC)" \
		CFLAGS="-I$(TARGET_TOOLCHAIN_STAGING_DIR)/usr/include/lua $(TARGET_CFLAGS)" \
		LDFLAGS="-L$(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib" \
		AR="$(TARGET_AR) rcu" \
		RANLIB="$(TARGET_RANLIB)" \
		all

$($(PKG)_STAGING_BINARY): $($(PKG)_BINARY)
	$(INSTALL_LIBRARY_INCLUDE_STATIC)

$($(PKG)_STAGING_LUALNK): $($(PKG)_STAGING_BINARY)
	mkdir -p $(dir $@)
	ln -sf ../$(notdir $<) $@

$(pkg): $($(PKG)_STAGING_LUALNK)


$($(PKG)_TARGET_BINARY): $($(PKG)_STAGING_BINARY)
	$(INSTALL_LIBRARY_STRIP)

# point to absolute path based on target root, because
# relation between $< and $@ may vary by configuration
$($(PKG)_TARGET_LUALNK): $($(PKG)_TARGET_BINARY)
	mkdir -p $(dir $@)
	ln -sf $(subst $(LUABIT32_DEST_DIR),,$<) $@

$(pkg)-precompiled: $($(PKG)_TARGET_LUALNK)


$(pkg)-clean:
	-$(SUBMAKE) -C $(LUABIT32_DIR) clean
	$(RM) -f $(wildcard \
		$(dir $(LUABIT32_STAGING_BINARY))/$(LUABIT32_NAME)*) \
		$(LUABIT32_STAGING_LUALNK)

$(pkg)-uninstall:
	$(RM) -f $(wildcard \
		$(dir $(LUABIT32_TARGET_BINARY))/$(LUABIT32_NAME)*) \
		$(LUABIT32_TARGET_LUALNK)

$(PKG_FINISH)
