$(call PKG_INIT_LIB, 33.4.0)
$(PKG)_DEPENDS_ON  += lua luabit32
$(PKG)_SITE := http://ftp.de.debian.org/debian/pool/main/l/lua-posix
$(PKG)_SOURCE := lua-posix_$($(PKG)_VERSION).orig.tar.gz
$(PKG)_SOURCE_MD5 := b36ff049095f28752caeb0b46144516c

$(PKG)_NAME           := libluaposix
$(PKG)_NETLINK_PATCH  := $($(PKG)_DIR)/ext/posix/sys/socket.c.bak
$(PKG)_BIN_PREFIX     := $($(PKG)_DIR)/ext/posix/.libs/$($(PKG)_NAME)
$(PKG)_LA             := $($(PKG)_BIN_PREFIX).la
$(PKG)_BIN            := $($(PKG)_BIN_PREFIX).so
$(PKG)_BINMAJ         := $($(PKG)_BIN_PREFIX).so.1
$(PKG)_BINARY         := $($(PKG)_BIN_PREFIX).so.1.0.0

$(PKG)_STAGING_LA     := $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib/$($(PKG)_NAME).la
$(PKG)_STAGING_BINARY := $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib/$(notdir $($(PKG)_BINARY))
$(PKG)_STAGING_LUALNK := $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib/lua/posix.so
$(PKG)_STAGING_LUADAT := $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/share/lua/posix

$(PKG)_TARGET_BINARY  := $($(PKG)_TARGET_DIR)/$(notdir $($(PKG)_BINARY))
$(PKG)_TARGET_LUALNK  := $($(PKG)_DEST_DIR)/usr/lib/lua/posix.so
$(PKG)_TARGET_LUADAT  := $($(PKG)_DEST_DIR)/usr/share/lua/posix

# lua.mk explicitly strips version from path, do not define it here
#$(PKG)_LUA_VERSION    := 5.1

$(PKG)_CONFIGURE_PRE_CMDS += $(AUTORECONF)
$(PKG)_CONFIGURE_OPTIONS += --prefix=/usr/
$(PKG)_CONFIGURE_OPTIONS += --enable-shared
$(PKG)_CONFIGURE_OPTIONS += --enable-static
$(PKG)_CONFIGURE_OPTIONS += LUA="$(TARGET_TOOLCHAIN_STAGING_DIR)/usr/bin/lua"$($(PKG)_LUA_VERSION)
$(PKG)_CONFIGURE_OPTIONS += LUA_INCLUDE="-I$(TARGET_TOOLCHAIN_STAGING_DIR)/usr/include/lua"$($(PKG)_LUA_VERSION)
$(PKG)_CONFIGURE_OPTIONS += CPPFLAGS="-I$(TARGET_TOOLCHAIN_STAGING_DIR)/include"
$(PKG)_CONFIGURE_OPTIONS += LDFLAGS="-L$(TARGET_TOOLCHAIN_STAGING_DIR)/usr/lib"

$(PKG_SOURCE_DOWNLOAD)
$(PKG_UNPACKED)
$(PKG_CONFIGURED_CONFIGURE)


$(basename $($(PKG)_NETLINK_PATCH)): $($(PKG)_DIR)/.configured

$($(PKG)_NETLINK_PATCH): $(basename $($(PKG)_NETLINK_PATCH))
	cp -av $< $@
	H=$$(find $(TARGET_TOOLCHAIN_STAGING_DIR) -name netlink.h); \
	grep -o "NETLINK_[[:alnum:]_]*" $@ | while read s ; do \
	grep -q $$s $$H || echo -n '\\|'$$s ; done | cut -b 4- \
	| while read expat ; do grep -v "$$expat" $@ > $< ; done

$($(PKG)_BINARY) $($(PKG)_LA): $($(PKG)_NETLINK_PATCH)
	$(SUBMAKE) -C $(LUAPOSIX_DIR)
	cd $(dir $@); for f in *; do ln -f $$f liblua$$f; done
	mv -f $(LUAPOSIX_BIN) $(LUAPOSIX_BINARY)
	ln -s $(notdir $(LUAPOSIX_BINARY)) $(LUAPOSIX_BINMAJ)
	ln -s $(notdir $(LUAPOSIX_BINMAJ)) $(LUAPOSIX_BIN)

$($(PKG)_STAGING_BINARY): $($(PKG)_BINARY)
	$(INSTALL_LIBRARY_INCLUDE_STATIC)

$($(PKG)_STAGING_LUADAT): $($(PKG)_BINARY)
	$(SUBMAKE) -C $(LUAPOSIX_DIR) install-dist_luaposixDATA \
		DESTDIR="$(TARGET_TOOLCHAIN_STAGING_DIR)"

$($(PKG)_STAGING_LUALNK): $($(PKG)_STAGING_BINARY)
	mkdir -p $(dir $@)
	ln -sf ../$(notdir $<) $@

$($(PKG)_STAGING_LA): $($(PKG)_LA)
	$(INSTALL_FILE)
	$(PKG_FIX_LIBTOOL_LA) $@

$(pkg): $($(PKG)_STAGING_LUALNK) $($(PKG)_STAGING_LA) $($(PKG)_STAGING_LUADAT)


$($(PKG)_TARGET_BINARY): $($(PKG)_STAGING_BINARY)
	$(INSTALL_LIBRARY_STRIP)

$($(PKG)_TARGET_LUADAT): $($(PKG)_STAGING_LUADAT)
	mkdir -p $@ && $(call COPY_USING_TAR,$<,$@)

# point to absolute path based on target root, because
# relation between $< and $@ may vary by configuration
$($(PKG)_TARGET_LUALNK): $($(PKG)_TARGET_BINARY)
	mkdir -p $(dir $@)
	ln -sf $(subst $(LUAPOSIX_DEST_DIR),,$<) $@

$(pkg)-precompiled: $($(PKG)_TARGET_LUALNK) $($(PKG)_TARGET_LUADAT)


$(pkg)-clean:
	-$(SUBMAKE) -C $(LUAPOSIX_DIR) clean
	$(RM) -rvf \
		$(patsubst %.la,%,$(LUAPOSIX_STAGING_LA))* \
		$(LUAPOSIX_STAGING_LUALNK) \
		$(LUAPOSIX_STAGING_LUADAT)

$(pkg)-uninstall:
	$(RM) -vf \
		$(LUAPOSIX_TARGET_BINARY) \
		$(LUAPOSIX_TARGET_LUALNK) \
		$(LUAPOSIX_TARGET_LUADAT)

$(PKG_FINISH)
