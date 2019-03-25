
TARGET ?= arm-none-eabi
# TARGET ?= msp430-elf

BINUTILS_VER	= 2.32
GCC_VER			= 8.3.0
GMP_VER			= 6.1.2
MPFR_VER		= 4.0.2
MPC_VER			= 1.1.0
ISL_VER			= 0.18
CLOOG_VER		= 0.18.1

CWD    = $(CURDIR)
MODULE = $(notdir $(CURDIR))

.PHONY: cross all clean dirs gz cclibs binutils gcc

cross: dirs gz cclibs binutils
	
TMP		?= $(CWD)/tmp
SRC		?= $(TMP)/src
GZ		?= $(HOME)/gz
CROSS	?= $(CWD)/$(TARGET)
SYSROOT	?= $(CROSS)/sysroot

dirs:
	mkdir -p $(TMP) $(SRC) $(GZ) $(CROSS) $(SYSROOT)

BINUTILS	= binutils-$(BINUTILS_VER)
GCC			= gcc-$(GCC_VER)
GMP			= gmp-$(GMP_VER)
MPFR		= mpfr-$(MPFR_VER)
MPC			= mpc-$(MPC_VER)
ISL			= isl-$(ISL_VER)
CLOOG		= cloog-$(CLOOG_VER)

BINUTILS_GZ	= $(BINUTILS).tar.xz
GCC_GZ		= $(GCC).tar.xz
GMP_GZ		= $(GMP).tar.xz
MPFR_GZ		= $(MPFR).tar.xz
MPC_GZ		= $(MPC).tar.gz
ISL_GZ		= $(ISL).tar.bz2
CLOOG_GZ	= $(CLOOG).tar.gz

gz: $(GZ)/$(BINUTILS_GZ) $(GZ)/$(GCC_GZ) \
	$(GZ)/$(GMP_GZ) $(GZ)/$(MPFR_GZ) $(GZ)/$(MPC_GZ) \
	$(GZ)/$(ISL_GZ) $(GZ)/$(CLOOG_GZ)

WGET = wget -P $(GZ) -c

$(GZ)/$(BINUTILS_GZ):
	$(WGET) http://ftp.gnu.org/gnu/binutils/$(BINUTILS_GZ)
$(GZ)/$(GCC_GZ):
	$(WGET) https://ftp.gnu.org/gnu/gcc/$(GCC)/$(GCC_GZ)

$(GZ)/$(GMP_GZ):
	$(WGET) ftp://ftp.gmplib.org/pub/gmp/$(GMP_GZ)
$(GZ)/$(MPFR_GZ):
	$(WGET) https://www.mpfr.org/mpfr-current/$(MPFR_GZ)
$(GZ)/$(MPC_GZ):
	$(WGET) https://ftp.gnu.org/gnu/mpc/$(MPC_GZ)

$(GZ)/$(ISL_GZ):
	$(WGET) ftp://gcc.gnu.org/pub/gcc/infrastructure/$(ISL_GZ)
$(GZ)/$(CLOOG_GZ):
	$(WGET) ftp://gcc.gnu.org/pub/gcc/infrastructure/$(CLOOG_GZ)

cclibs: gmp mpfr mpc cloog isl

CFG = configure --prefix=$(CROSS)

CORENUM = $(shell grep processor /proc/cpuinfo|wc -l)

CFG_CCLIBS	= --disable-shared

CFG_GMP		= $(CFG_CCLIBS)

gmp: $(CROSS)/lib/libgmp.a
$(CROSS)/lib/libgmp.a: $(SRC)/$(GMP)/README
	rm -rf $(TMP)/$(GMP) ; mkdir $(TMP)/$(GMP) ; cd $(TMP)/$(GMP) ; \
	$(SRC)/$(GMP)/$(CFG) $(CFG_GMP) && make -j$(CORENUM) && make install
	
CFG_MPFR	= $(CFG_CCLIBS) --with-gmp=$(CROSS)

mpfr: $(CROSS)/lib/libmpfr.a
$(CROSS)/lib/libmpfr.a: $(SRC)/$(MPFR)/README
	rm -rf $(TMP)/$(MPFR) ; mkdir $(TMP)/$(MPFR) ; cd $(TMP)/$(MPFR) ; \
	$(SRC)/$(MPFR)/$(CFG) $(CFG_MPFR) && make -j$(CORENUM) && make install

