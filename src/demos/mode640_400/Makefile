		include ../../Makefile.defs

_dummy := $(shell mkdir -p $(BUILD)/includes)



LD=ld65
LDOPT=-v -vm
CC=cc65
CCOPT=-g -T -O -Or -r -I $(TOP)/includes -I /usr/share/cc65/include -I $(BUILD)/includes
AS=ca65 -I $(TOP)/includes
ASOPT=
DEMO_OBJS=$(BUILD)/main.o $(BUILD)/myos.o
ASM_DEPS=$(wildcard $(TOP)/includes/*.inc)
DEPS=$(wildcard *.h) $(BUILD)/pics.h

CLIBDIR=$(TOP)/clib
CLIB=$(CLIBDIR)/clib.lib


SSD=$(SSDS)/640x400.ssd



.PHONY:clean all 

all: $(BUILD)/demo.bin

ssd: $(SSD)




$(SSD): all
	dfs form -80 $(SSD)
	dfs add -l 0xE00 -e 0xE00 -f "DEMO" $(SSD) $(BUILD)/demo.bin
	dfs add $(SSD) $(BUILD)/*.bbc.inf
	dfs add -l FFFF8000 -e FFFF8000 -f 'R.CLIB' $(SSD) $(CLIBDIR)/clib.rom


deploy:	$(SSD)
		mkdir -p $(DEPLOY_TOP)/640x400
		dfs read -i -d $(DEPLOY_TOP)/640x400 $(SSD)

$(BUILD)/demo.bin: $(DEMO_OBJS) demo.cfg
	$(LD) $(LDOPT) -C demo.cfg -o $@ $(DEMO_OBJS) $(CLIB) -m $@.map
	$(SCRIPTS)/ld65map2noi.pl <$(BUILD)/demo.bin.map >$(BUILD)/demo.noi


$(BUILD)/%.s:	%.c $(DEPS)
		$(CC) $(CCOPT) -o $@ $<

$(BUILD)/%.o:	$(BUILD)/%.s 
		$(AS) $(ASOPT) -l $(basename $@).lst -o $@ $<

$(BUILD)/%.o:	%.s $(ASM_DEPS)
		$(AS) $(ASOPT) -l $(basename $@).lst -o $@ $<

$(BUILD)/%.bbc:	src_pngs/%.png
		perl png2bbc.pl $< $@

$(BUILD)/pics.h:	$(addprefix $(BUILD)/, $(notdir $(patsubst %.png,%.bbc, $(wildcard src_pngs/*.png))))
		./dopics.sh $(BUILD)

clean:
	-rm $(patsubst %.o, %.lst, $(DEMO_OBJS))
	-rm $(DEMO_OBJS)
	-rm $(SSD)
	-rm $(BUILD)/includes/pics.h
	-rm $(BUILD)/demo.bin
	-rm $(BUILD)/demo.bin.map
	-rm $(BUILD)/demo.noi
	-rm $(BUILD)/*.bbc.inf
	-rm $(BUILD)/*.bbc
