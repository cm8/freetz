pkg := luastatic
PKG := LUASTATIC_HOST

$(PKG)_VERSION       := 0.0.10
$(PKG)_SOURCE        := $(pkg)-$($(PKG)_VERSION).tar.gz
$(PKG)_SOURCE_DL     := $($(PKG)_VERSION).tar.gz
$(PKG)_SOURCE_SHA256 := da102c8fb61a66ffb6421cee3120bbb56cf548607d394f00896939109633e40e
$(PKG)_SITE          := https://www.github.com/ers35/$(pkg)/archive
#$(PKG)_SITE         := git_no_submodules@https://www.github.com/ers35/$(pkg)

$(PKG)_MAKE_DIR      := $(TOOLS_DIR)/make/$(pkg)-host
$(PKG)_DIR           := $(TOOLS_SOURCE_DIR)/$(pkg)-$($(PKG)_VERSION)

$(DL_DIR)/$($(PKG)_SOURCE): | $(DL_DIR)
	$(DL_TOOL) $(dir $@) $(LUASTATIC_HOST_SOURCE_DL) $(LUASTATIC_HOST_SITE) $(LUASTATIC_HOST_SOURCE_SHA256)
	mv $(dir $@)/$(LUASTATIC_HOST_SOURCE_DL) $@

$($(PKG)_DIR)/.unpacked: $(DL_DIR)/$($(PKG)_SOURCE) | $(TOOLS_SOURCE_DIR) $(UNPACK_TARBALL_PREREQUISITES)
	$(call UNPACK_TARBALL,$(DL_DIR)/$(LUASTATIC_HOST_SOURCE),$(TOOLS_SOURCE_DIR))
	$(call APPLY_PATCHES,$(LUASTATIC_HOST_MAKE_DIR)/patches,$(LUASTATIC_HOST_DIR))
	touch $@

$($(PKG)_DIR)/$(pkg): $($(PKG)_DIR)/.unpacked
	$(MAKE) -C $(dir $@) $(notdir $@)

$(TOOLS_DIR)/$(pkg): $($(PKG)_DIR)/$(pkg)
	$(INSTALL_FILE)

$(pkg)-host-source: $(DL_DIR)/$($(PKG)_SOURCE)

$(pkg)-host-unpacked: $($(PKG)_DIR)/.unpacked

$(pkg)-host: $(TOOLS_DIR)/$(pkg)

$(pkg)-host-clean:

$(pkg)-host-dirclean:
	$(RM) -r $(LUASTATIC_HOST_DIR)

$(pkg)-host-distclean: $(pkg)-host-dirclean
	$(RM) $(TOOLS_DIR)/$(subst -host-distclean,,$@)
