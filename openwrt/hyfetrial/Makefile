#
# OpenWrt package Makefile for esim (LPAC-based eSIM manager + HYFE trial
# claim menu). Package name kept as 'hyfetrial' for backward-compat with
# existing CI / feeds; install path moves from /usr/bin/hyfetrial to
# /usr/bin/esim.
#
# This package has no compiled code, just shell scripts. The actual source
# files live in `<repo-root>/src` and `<repo-root>/etc`. We resolve the path
# at build time via $(HYFETRIAL_SRC):
#   * gh-action-sdk mounts the workspace at /feed -> use /feed
#   * Manual local feed (`src-link action /path/to/0xygen-esim/openwrt`):
#     pass HYFETRIAL_SRC explicitly, or rely on /feed override.
#
# Build with the official OpenWrt SDK:
#   cd openwrt-sdk-*/
#   echo "src-link hyfetrial $(pwd)/../openwrt" >> feeds.conf
#   ./scripts/feeds update hyfetrial && ./scripts/feeds install hyfetrial
#   make defconfig
#   make package/hyfetrial/compile V=s HYFETRIAL_SRC=$(realpath ../..)
#
include $(TOPDIR)/rules.mk

PKG_NAME:=hyfetrial
PKG_VERSION:=0.2.0
PKG_RELEASE:=1
PKG_MAINTAINER:=0xwuwa999 <0xwuwa999@gmail.com>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

# Source location resolution:
#   1. Explicit HYFETRIAL_SRC via env / make var (highest priority)
#   2. gh-action-sdk's /feed mount
#   3. Walk up from $(CURDIR): assume <repo>/openwrt/hyfetrial/Makefile
HYFETRIAL_SRC ?= $(if $(wildcard /feed/src/esim),/feed,$(realpath $(CURDIR)/../..))

include $(INCLUDE_DIR)/package.mk

define Package/hyfetrial
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=esim - LPAC eSIM manager + HYFE trial claim menu (XL Prioritas)
  URL:=https://github.com/nyawitniorang/0xygen-esim
  DEPENDS:=+curl +jq +ca-bundle
  PKGARCH:=all
endef

define Package/hyfetrial/description
  CLI ringan satu-paket untuk:
    * Manage eSIM lokal di L850GL via lpac (info EID, profile list, switch,
      delete, download, process notification, recovery SIM missing).
    * Klaim eSIM Trial gratis HYFE/XL Prioritas (multi-akun email, multi-EID
      slot, OTP via IMAP atau manual paste, reCAPTCHA via paste atau solver
      berbayar 2captcha / anti-captcha / capsolver / nextcaptcha).
    * Mode "Klaim Cepat" dengan setup preferences (email/EID/captcha/OTP/
      pattern/auto-pick) buat klaim semi-otomatis dari menu.
  Murni shell + curl + jq, tanpa kompilasi.
endef

# No source download / no native build steps: this is a pure shell package.
define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/hyfetrial/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(HYFETRIAL_SRC)/src/esim $(1)/usr/bin/esim

	$(INSTALL_DIR) $(1)/usr/lib/hyfetrial
	$(INSTALL_DATA) $(HYFETRIAL_SRC)/src/lib/common.sh  $(1)/usr/lib/hyfetrial/common.sh
	$(INSTALL_DATA) $(HYFETRIAL_SRC)/src/lib/api.sh     $(1)/usr/lib/hyfetrial/api.sh
	$(INSTALL_DATA) $(HYFETRIAL_SRC)/src/lib/captcha.sh $(1)/usr/lib/hyfetrial/captcha.sh
	$(INSTALL_DATA) $(HYFETRIAL_SRC)/src/lib/otp.sh     $(1)/usr/lib/hyfetrial/otp.sh
	$(INSTALL_DATA) $(HYFETRIAL_SRC)/src/lib/config.sh  $(1)/usr/lib/hyfetrial/config.sh
	$(INSTALL_DATA) $(HYFETRIAL_SRC)/src/lib/hyfe.sh    $(1)/usr/lib/hyfetrial/hyfe.sh

	$(INSTALL_DIR) $(1)/etc/hyfetrial
	$(INSTALL_CONF) $(HYFETRIAL_SRC)/etc/config.example $(1)/etc/hyfetrial/config.example
endef

define Package/hyfetrial/conffiles
/etc/hyfetrial/config.example
endef

$(eval $(call BuildPackage,hyfetrial))
