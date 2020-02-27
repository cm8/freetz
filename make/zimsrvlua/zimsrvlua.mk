$(call PKG_INIT_BIN, 0.1)
$(PKG)_REBUILD_SUBOPTS  += FREETZ_PACKAGE_ZIMSRVLUA_STATIC
$(PKG)_DEPENDS_ON       := luaposix luastruct

$(PKG)_BINARY           := $($(PKG)_DIR)/zimsrv.lua
$(PKG)_TARGET_BINARY    := $($(PKG)_DEST_USR_BIN)/zimsrvlua

$(PKG_LOCALSOURCE_PACKAGE)
$(PKG_CONFIGURED_NOP)

$($(PKG)_BINARY): $($(PKG)_DIR)/.configured

ifeq ($(strip $(FREETZ_PACKAGE_ZIMSRVLUA_STATIC)),y)
$(PKG)_HOST_DEPENDS_ON  := luastatic-host
$(PKG)_BINARY_STATIC    := $($(PKG)_DIR)/zimsrv
$(PKG)_B_INCL_STRUCT    := $($(PKG)_BINARY:%.lua=%)_incl_struct.lua
$(PKG)_STRUCT_LUA       := $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/share/lua/struct.lua

$($(PKG)_B_INCL_STRUCT): $($(PKG)_BINARY)
	sed -ne 1p $< > $@
	sed -e '1s,^#!.*,,' -e '/^return struct$$/d' $(ZIMSRVLUA_STRUCT_LUA) >> $@
	sed -e 1d $< >> $@
	@chmod 755 $@

$($(PKG)_BINARY_STATIC): $($(PKG)_B_INCL_STRUCT)
	CC=$(TARGET_CC) $(TOOLS_DIR)/luastatic $< \
	$(addprefix $(TARGET_TOOLCHAIN_STAGING_DIR)/lib/liblua,.a bit32.a posix.a) \
	-I$(TARGET_TOOLCHAIN_STAGING_DIR)/usr/include/lua \
	-Wl,--allow-multiple-definition -lcrypt -o $@

$($(PKG)_TARGET_BINARY): $($(PKG)_BINARY_STATIC)
	$(INSTALL_BINARY_STRIP)
else
$($(PKG)_TARGET_BINARY): $($(PKG)_BINARY)
	$(INSTALL_BINARY)
endif

$(pkg):

$(pkg)-precompiled: $($(PKG)_TARGET_BINARY)

$(pkg)-clean:
	$(RM) $(ZIMSRVLUA_BINARY_STATIC) $(ZIMSRVLUA_B_INCL_STRUCT)

$(pkg)-dirclean:
	$(RM) -r $(ZIMSRVLUA_DIR)

$(pkg)-uninstall: $(pkg)-dirclean
	$(RM) $(ZIMSRVLUA_TARGET_BINARY)

$(PKG_FINISH)