CFG_MPC		= $(CFG_CCLIBS) --with-gmp=$(CROSS)

mpc: $(CROSS)/lib/libmpc.a
$(CROSS)/lib/libmpc.a: $(SRC)/$(MPC)/README
	rm -rf $(TMP)/$(MPC) ; mkdir $(TMP)/$(MPC) ; cd $(TMP)/$(MPC) ; \
	$(SRC)/$(MPC)/$(CFG) $(CFG_MPC) && make -j$(CORENUM) && make install

CFG_CLOOG	= $(CFG_CCLIBS) --with-gmp-prefix=$(CROSS)

cloog: $(CROSS)/lib/libcloog-isl.a
$(CROSS)/lib/libcloog-isl.a: $(SRC)/$(CLOOG)/README
	rm -rf $(TMP)/$(CLOOG) ; mkdir $(TMP)/$(CLOOG) ; cd $(TMP)/$(CLOOG) ; \
	$(SRC)/$(CLOOG)/$(CFG) $(CFG_CLOOG) && make -j$(CORENUM) && make install

CFG_ISL		= $(CFG_CCLIBS) --with-gmp-prefix=$(CROSS)

isl: $(CROSS)/lib/libisl.a
$(CROSS)/lib/libisl.a: $(SRC)/$(ISL)/README
	rm -rf $(TMP)/$(ISL) ; mkdir $(TMP)/$(ISL) ; cd $(TMP)/$(ISL) ; \
	$(SRC)/$(ISL)/$(CFG) $(CFG_ISL) && make -j$(CORENUM) && make install

$(SRC)/%/README: $(GZ)/%.tar.bz2
	cd $(SRC) ; bzcat $< | tar x && touch $@
$(SRC)/%/README: $(GZ)/%.tar.xz
	cd $(SRC) ; xzcat $< | tar x && touch $@
$(SRC)/%/README: $(GZ)/%.tar.gz
	cd $(SRC) ;  zcat $< | tar x && touch $@
	
CFG_WITHCCLIBS = --with-gmp=$(CROSS) --with-mpfr=$(CROSS) --with-mpc=$(CROSS)
					--with-isl=$(CROSS) --with-cloog=$(CROSS)

CFG_BINUTILS = --disable-nls --prefix=$(CROSS) --target=$(TARGET) \
	--with-sysroot=$(SYSROOT) --with-native-system-header-dir=/include \
	--enable-lto --disable-multilib \
	$(CFG_WITHCCLIBS)

binutils: $(CROSS)/bin/$(TARGET)-ld
$(CROSS)/bin/$(TARGET)-ld: $(SRC)/$(BINUTILS)/README
	rm -rf $(TMP)/$(BINUTILS) ; mkdir $(TMP)/$(BINUTILS) ; cd $(TMP)/$(BINUTILS) ; \
	$(SRC)/$(BINUTILS)/$(CFG) $(CFG_BINUTILS) && make -j$(CORENUM) && make install

CFG_GCC = $(CFG_BINUTILS) --with-newlib --enable-languages="c"

gcc: $(CROSS)/bin/$(TARGET)-gcc
$(CROSS)/bin/$(TARGET)-gcc: $(SRC)/$(GCC)/README
	rm -rf $(TMP)/$(GCC) ; mkdir $(TMP)/$(GCC) ; cd $(TMP)/$(GCC) ; \
	$(SRC)/$(GCC)/$(CFG) $(CFG_GCC)
#	 && make -j$(CORENUM) && make install

.PHONY: target arm-none-eabi msp430-elf
target: $(TARGET)

MSP430_FILES_VER = 1.206
MSP430_FILES_GZ  = msp430-gcc-support-files-$(MSP430_FILES_VER).zip

msp430-elf: $(GZ)/$(MSP430_FILES_GZ)
	cd $(TMP) ; unzip -x $< && \
	mv msp430-gcc-support-files/include $(SYSROOT)/
$(GZ)/$(MSP430_FILES_GZ):
	$(WGET) http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/latest/exports/$(MSP430_FILES_GZ)
