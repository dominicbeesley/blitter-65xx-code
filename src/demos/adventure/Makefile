		include ../../Makefile.defs

_dummy := $(shell mkdir -p $(BUILD)/tiles $(BUILD)/maps $(BUILD)/includes)


TILECUT=/cygdrive/d/work/vs2017/AuthorityFileLtd/Games/TileCutter/TileCutter/bin/Debug/TileCutter.exe

CLEAN_EXTRA= \
				tiles/charac.til \
				tiles/main.pal \
				gen_vars.h

TARGETS=game loader wander

SSD=$(SSDS)/adventure.ssd

LD=ld65
LDOPT=-v -vm
CC=cc65
CCOPT=-T -O -Or -r -I ../../../includes -I $(BUILD)/includes -I /usr/local/share/cc65/include
AS=ca65 -I ../../../includes
ASOPT=


CLIBDIR=~/cc65-rom

#CLIB=bbc.lib
CLIB=$(CLIBDIR)/clib.lib


.SECONDARY:$(BUILD)/game.s $(BUILD)/dma.s $(BUILD)/loader.s $(BUILD)/wander.s

GAME_OBJS=	game draw_map dma myos tile_map brk adval sprite screenmaths 
WANDER_OBJS=	wander draw_map dma myos tile_map brk sprite screenmaths text
LOADER_OBJS=	loader dma myos rle_asm
INCS=$(BUILD)/includes/ $(BUILD)/includes/gen_vars.h


TARGETS_O=$(addprefix $(BUILD)/, $(addsuffix .o, $(TARGETS)))
GAME_OBJS_O=$(addprefix $(BUILD)/, addsuffix(.o, $(GAME_OBJS)))
WANDER_OBJS_O=$(addprefix $(BUILD)/, addsuffix(.o, $(WANDER_OBJS)))
LOADER_OBJS_O=$(addprefix $(BUILD)/, addsuffix(.o, $(LOADER_OBJS)))

all: $(TARGETS_O)

ssd: $(SSD)

$(BUILD)/clib.rom:
	cp $(CLIBDIR)/clib.rom $(BUILD)/clib.rom

$(SSD): ssd/include.lst tiles $(BUILD)/clib.rom $(TARGETS_O)
	$(SCRIPTS)/buildssd.sh --dest adventure.ssd --hostfs ~/hostfs --name advent65 ./ssd
	$(SCRIPTS)/hostfs2vdfs.sh ~/hostfs/advent65 ~/vdfs/advent65

$(BUILD)/game.bin: $(GAME_OBJS) game.cfg
	$(LD) $(LDOPT) -o $@ $(GAME_OBJS) $(CLIB) -m $@.map
	$(SCRIPTS)/ld65map2noi.pl <$(BUILD)/game.bin.map >$(BUILD)/game.noi

$(BUILD)/wander.bin: $(WANDER_OBJS) wander.cfg
	$(LD) $(LDOPT) -o $@ $(WANDER_OBJS) $(CLIB) -m $@.map
	$(SCRIPTS)/ld65map2noi.pl <$(BUILD)/wander.bin.map >$(BUILD)/wander.noi

$(BUILD)/loader.bin: $(LOADER_OBJS) loader.cfg
	$(LD) $(LDOPT) -o $@ $(LOADER_OBJS) $(CLIB) -m $@.map
	$(SCRIPTS)/ld65map2noi.pl <$(BUILD)/loader.bin.map >$(BUILD)/loader.noi

$(patsubst %.c, $(BUILD)/%.s, $(wildcard *.c)): $(BUILD)/includes/gen_vars.h adv_globals.h myos.h 

$(patsubst %.s, $(BUILD)/%.o, $(wildcard *.s)): adv_globals.inc

$(BUILD)/%.s:	%.c
		$(CC) $(CCOPT) -o $@ $<

$(BUILD)/%.o:	$(BUILD)/%.s 
		$(AS) $(ASOPT) -o $@ $<

$(BUILD)/%.o:	%.s | adv_globals.inc
		$(AS) $(ASOPT) -o $@ $<


$(BUILD)/tiles/%.rle: $(BUILD)/tiles/%.til scripts/runlengthencode.pl
		scripts/runlengthencode.pl $< $@

tiles: $(BUILD)/tiles/charac.rle $(BUILD)/tiles/main.pal $(BUILD)/includes/gen_vars.h $(BUILD)/tiles/over-back.rle $(BUILD)/tiles/over-back.til.cuts $(BUILD)/tiles/over-front.rle $(BUILD)/tiles/over-front.til.cuts

$(BUILD)/tiles/tile-cutter.xml: \
		$(BUILD)/tiles/over-back.cutdefs \
		$(BUILD)/tiles/over-front.cutdefs \
		src-graphics/character.cutdefs \
		src-graphics/palette.xml \
		scripts/build-tilecut.sh
		scripts/build-tilecut.sh \
			src-graphics/palette.xml \
			src-graphics/character.cutdefs \
			$(BUILD)/tiles/over-front.cutdefs \
			$(BUILD)/tiles/over-back.cutdefs \
			$(BUILD)/tiles/tile-cutter.xml

$(BUILD)/tiles/charac.til $(BUILD)/tiles/main.pal $(BUILD)/tiles/over-back.til $(BUILD)/tiles/over-back.til.cuts $(BUILD)/tiles/over-front.til $(BUILD)/tiles/over-front.til.cuts &: \
		src-graphics/cave.png \
		src-graphics/character.png \
		src-graphics/Overworld16x24.png \
		src-graphics/objects.png \
		$(BUILD)/tiles/tile-cutter.xml


		scripts/tilecutter.py $(BUILD)/tiles/tile-cutter.xml $(shell pwd)

$(BUILD)/includes/gen_vars.h: $(BUILD)/tiles/charac.til $(BUILD)/tiles/over-back.til $(BUILD)/tiles/over-front.til
		echo -n -e "#define CHARAC_SPR_LEN\t" > $(BUILD)/includes/gen_vars.h
		stat -c%s $(BUILD)/tiles/charac.til >> $(BUILD)/includes/gen_vars.h
		echo -n -e "#define BACK_SPR_LEN\t" >> $(BUILD)/includes/gen_vars.h
		stat -c%s $(BUILD)/tiles/over-back.til >> $(BUILD)/includes/gen_vars.h
		echo -n -e "#define FRONT_SPR_LEN\t" >> $(BUILD)/includes/gen_vars.h
		stat -c%s $(BUILD)/tiles/over-front.til >> $(BUILD)/includes/gen_vars.h
		unix2dos $(BUILD)/includes/gen_vars.h


$(BUILD)/maps/home.bin $(BUILD)/tiles/over-back.cutdefs $(BUILD)/tiles/over-front.cutdefs: maps/home2.tmx scripts/makemapsandcuts.pl
		scripts/makemapsandcuts.pl maps/home2.tmx $(BUILD)/tiles/over-back.cutdefs $(BUILD)/tiles/over-front.cutdefs $(BUILD)/maps/home.bin

		
clean::
	-rm -R -f $(BUILD)/*