		include ../../Makefile.defs

_dummy := $(shell mkdir -p $(BUILD) $(BUILD)/includes)


LD=ld65
LDOPT=-v -vm
CC=cc65
CCOPT=-g -T -O -Or -r -I $(TOP)/includes -I $(BUILD)/includes -I /usr/share/cc65/include
AS=ca65 -I $(TOP)/includes
ASOPT=
LOADER_OBJS=$(BUILD)/loader.o $(BUILD)/dma.o $(BUILD)/myos.o
DEMO_OBJS=$(BUILD)/dma.o $(BUILD)/myos.o $(BUILD)/main.o $(BUILD)/aeris-test.o $(BUILD)/rainbow.o $(BUILD)/effects.o
ASM_DEPS=globals.inc $(wildcard $(TOP)/includes/*.inc)
SSD=$(SSDS)/copper.ssd

CLIBDIR=$(TOP)/clib
CLIB=$(CLIBDIR)/clib.lib

.PHONY:clean all 

all:	$(BUILD)/loader.bin $(BUILD)/demo.bin

$(SSD): all
	dfs form -80 $(SSD)
	dfs add -l 0xE00 -e 0xE00 -f "$.LOADER" $(SSD) $(BUILD)/loader.bin
	dfs add -l 0xE00 -e 0xE00 -f "$.DEMO" $(SSD) $(BUILD)/demo.bin
	dfs add -f "B.RAIN" $(SSD) assets/RAIN.B
	dfs add -f "$.!BOOT" $(SSD) _21BOOT.txt
	dfs add -l FFFF8000 -e FFFF8000 -f 'R.CLIB' $(SSD) $(CLIBDIR)/clib.rom
	dfs opt4 -3 $(SSD)


deploy:	$(SSD)
		mkdir -p $(DEPLOY_TOP)/copper
		dfs read -i -d $(DEPLOY_TOP)/copper $(SSD)


$(BUILD)/includes/gen_vars.h:
	touch $(BUILD)/includes/gen_vars.h

$(BUILD)/loader.bin: $(LOADER_OBJS) loader.cfg
	$(LD) $(LDOPT) -C loader.cfg -o $@ $(LOADER_OBJS) $(CLIB) -m $@.map
	$(SCRIPTS)/ld65map2noi.pl <$(BUILD)/loader.bin.map >$(BUILD)/loader.noi

$(BUILD)/demo.bin: $(DEMO_OBJS) demo.cfg
	$(LD) $(LDOPT) -C demo.cfg -o $@ $(DEMO_OBJS) $(CLIB) -m $@.map
	$(SCRIPTS)/ld65map2noi.pl <$(BUILD)/demo.bin.map >$(BUILD)/demo.noi


$(BUILD)/rainbow.s: rainbow.pl
	./rainbow.pl > $(BUILD)/rainbow.s

$(patsubst %.c, $(BUILD)/%.s, $(wildcard *.c)): $(BUILD)/includes/gen_vars.h globals.h myos.h 

$(patsubst %.s, $(BUILD)/%.o, $(wildcard *.s)): globals.inc

$(BUILD)/%.s:	%.c
		$(CC) $(CCOPT) -o $@ $<

$(BUILD)/%.o:	$(BUILD)/%.s 
		$(AS) $(ASOPT) -l $(basename $@).lst -o $@ $<

$(BUILD)/%.o:	%.s $(ASM_DEPS)
		$(AS) $(ASOPT) -l $(basename $@).lst -o $@ $<



clean::
	
	-rm -R -f $(BUILD)/*
	-rm $(SSD)
