# ----------------------------------------------------------------------------
# Copyright (c) 2013, KOBAYASHI Daisuke
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# ----------------------------------------------------------------------------

GCC_VERSION = 4.7.2
BINUTILS_VERSION = 2.22
NEWLIB_VERSION = 1.20.0
GMP_VERSION = 5.0.5
MPFR_VERSION = 3.1.1
MPC_VERSION = 1.0.1

PREFIX = /usr/local
XPREFIX = $(PREFIX)/$(TARGET)/$(GCC_VERSION)

PATH = $(XPREFIX)/bin:/usr/local/bin:/usr/bin:/bin

CURL = curl
TAR = tar

GCC_ = gcc-$(GCC_VERSION)
BINUTILS_ = binutils-$(BINUTILS_VERSION)
NEWLIB_ = newlib-$(NEWLIB_VERSION)
GMP_ = gmp-$(GMP_VERSION)
MPFR_ = mpfr-$(MPFR_VERSION)
MPC_ = mpc-$(MPC_VERSION)

ifneq ($(TARGET),)
all: $(GCC_).stamp
else
all:
	@echo "You must set the variable TARGET."
endif

$(GCC_).tar.bz2:
	# $(CURL) -O ftp://gcc.gnu.org/pub/gcc/releases/$(GCC_)/$@
	$(CURL) -L -O http://ftpmirror.gnu.org/gcc/$(GCC_)/$@

$(BINUTILS_).tar.bz2:
	# $(CURL) -O ftp://ftp.gnu.org/gnu/binutils/$@
	$(CURL) -L -O http://ftpmirror.gnu.org/binutils/$@

$(NEWLIB_).tar.gz:
	$(CURL) -O ftp://sourceware.org/pub/newlib/$@

$(GMP_).tar.bz2:
	# $(CURL) -O ftp://ftp.gmplib.org/pub/$(GMP_)/$@
	$(CURL) -L -O http://ftpmirror.gnu.org/gmp/$@

$(MPFR_).tar.bz2:
	$(CURL) -O http://www.mpfr.org/$(MPFR_)/$@

$(MPC_).tar.gz:
	$(CURL) -O http://www.multiprecision.org/mpc/download/$@

.SECONDARY: $(GCC_) $(BINUTILS_) $(NEWLIB_) $(GMP_) $(MPFR_) $(MPC_)

gmp-%: gmp-%.tar.bz2
	$(TAR) jxf $<
	touch $@

mpfr-%: mpfr-%.tar.bz2
	$(TAR) jxf $<
	touch $@

mpc-%: mpc-%.tar.gz
	$(TAR) zxf $<
	touch $@

binutils-%: binutils-%.tar.bz2
	$(TAR) jxf $<
	touch $@

gcc-%: gcc-%.tar.bz2
	$(TAR) jxf $<
	touch $@

newlib-%: newlib-%.tar.gz
	$(TAR) zxf $<
	touch $@

.SECONDARY: $(GCC_).stamp $(GCC_).core.stamp $(BINUTILS_).stamp \
	$(NEWLIB_).stamp $(GMP_).stamp $(MPFR_).stamp $(MPC_).stamp

gmp-%.stamp: BUILDDIR = gmp-$*.build
gmp-%.stamp: OPTS = --prefix=$(PWD) --disable-shared
gmp-%.stamp: gmp-%
	$(BUILDLIB)

mpfr-%.stamp: BUILDDIR = mpfr-$*.build
mpfr-%.stamp: OPTS = --prefix=$(PWD) --with-gmp=$(PWD) --disable-shared
mpfr-%.stamp: mpfr-% $(GMP_).stamp
	$(BUILDLIB)

mpc-%.stamp: BUILDDIR = mpc-$*.build
mpc-%.stamp: OPTS = --prefix=$(PWD) --with-gmp=$(PWD) --with-mpfr=$(PWD) --disable-shared
mpc-%.stamp: mpc-% $(GMP_).stamp $(MPFR_).stamp
	$(BUILDLIB)

define BUILDLIB
mkdir -p $(BUILDDIR)
cd $(BUILDDIR) && ../$</configure $(OPTS)
$(MAKE) -C $(BUILDDIR)
$(MAKE) -C $(BUILDDIR) install
touch $@
endef

BINUTILS_OPTS = --prefix=$(XPREFIX) --target=$(TARGET)

binutils-%.stamp: BUILDDIR = binutils-$*.build
binutils-%.stamp: binutils-%
	mkdir -p $(BUILDDIR)
	cd $(BUILDDIR) && ../$</configure $(BINUTILS_OPTS)
	$(MAKE) -C $(BUILDDIR)
	$(MAKE) -C $(BUILDDIR) install
	touch $@

GCC_OPTS = --prefix=$(XPREFIX) --target=$(TARGET) --with-newlib \
		--with-gmp=$(PWD) --with-mpfr=$(PWD) --with-mpc=$(PWD) \
		--enable-languages=c,c++

gcc-%.core.stamp: BUILDDIR = gcc-$*.build
gcc-%.core.stamp: gcc-% $(GMP_).stamp $(MPFR_).stamp $(MPC_).stamp \
		$(BINUTILS_).stamp
	mkdir -p $(BUILDDIR)
	cd $(BUILDDIR) && ../$</configure $(GCC_OPTS)
	$(MAKE) -C $(BUILDDIR) all-gcc
	$(MAKE) -C $(BUILDDIR) install-gcc
	touch $@

NEWLIB_OPTS = --prefix=$(XPREFIX) --target=$(TARGET)

newlib-%.stamp: BUILDDIR = newlib-$*.build
newlib-%.stamp: newlib-% $(GCC_).core.stamp
	mkdir -p $(BUILDDIR)
	cd $(BUILDDIR) && ../$</configure $(NEWLIB_OPTS)
	$(MAKE) -C $(BUILDDIR)
	$(MAKE) -C $(BUILDDIR) install
	touch $@

gcc-%.stamp: BUILDDIR = gcc-$*.build
gcc-%.stamp: gcc-% gcc-%.core.stamp $(NEWLIB_).stamp
	$(MAKE) -C $(BUILDDIR)
	$(MAKE) -C $(BUILDDIR) install
	touch $@

clean:
	$(RM) *.stamp
	$(RM) -r *.build
.PHONY: clean

