#
# OpenWrt package Makefile for hyfetrial.
#
# Usage:
#   1. Drop this file (and the parent directory renamed to `hyfetrial/`)
#      into your OpenWrt feed, e.g. `feeds/custom/hyfetrial/Makefile`.
#      The Makefile expects the project source at the same level it would
#      be after `git clone https://github.com/nyawitniorang/0xygen-esim.git`,
#      i.e. with `src/hyfetrial`, `src/lib/*.sh`, and `etc/config.example`
#      relative to this Makefile (use a symlink or git submodule).
#   2. `./scripts/feeds update -a && ./scripts/feeds install hyfetrial`
#   3. `make package/hyfetrial/compile`
#
# Or build straight from this repo:
#   make -C openwrt PKG_BUILD_DIR=$(pwd) ...
#
include $(TOPDIR)/rules.mk

PKG_NAME:=hyfetrial
PKG_VERSION:=0.1.0
PKG_RELEASE:=1
PKG_MAINTAINER:=0xwuwa999 <0xwuwa999@gmail.com>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

# Source layout: this Makefile is in openwrt/, the actual scripts live in
# ../src and ../etc relative to it. We use a relative path so the package
# can be built from the repo root without any extra checkout.
PKG_SRC_DIR := $(realpath $(CURDIR)/..)

include $(INCLUDE_DIR)/package.mk

define Package/hyfetrial
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=hyfetrial - klaim eSIM Trial HYFE (XL Prioritas) dari CLI
  URL:=https://github.com/nyawitniorang/0xygen-esim
  DEPENDS:=+curl +jq +ca-bundle
  PKGARCH:=all
endef

define Package/hyfetrial/description
  CLI ringan untuk request eSIM Trial gratis HYFE dari prioritas.xl.co.id.
  Mengotomatiskan: pilih nomor cantik, isi data, input EID, kirim & verifikasi
  OTP email. Dukungan reCAPTCHA via paste manual atau solver berbayar
  (2captcha / anti-captcha / capsolver). Dukungan IMAP untuk auto-baca OTP.
  Murni shell + curl + jq, tanpa kompilasi.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/hyfetrial/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_SRC_DIR)/src/hyfetrial $(1)/usr/bin/hyfetrial

	$(INSTALL_DIR) $(1)/usr/lib/hyfetrial
	$(INSTALL_DATA) $(PKG_SRC_DIR)/src/lib/common.sh  $(1)/usr/lib/hyfetrial/common.sh
	$(INSTALL_DATA) $(PKG_SRC_DIR)/src/lib/api.sh     $(1)/usr/lib/hyfetrial/api.sh
	$(INSTALL_DATA) $(PKG_SRC_DIR)/src/lib/captcha.sh $(1)/usr/lib/hyfetrial/captcha.sh
	$(INSTALL_DATA) $(PKG_SRC_DIR)/src/lib/otp.sh     $(1)/usr/lib/hyfetrial/otp.sh

	$(INSTALL_DIR) $(1)/etc/hyfetrial
	$(INSTALL_CONF) $(PKG_SRC_DIR)/etc/config.example $(1)/etc/hyfetrial/config.example
endef

define Package/hyfetrial/conffiles
/etc/hyfetrial/config.example
endef

$(eval $(call BuildPackage,hyfetrial))
