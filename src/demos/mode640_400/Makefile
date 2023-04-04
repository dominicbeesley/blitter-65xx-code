		include ../../Makefile.defs


LD=ld65
LDOPT=-v -vm
CC=cc65
CCOPT=-g -T -O -Or -r -I $(TOP)/includes -I /usr/share/cc65/include -I $(BUILD)
AS=ca65 -I $(TOP)/includes
ASOPT=

CLIBDIR=$(TOP)/clib
CLIB=$(CLIBDIR)/clib.lib


SSD=$(SSDS)/640x400.ssd



.PHONY:clean all 

all: $(BUILD)/demo.bin

ssd: $(SSD)

TARGETS=demo.bin
PICS=$(wildcard src_pngs/*.png)

DEMO_OBJS=$(BUILD)/main.o $(BUILD)/myos.o
ASM_DEPS=$(wildcard $(TOP)/includes/*.inc)
DEPS=$(wildcard *.h) $(BUILD)/pics.h

TARGETS_O=$(addprefix $(BUILD)/, $(TARGETS))
PICS_BBC=$(addprefix $(BUILD)/, $(notdir $(patsubst %.png,%.bbc, $(PICS))))


$(SSD): $(PICS_BBC) $(TARGETS_O) $(CLIBDIR)/clib.rom
	dfs form -80 $(SSD)
	dfs add -l 0xE00 -e 0xE00 -f "DEMO" $(SSD) $(BUILD)/demo.bin
	dfs add $(SSD) $(addsuffix .inf, $(PICS_BBC))
	dfs add -l FFFF8000 -e FFFF8000 -f 'R.CLIB' $(SSD) $(CLIBDIR)/clib.rom


deploy:	$(SSD)
		mkdir -p $(DEPLOY_TOP)/640x400
		dfs read -i -d $(DEPLOY_TOP)/640x400 $(SSD)

$(BUILD)/%.bin: $(DEMO_OBJS) %.cfg
	$(LD) $(LDOPT) -C $(filter %.cfg, $^) -o $@ $(DEMO_OBJS) $(CLIB) -m $@.map
	$(SCRIPTS)/ld65map2noi.pl <$(BUILD)/demo.bin.map >$(BUILD)/demo.noi


$(BUILD)/%.s:	%.c $(DEPS)
		$(CC) $(CCOPT) -o $@ $<

$(BUILD)/%.o:	$(BUILD)/%.s 
		$(AS) $(ASOPT) -l $(basename $@).lst -o $@ $<

$(BUILD)/%.o:	%.s $(ASM_DEPS)
		$(AS) $(ASOPT) -l $(basename $@).lst -o $@ $<

$(BUILD)/%.bbc:	src_pngs/%.png
		perl png2bbc.pl $< $@

$(BUILD)/pics.h:	$(PICS_BBC)
		./dopics.sh $(BUILD)

clean:
	-rm $(patsubst %.o, %.lst, $(DEMO_OBJS))
	-rm $(DEMO_OBJS)
	-rm $(SSD)
	-rm $(BUILD)/pics.h
	-rm $(TARGETS_O)
	-rm $(addsuffix .map, $(TARGETS_O))
	-rm $(patsubst %.bin, %.noi, $(TARGETS_O))
	-rm $(PICS_BBC)
	-rm $(addsuffix .inf, $(PICS_BBC))
