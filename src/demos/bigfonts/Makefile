		include ../../Makefile.defs

LD=ld65
LDOPT=-v -vm
CC=cc65
CCOPT=-g -T -O -Or -r -I $(TOP)/includes -I $(BUILD)/includes
AS=ca65 -I $(TOP)/includes
ASOPT=
LOADER_OBJS=loader dma myos
DEMO_OBJS=dma myos fontmap main aeris-test
LOADER_OBJS_O=$(addprefix $(BUILD)/, $(addsuffix .o, $(LOADER_OBJS)))
DEMO_OBJS_O=$(addprefix $(BUILD)/, $(addsuffix .o, $(DEMO_OBJS)))
ASM_DEPS=globals.inc $(wildcard $(TOP)/includes/*.inc)
TILECUT=$(SCRIPTS)/tilecutter.py
SSD=$(SSDS)/bigfonts.ssd

TARGETS=$(BUILD)/font.til $(BUILD)/owl.til $(BUILD)/main.pal $(BUILD)/loader.bin $(BUILD)/demo.bin

CLIBDIR=$(TOP)/clib
CLIB=$(CLIBDIR)/clib.lib

.PHONY:clean all 

all:	$(TARGETS)

ssd:	$(SSD)

deploy:	ssd
		mkdir -p $(DEPLOY_TOP)/bigfonts
		dfs read -i -d $(DEPLOY_TOP)/bigfonts $(SSD)

$(SSD): $(TARGETS) _21BOOT.xxx $(CLIBDIR)/clib.rom
	dfs form -80 $(SSD)
	dfs add -f "T.FONT" $(SSD) $(BUILD)/font.til
	dfs add -f "T.OWL" $(SSD) $(BUILD)/owl.til
	dfs add -f "P.MAIN" $(SSD) $(BUILD)/main.pal
	dfs add -l 0x1900 -e 0x1900 -f "LOADER" $(SSD) $(BUILD)/loader.bin
	dfs add -l 0x1100 -e 0x1100 -f "DEMO" $(SSD) $(BUILD)/demo.bin
	dfs add -f "!BOOT" $(SSD) _21BOOT.xxx
	dfs add -l FFFF8000 -e FFFF8000 -f 'R.CLIB' $(SSD) $(CLIBDIR)/clib.rom
	dfs title $(SSD) "bigfonts"
	dfs opt4 -3 $(SSD)


$(BUILD)/includes/gen_vars.h:
	mkdir -p $(BUILD)/includes
	touch $(BUILD)/includes/gen_vars.h

$(BUILD)/loader.bin: $(LOADER_OBJS_O) loader.cfg
	$(LD) $(LDOPT) -C loader.cfg -o $@ $(LOADER_OBJS_O) $(CLIB) --dbgfile $(basename $@).dbg -m $@.map
	$(SCRIPTS)/ld65map2noi.pl <$(BUILD)/loader.bin.map >$(BUILD)/loader.noi
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)

$(BUILD)/demo.bin: $(DEMO_OBJS_O) demo.cfg
	$(LD) $(LDOPT) -C demo.cfg -o $@ $(DEMO_OBJS_O) $(CLIB) --dbgfile $(basename $@).dbg -m $@.map
	$(SCRIPTS)/ld65map2noi.pl <$(BUILD)/demo.bin.map >$(BUILD)/demo.noi
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)


$(patsubst %.c, $(BUILD)/%.s, $(wildcard *.c)): $(BUILD)/includes/gen_vars.h globals.h myos.h 

$(patsubst %.s, $(BUILD)/%.o, $(wildcard *.s)): globals.inc

$(BUILD)/%.s:	%.c
		$(CC) $(CCOPT) -g -o $@ $<

$(BUILD)/%.o:	$(BUILD)/%.s 
		$(AS) $(ASOPT) -g -l $(basename $@).lst -o $@ $<

$(BUILD)/%.o:	%.s $(ASM_DEPS)
		$(AS) $(ASOPT) -g -l $(basename $@).lst -o $@ $<


$(BUILD)/fontmap.s: fontmap/ascii2font.txt fontmap/big_fontmap.tmx scripts/fontmap2asm.pl
		scripts/fontmap2asm.pl fontmap/big_fontmap.tmx fontmap/ascii2font.txt $(BUILD)/fontmap.s


$(BUILD)/main.pal $(BUILD)/font.til: src-gra/big_font_parts_mo2_g2.png fontmap/tile-cutter.xml
	$(TILECUT) fontmap/tile-cutter.xml "$(shell pwd)" "$(BUILD)"


clean::
	-rm -f $(BUILD)/main.pal $(BUILD)/font.til $(BUILD)/owl.til $(BUILD)/font.til.cuts $(BUILD)/owl.til.cuts
	-rm -f $(TARGETS)
	-rm -f $(LOADER_OBJS_O)
	-rm -f $(DEMO_OBJS_O)
	-rm -f $(addprefix $(BUILD)/, $(addsuffix .lst, $(LOADER_OBJS)))
	-rm -f $(addprefix $(BUILD)/, $(addsuffix .lst, $(DEMO_OBJS)))
	-rm -f $(addprefix $(BUILD)/, $(addsuffix .s, $(LOADER_OBJS)))
	-rm -f $(addprefix $(BUILD)/, $(addsuffix .s, $(DEMO_OBJS)))
	-rm -f $(BUILD)/demo.bin.map $(BUILD)/demo.noi
	-rm -f $(BUILD)/loader.bin.map $(BUILD)/loader.noi
	-rm -f $(BUILD)/includes/gen_vars.h	
	-rm $(SSD)
