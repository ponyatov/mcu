
TARGET  = arm-none-eabi

# STM32F0/L0 series
CFG_CPU = --with-cpu=cortex-m0 --with-float=soft \
			--with-mode=thumb --disable-interwork

# MSP430
# TARGET = msp430-elf
# CFG_CPU = --with-cpu=msp430g2554

BINUTILS_VER	= 2.32
GCC_VER			= 8.3.0
GMP_VER			= 6.1.2
MPFR_VER		= 4.0.2
MPC_VER			= 1.1.0
ISL_VER			= 0.18
# 0.12.2
# 0.18 undetected by newlib
CLOOG_VER		= 0.18.1

NEWLIB_VER		= nano-2.1

CWD    = $(CURDIR)
MODULE = $(notdir $(CURDIR))

.PHONY: cross all clean dirs gz cclibs binutils gcc0 newlib gcc

cross: dirs gz cclibs binutils gcc0 newlib gcc

TMP		?= $(CWD)/tmp
SRC		?= $(TMP)/src
GZ		?= $(HOME)/gz
CROSS	?= $(CWD)/$(TARGET)
SYSROOT	?= $(CROSS)/sysroot

dirs:
	mkdir -p $(TMP) $(SRC) $(GZ) $(CROSS) $(SYSROOT)

.PHONY: clean
clean:
	rm -rf $(CROSS)
	
BINUTILS	= binutils-$(BINUTILS_VER)
GCC			= gcc-$(GCC_VER)
GMP			= gmp-$(GMP_VER)
MPFR		= mpfr-$(MPFR_VER)
MPC			= mpc-$(MPC_VER)
ISL			= isl-$(ISL_VER)
CLOOG		= cloog-$(CLOOG_VER)

NEWLIB		= newlib-$(NEWLIB_VER)

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

XPATH = PATH=$(CROSS)/bin:$(PATH)

CFG = configure --disable-nls --prefix=$(CROSS)

CORENUM = $(shell grep processor /proc/cpuinfo|wc -l)

MAKE	= $(XPATH) make
MAKEJ	= $(MAKE) -j$(CORENUM)

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
	
CFG_WITHCCLIBS = --with-gmp=$(CROSS) --with-mpfr=$(CROSS) --with-mpc=$(CROSS) \
					--with-isl=$(CROSS) --with-cloog=$(CROSS)

CFG_BINUTILS = --target=$(TARGET) $(CFG_CPU) \
	--with-sysroot=$(SYSROOT) --with-native-system-header-dir=/include \
	--enable-lto --disable-multilib \
	$(CFG_WITHCCLIBS) --disable-isl-version-check

binutils: $(CROSS)/bin/$(TARGET)-ld
$(CROSS)/bin/$(TARGET)-ld: $(SRC)/$(BINUTILS)/README
	rm -rf $(TMP)/$(BINUTILS) ; mkdir $(TMP)/$(BINUTILS) ; cd $(TMP)/$(BINUTILS) ; \
	$(SRC)/$(BINUTILS)/$(CFG) $(CFG_BINUTILS) && make -j$(CORENUM) && make install

CFG_GCC = $(CFG_BINUTILS) --with-newlib --enable-languages="c"

gcc0: $(SRC)/$(GCC)/README
	rm -rf $(TMP)/$(GCC) ; mkdir $(TMP)/$(GCC) ; cd $(TMP)/$(GCC) ; \
	$(SRC)/$(GCC)/$(CFG) $(CFG_GCC)
	cd $(TMP)/$(GCC) ; $(MAKE) -j2 all-host   ; $(MAKE) install-host

gcc: $(SYSROOT)/lib/libc.a
	cd $(TMP)/$(GCC) ; $(MAKE) -j2 all-target ; $(MAKE) install-target
	
CFG_NEWLIB = $(CFG_BINUTILS) --prefix=$(SYSROOT) \
				--disable-newlib-supplied-syscalls \
				--infodir=$(CROSS)/share/info

#--enable-newlib-reent-small --disable-newlib-fvwrite-in-streamio 
#--disable-newlib-fseek-optimization --disable-newlib-wide-orient 
#--enable-newlib-nano-malloc --disable-newlib-unbuf-stream-opt 
#--enable-lite-exit --enable-newlib-global-atexit 
#--enable-newlib-nano-formatted-io
	
newlib: $(SYSROOT)/lib/libc.a
$(SYSROOT)/lib/libc.a: $(SRC)/$(NEWLIB)/README
	rm -rf $(TMP)/$(NEWLIB) ; mkdir $(TMP)/$(NEWLIB) ; cd $(TMP)/$(NEWLIB) ; \
	$(XPATH) $(SRC)/$(NEWLIB)/$(CFG) $(CFG_NEWLIB) && \
	$(MAKEJ) && $(MAKE) install
	mv $(SYSROOT)/$(TARGET)/* $(SYSROOT)/ ; rmdir $(SYSROOT)/$(TARGET)
	
$(SRC)/$(NEWLIB)/README:
	cd $(SRC) ; git clone --depth=1 https://github.com/iperry/$(NEWLIB).git
#	cd $(SRC) ; git clone https://keithp.com/cgit/newlib.git

.PHONY: target arm-none-eabi msp430-elf
target: $(TARGET)

STLINK_VER  = 1.5.1
STLINK		= stlink-$(STLINK_VER)
STLINK_GZ   = $(STLINK_VER).tar.gz

arm-none-eabi: $(CROSS)/bin/st-util

CFG_STLINK	= -DCMAKE_INSTALL_PREFIX="$(CROSS)"

$(CROSS)/bin/st-util: $(SRC)/$(STLINK)/README
	rm -rf $(TMP)/$(STLINK) ; mkdir $(TMP)/$(STLINK) ; cd $(TMP)/$(STLINK) ; \
	cmake $(CFG_STLINK) $(SRC)/$(STLINK) && $(MAKEJ) && sudo $(MAKE) install
	
$(GZ)/stlink-$(STLINK_GZ):
	$(WGET) -O $@ https://github.com/texane/stlink/archive/v$(STLINK_GZ)

MSP430_FILES_VER = 1.206
MSP430_FILES_GZ  = msp430-gcc-support-files-$(MSP430_FILES_VER).zip

msp430-elf: $(GZ)/$(MSP430_FILES_GZ)
	cd $(TMP) ; unzip -x $< && \
	mv msp430-gcc-support-files/include $(SYSROOT)/
	mkdir -p $(CROSS)/doc ; $(WGET) -P $(CROSS)/doc http://www.ti.com/lit/ug/slau646c/slau646c.pdf
$(GZ)/$(MSP430_FILES_GZ):
	$(WGET) http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/latest/exports/$(MSP430_FILES_GZ)


MCU_CC = $(XPATH) $(TARGET)-gcc --specs=nosys.specs
MCU_OD = $(XPATH) $(TARGET)-objdump
MCU_CFLAGS = -mthumb -mcpu=cortex-m3
.PHONY: test
test: none.elf
	rm $<
%.elf: test/%.c
	$(MCU_CC) $(MCU_CFLAGS) -o $@ $< && $(MCU_OD) -x $@

.PHONY: push pull
push:
	git push -v
	cd .. ; git push -v
pull:
	git pull -v
	cd .. ; git pull -v
	
