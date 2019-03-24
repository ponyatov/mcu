
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

cross: dirs gz
	
TMP   ?= $(CWD)/tmp
SRC   ?= $(TMP)/src
GZ    ?= $(HOME)/gz
CROSS ?= $(CWD)/cross

dirs:
	mkdir -p $(TMP) $(SRC) $(GZ) $(CROSS)

BINUTILS		= binutils-$(BINUTILS_VER)
GCC				= gcc-$(GCC_VER)
GMP				= gmp-$(GMP_VER)
MPFR			= mpfr-$(MPFR_VER)
MPC				= mpc-$(MPC_VER)
ISL				= isl-$(ISL_VER)
CLOOG			= cloog-$(CLOOG_VER)

BINUTILS_GZ		= $(BINUTILS).tar.xz
GCC_GZ			= $(GCC).tar.xz
GMP_GZ			= $(GMP).tar.xz
MPFR_GZ			= $(MPFR).tar.xz
MPC_GZ			= $(MPC).tar.gz
ISL_GZ			= $(ISL).tar.bz2
CLOOG_GZ		= $(CLOOG).tar.gz

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

cclibs: gmp mpfr mpc isl cloog

CFG = configure --prefix=$(CROSS)

CORENUM = $(shell grep processor /proc/cpuinfo|wc -l)

CFG_CCLIBS = --disable-shared

CFG_GMP    = $(CFG_CCLIBS)

gmp: $(CROSS)/lib/libgmp.a
$(CROSS)/lib/libgmp.a: $(SRC)/$(GMP)/README
	rm -rf $(TMP)/$(GMP) ; mkdir $(TMP)/$(GMP) ; cd $(TMP)/$(GMP) ; \
	$(SRC)/$(GMP)/$(CFG) $(CFG_GMP) && make -j$(CORENUM) && make install

$(SRC)/%/README: $(GZ)/%.tar.bz2
	cd $(SRC) ; bzcat $< | tar x
