# Generic Makefile for installing esim (with HYFE claim menu) on a stock
# Linux box (or any OpenWrt target after the package has been built and
# unpacked).
#
# Usage:
#   make install                 # install under /usr/local
#   make install PREFIX=/usr     # install under /usr
#   make install DESTDIR=/tmp/x  # stage into /tmp/x (for packagers)
#   make uninstall
#
# OpenWrt users: prefer `openwrt/Makefile` instead and build via `opkg`.

PREFIX  ?= /usr/local
DESTDIR ?=

BIN_DIR  := $(DESTDIR)$(PREFIX)/bin
LIB_DIR  := $(DESTDIR)$(PREFIX)/lib/hyfetrial
ETC_DIR  := $(DESTDIR)/etc/hyfetrial

INSTALL  ?= install

.PHONY: all install uninstall lint test help

all: help

help:
	@echo 'Targets:'
	@echo '  install    - install esim to $$(PREFIX)=$(PREFIX)'
	@echo '  uninstall  - remove installed files'
	@echo '  lint       - run shellcheck on all scripts'
	@echo '  test       - smoke test (--help, --version)'

install:
	$(INSTALL) -d $(BIN_DIR) $(LIB_DIR) $(ETC_DIR)
	$(INSTALL) -m 0755 src/esim           $(BIN_DIR)/esim
	$(INSTALL) -m 0644 src/lib/common.sh  $(LIB_DIR)/common.sh
	$(INSTALL) -m 0644 src/lib/api.sh     $(LIB_DIR)/api.sh
	$(INSTALL) -m 0644 src/lib/captcha.sh $(LIB_DIR)/captcha.sh
	$(INSTALL) -m 0644 src/lib/otp.sh     $(LIB_DIR)/otp.sh
	$(INSTALL) -m 0644 src/lib/config.sh  $(LIB_DIR)/config.sh
	$(INSTALL) -m 0644 src/lib/hyfe.sh    $(LIB_DIR)/hyfe.sh
	$(INSTALL) -m 0644 etc/config.example $(ETC_DIR)/config.example

uninstall:
	rm -f $(BIN_DIR)/esim
	rm -f $(LIB_DIR)/common.sh $(LIB_DIR)/api.sh \
	      $(LIB_DIR)/captcha.sh $(LIB_DIR)/otp.sh \
	      $(LIB_DIR)/config.sh  $(LIB_DIR)/hyfe.sh
	-rmdir $(LIB_DIR) 2>/dev/null || true
	rm -f $(ETC_DIR)/config.example
	-rmdir $(ETC_DIR) 2>/dev/null || true

lint:
	shellcheck -s sh src/esim src/lib/*.sh

test:
	./src/esim --help    >/dev/null
	./src/esim --version
