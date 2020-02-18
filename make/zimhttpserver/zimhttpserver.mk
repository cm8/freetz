ZIMHTTPSERVER_GIT_REPOSITORY := https://github.com/waynepiekarski/zimHttpServer32
$(call PKG_INIT_BIN, $(if $(FREETZ_PACKAGE_ZIMHTTPSERVER_VERSION_LATEST_GIT),$(call \
	git-get-latest-revision,$(ZIMHTTPSERVER_GIT_REPOSITORY),endian),bcac442183))

$(PKG)_BINARY := $($(PKG)_DIR)/zimHttpServer.pl
$(PKG)_SITE := git@$($(PKG)_GIT_REPOSITORY)
$(PKG)_SOURCE := $(pkg)-$($(PKG)_VERSION).tar.xz
$(PKG)_TARGET_BINARY := $($(PKG)_DEST_DIR)/usr/bin/$(pkg)

$(PKG)_BUILD_PREREQ += git
$(PKG)_BUILD_PREREQ_HINT := Hint: on debian-like systems "sudo apt-get install git"

$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_ZIMHTTPSERVER_VERSION_LATEST_TESTED
$(PKG)_REBUILD_SUBOPTS += FREETZ_PACKAGE_ZIMHTTPSERVER_VERSION_LATEST_GIT

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
