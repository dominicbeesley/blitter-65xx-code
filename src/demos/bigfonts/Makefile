		include ../../Makefile.defs

LD=ld65
LDOPT=-v -vm -L /usr/share/cc65/lib
CC=cc65
CCOPT=-g -T -O -Or -r -I $(TOP)/includes -I $(BUILD)/includes -I /usr/share/cc65/include
AS=ca65 -I $(TOP)/includes
ASOPT=
LOADER_OBJS=$(BUILD)/loader.o $(BUILD)/dma.o $(BUILD)/myos.o
DEMO_OBJS=$(BUILD)/dma.o $(BUILD)/myos.o $(BUILD)/fontmap.o $(BUILD)/main.o $(BUILD)/aeris-test.o
ASM_DEPS=globals.inc $(wildcard $(TOP)/includes/*.inc)
TILECUT=$(SCRIPTS)/tilecutter.py
SSD=$(SSDS)/bigfonts.ssd

CLIBDIR=$(TOP)/clib
CLIB=$(CLIBDIR)/clib.lib

.PHONY:clean all 

all:	$(BUILD)/font.til $(BUILD)/main.pal $(BUILD)/loader.bin $(BUILD)/demo.bin

ssd:	$(SSD)

deploy:	ssd
		mkdir -p $(DEPLOY_TOP)/bigfonts
		dfs read -i -d $(DEPLOY_TOP)/bigfonts $(SSD)

$(SSD): all
	dfs form -80 $(SSD)
	dfs add -f "T.FONT" $(SSD) $(BUILD)/font.til
	dfs add -f "T.OWL" $(SSD) $(BUILD)/owl.til
	dfs add -f "P.MAIN" $(SSD) $(BUILD)/main.pal
	dfs add -l 0x1900 -e 0x1900 -f "LOADER" $(SSD) $(BUILD)/loader.bin
	dfs add -l 0x1100 -e 0x1100 -f "DEMO" $(SSD) $(BUILD)/demo.bin
	dfs add -f "!BOOT" $(SSD) _21BOOT.txt 
	dfs add -l FFFF8000 -e FFFF8000 -f 'R.CLIB' $(SSD) $(CLIBDIR)/clib.rom
	dfs title $(SSD) "bigfonts"
	dfs opt4 -3 $(SSD)


$(BUILD)/includes/gen_vars.h:
	mkdir -p $(BUILD)/includes
	touch $(BUILD)/includes/gen_vars.h

$(BUILD)/loader.bin: $(LOADER_OBJS) loader.cfg
	$(LD) $(LDOPT) -C loader.cfg -o $@ $(LOADER_OBJS) $(CLIB) -m $@.map
	$(SCRIPTS)/ld65map2noi.pl <$(BUILD)/loader.bin.map >$(BUILD)/loader.noi

$(BUILD)/demo.bin: $(DEMO_OBJS) demo.cfg
	$(LD) $(LDOPT) -C demo.cfg -o $@ $(DEMO_OBJS) $(CLIB) -m $@.map
	$(SCRIPTS)/ld65map2noi.pl <$(BUILD)/demo.bin.map >$(BUILD)/demo.noi


$(patsubst %.c, $(BUILD)/%.s, $(wildcard *.c)): $(BUILD)/includes/gen_vars.h globals.h myos.h 

$(patsubst %.s, $(BUILD)/%.o, $(wildcard *.s)): globals.inc

$(BUILD)/%.s:	%.c
		$(CC) $(CCOPT) -o $@ $<

$(BUILD)/%.o:	$(BUILD)/%.s 
		$(AS) $(ASOPT) -l $(basename $@).lst -o $@ $<

$(BUILD)/%.o:	%.s $(ASM_DEPS)
		$(AS) $(ASOPT) -l $(basename $@).lst -o $@ $<


$(BUILD)/fontmap.s: fontmap/ascii2font.txt fontmap/big_fontmap.tmx scripts/fontmap2asm.pl
		scripts/fontmap2asm.pl fontmap/big_fontmap.tmx fontmap/ascii2font.txt $(BUILD)/fontmap.s


$(BUILD)/main.pal $(BUILD)/font.til: src-gra/big_font_parts_mo2_g2.png fontmap/tile-cutter.xml
	$(TILECUT) fontmap/tile-cutter.xml "$(shell pwd)" "$(BUILD)"


clean::
	-rm -f $(BUILD)/main.pal $(BUILD)/font.til
	-rm -R -f $(BUILD)/*
	-rm $(SSD)
