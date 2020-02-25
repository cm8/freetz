pkg := luastatic-host
PKG := LUASTATIC_HOST

$(PKG)_BIN           := luastatic
$(PKG)_VERSION       := 0.0.10
$(PKG)_SOURCE        := $($(PKG)_BIN)-$($(PKG)_VERSION).tar.gz
$(PKG)_SOURCE_SHA256 := da102c8fb61a66ffb6421cee3120bbb56cf548607d394f00896939109633e40e
$(PKG)_SITE          := https://www.github.com/ers35/$($(PKG)_BIN)/archive
#$(PKG)_SITE         := git_no_submodules@https://www.github.com/ers35/$($(PKG)_BIN)

$(PKG)_MAKE_DIR      := $(TOOLS_DIR)/make/$(pkg)
$(PKG)_DIR           := $(TOOLS_SOURCE_DIR)/$($(PKG)_BIN)-$($(PKG)_VERSION)

$(DL_DIR)/$($(PKG)_SOURCE): | $(DL_DIR)
	$(DL_TOOL) $(DL_DIR) $(LUASTATIC_HOST_VERSION).tar.gz $(LUASTATIC_HOST_SITE) $(LUASTATIC_HOST_SOURCE_SHA256)
	mv $(DL_DIR)/$(LUASTATIC_HOST_VERSION).tar.gz $@

$($(PKG)_DIR)/.unpacked: $(DL_DIR)/$($(PKG)_SOURCE) | $(TOOLS_SOURCE_DIR) $(UNPACK_TARBALL_PREREQUISITES)
	$(call UNPACK_TARBALL,$<,$(TOOLS_SOURCE_DIR))
	$(call APPLY_PATCHES,$(LUASTATIC_HOST_MAKE_DIR)/patches,$(dir $@))
	touch $@

$($(PKG)_DIR)/$($(PKG)_BIN): $($(PKG)_DIR)/.unpacked
	$(MAKE) -C $(dir $@) $(notdir $@)

$(TOOLS_DIR)/$($(PKG)_BIN): $($(PKG)_DIR)/$($(PKG)_BIN)
	$(INSTALL_FILE)

$(pkg)-source: $(DL_DIR)/$($(PKG)_SOURCE)

$(pkg)-unpacked: $($(PKG)_DIR)/.unpacked

$(pkg): $(TOOLS_DIR)/$($(PKG)_BIN)

$(pkg)-clean:

$(pkg)-dirclean:
	$(RM) -r $(LUASTATIC_HOST_DIR)

$(pkg)-distclean: $(pkg)-dirclean
	$(RM) $(TOOLS_DIR)/$(LUASTATIC_HOST_BIN)
