CWD = $(CURDIR)
MODULE = $(notdir $(CURDIR))

.PHONY: cross all clean

cross: dirs
	echo $(MODULE) @ $(CWD)
	
TMP ?= $(CWD)/tmp
GZ  ?= $(CWD)/gz
SRC ?= $(CWD)/src

.PHONY: dirs
dirs:
	echo mkdir -p $(TMP) $(GZ) $(SRC)