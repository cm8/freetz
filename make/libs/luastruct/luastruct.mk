LUASTRUCT_GIT_REPOSITORY := https://github.com/iryont/lua-struct

$(call PKG_INIT_BIN, $(if $(FREETZ_LIB_LUASTRUCT_VERSION_LATEST_GIT),$(call \
	git-get-latest-revision,$(LUASTRUCT_GIT_REPOSITORY),master),85a2b20544))

$(PKG)_DEPENDS_ON  += lua
$(PKG)_SOURCE      := $(pkg)-$($(PKG)_VERSION).tar.xz
$(PKG)_SITE        := git_no_submodules@$($(PKG)_GIT_REPOSITORY)

$(PKG)_BUILD_PREREQ += git
$(PKG)_BUILD_PREREQ_HINT := Hint: on Debian-like systems this binary is provided by the git package (sudo apt-get install git)

$(PKG)_REBUILD_SUBOPTS += FREETZ_LIB_LUASTRUCT_VERSION_LATEST_TESTED
$(PKG)_REBUILD_SUBOPTS += FREETZ_LIB_LUASTRUCT_VERSION_LATEST_GIT

$(PKG)_BINARY         := $($(PKG)_DIR)/struct.lua
$(PKG)_STAGING_BINARY := $(TARGET_TOOLCHAIN_STAGING_DIR)/usr/share/lua/$(notdir $($(PKG)_BINARY))
$(PKG)_TARGET_BINARY  := $($(PKG)_DEST_DIR)/usr/share/lua/$(notdir $($(PKG)_BINARY))

$(PKG_SOURCE_DOWNLOAD)
$(PKG_UNPACKED)
$(PKG_CONFIGURED_NOP)


$($(PKG)_BINARY): $($(PKG)_DIR)/.configured
	@chmod 755 $@

$($(PKG)_STAGING_BINARY): $($(PKG)_BINARY)
	$(INSTALL_FILE)

$($(PKG)_TARGET_BINARY): $($(PKG)_STAGING_BINARY)
	$(INSTALL_FILE)


$(pkg): $($(PKG)_STAGING_BINARY)

$(pkg)-precompiled: $($(PKG)_TARGET_BINARY)

$(pkg)-clean:
	$(RM) $(LUASTRUCT_STAGING_BINARY)

$(pkg)-uninstall: $(pkg)-clean
	$(RM) $(LUASTRUCT_TARGET_BINARY)


$(PKG_FINISH)
