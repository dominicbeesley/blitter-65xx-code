		include ../../Makefile.defs

_dummy := $(shell mkdir -p $(BUILD)/tiles $(BUILD)/maps $(BUILD)/includes)


TARGETS=game loader wander

SSD=$(SSDS)/adventure.ssd

LD=ld65
LDOPT=-v -vm
CC=cc65
CCOPT=-T -O -Or -r -I $(TOP)/includes -I $(BUILD)/includes -I $(BUILD)/tiles -I .
AS=ca65 -I $(TOP)/includes
ASOPT=


CLIBDIR=$(TOP)/clib
CLIB=$(CLIBDIR)/clib.lib


EXTRA_ASM=$(addprefix $(BUILD)/, game.s dma.s loader.s wander.s adval.s brk.s sprite.s text.s tile_map.s)
.SECONDARY:$(EXTRA_ASM)

GAME_OBJS=	game draw_map dma myos tile_map brk adval sprite screenmaths 
WANDER_OBJS=	wander draw_map dma myos tile_map brk sprite screenmaths text
LOADER_OBJS=	loader dma myos rle_asm
INCS=$(BUILD)/includes/ $(BUILD)/includes/gen_vars.h

TILES=$(BUILD)/tiles/charac.rle $(BUILD)/tiles/main.pal $(BUILD)/includes/gen_vars.h $(BUILD)/tiles/over.back.rle $(BUILD)/tiles/over.back.til.cuts $(BUILD)/tiles/over.front.rle $(BUILD)/tiles/over.collide.rle $(BUILD)/tiles/over.front.til.cuts $(BUILD)/tiles/over.map.rle

GROUPS=over

GROUPS_O=$(addprefix $(BUILD)/, $(addsuffix .o, $(GROUPS)))
GROUPS_H_O=$(addprefix $(BUILD)/tiles/, $(addsuffix .h, $(GROUPS)))

TARGETS_O=$(addprefix $(BUILD)/, $(addsuffix .bin, $(TARGETS)))
GAME_OBJS_O=$(addprefix $(BUILD)/, $(addsuffix .o, $(GAME_OBJS))) $(GROUPS_O)
WANDER_OBJS_O=$(addprefix $(BUILD)/, $(addsuffix .o, $(WANDER_OBJS))) $(GROUPS_O)
LOADER_OBJS_O=$(addprefix $(BUILD)/, $(addsuffix .o, $(LOADER_OBJS)))


all: $(TARGETS_O)

ssd: $(SSD) 

deploy: ssd
	mkdir -p $(DEPLOY_TOP)/advent65 
	dfs read -i -d $(DEPLOY_TOP)/advent65 $(SSD)

$(SSD): $(TILES) $(TARGETS_O) ./ssd/_21BOOT.xxx $(CLIBDIR)/clib.rom
	dfs form -80 $(SSD)
	dfs title $(SSD) advent65
	dfs add -l FFFF2000 -e FFFF2000 -f 'T.CHARAC' $(SSD) $(BUILD)/tiles/charac.rle
	dfs add -l FFFF2000 -e FFFF2000 -f 'P.MAIN' $(SSD) $(BUILD)/tiles/over.pal
	dfs add -l FFFF2000 -e FFFF2000 -f 'T.OBACK' $(SSD) $(BUILD)/tiles/over.back.rle
	dfs add -l FFFF2000 -e FFFF2000 -f 'T.OFRONT' $(SSD) $(BUILD)/tiles/over.front.rle
	dfs add -l FFFF2000 -e FFFF2000 -f 'T.OCOLL' $(SSD) $(BUILD)/tiles/over.collide.rle
	dfs add -l FFFF2000 -e FFFF2000 -f 'M.OVER' $(SSD) $(BUILD)/tiles/over.map.rle
	dfs add -l FFFF0E00 -e FFFF0E00 -f '$.GAME' $(SSD) $(BUILD)/game.bin
	dfs add -l FFFF0E00 -e FFFF0E00 -f '$.WANDER' $(SSD) $(BUILD)/wander.bin
	dfs add -l FFFF0E00 -e FFFF0E00 -f '$.LOADER' $(SSD) $(BUILD)/loader.bin
	dfs add -l FFFFFFFF -e FFFFFFFF -f '$.!BOOT' $(SSD) ./ssd/_21BOOT.xxx
	dfs add -l FFFF8000 -e FFFF8000 -f 'R.CLIB' $(SSD) $(CLIBDIR)/clib.rom

$(BUILD)/game.bin: $(GAME_OBJS_O) game.cfg
	$(LD) $(LDOPT) -C game.cfg -o $@ $(GAME_OBJS_O) $(CLIB) -m $@.map
	$(SCRIPTS)/ld65map2noi.pl <$(BUILD)/game.bin.map >$(BUILD)/game.noi

$(BUILD)/wander.bin: $(WANDER_OBJS_O) wander.cfg
	$(LD) $(LDOPT) -C wander.cfg -o $@ $(WANDER_OBJS_O) $(CLIB) -m $@.map
	$(SCRIPTS)/ld65map2noi.pl <$(BUILD)/wander.bin.map >$(BUILD)/wander.noi

$(BUILD)/loader.bin: $(LOADER_OBJS_O) loader.cfg
	$(LD) $(LDOPT) -C loader.cfg -o $@ $(LOADER_OBJS_O) $(CLIB) -m $@.map
	$(SCRIPTS)/ld65map2noi.pl <$(BUILD)/loader.bin.map >$(BUILD)/loader.noi

$(patsubst %.c, $(BUILD)/%.s, $(wildcard *.c)): $(BUILD)/includes/gen_vars.h adv_globals.h myos.h 

$(patsubst %.s, $(BUILD)/%.o, $(wildcard *.s)): adv_globals.inc

$(BUILD)/%.s:	%.c
		$(CC) $(CCOPT) -o $@ $<

$(BUILD)/%.o:	$(BUILD)/%.s 
		$(AS) $(ASOPT) -o $@ $<

$(BUILD)/%.s:	$(BUILD)/tiles/%.c
		$(CC) $(CCOPT) -o $@ $<

$(BUILD)/%.o:	%.s | adv_globals.inc
		$(AS) $(ASOPT) -o $@ $<

$(BUILD)/tiles/%.rle: $(BUILD)/tiles/%.til scripts/runlengthencode.pl
		scripts/runlengthencode.pl $< $@

$(BUILD)/tiles/%.map.rle: $(BUILD)/tiles/%.map scripts/runlengthencode.pl
		scripts/runlengthencode.pl $< $@


$(BUILD)/tiles/charac.til:	maps/character.tilecuts.xml src-graphics/character.png
		$(SCRIPTS)/tilecutter.py maps/character.tilecuts.xml $(shell pwd) $(BUILD)/tiles

$(BUILD)/tiles/over.pal $(BUILD)/tiles/over.front.til $(BUILD)/tiles/over.back.til $(BUILD)/tiles/over.collide.til $(BUILD)/tiles/over.map &: \
		src-graphics/Overworld16x24.png \
		$(BUILD)/tiles/over.tilecuts.xml

		$(SCRIPTS)/tilecutter.py $(BUILD)/tiles/over.tilecuts.xml $(shell pwd)

$(BUILD)/includes/gen_vars.h: $(BUILD)/tiles/charac.til $(BUILD)/tiles/over.back.til $(BUILD)/tiles/over.front.til
		echo -n "#define CHARAC_SPR_LEN\t" > $(BUILD)/includes/gen_vars.h
		stat -c%s $(BUILD)/tiles/charac.til >> $(BUILD)/includes/gen_vars.h
		echo -n "#define BACK_SPR_LEN\t" >> $(BUILD)/includes/gen_vars.h
		stat -c%s $(BUILD)/tiles/over.back.til >> $(BUILD)/includes/gen_vars.h
		echo -n "#define FRONT_SPR_LEN\t" >> $(BUILD)/includes/gen_vars.h
		stat -c%s $(BUILD)/tiles/over.front.til >> $(BUILD)/includes/gen_vars.h
		unix2dos $(BUILD)/includes/gen_vars.h


$(BUILD)/tiles/home.map \
$(BUILD)/tiles/over.tilecuts.xml \
$(BUILD)/tiles/home.h &: $(wildcard maps/*.tmx) $(wildcard maps/*.tsx) maps/main.pal scripts/makemapsandcuts2.pl
		scripts/makemapsandcuts2.pl $(BUILD)/tiles "over" 0 maps/main.pal $(wildcard maps/*.tmx)

game.c:$(BUILD)/includes/all_maps.h

$(BUILD)/includes/all_maps.h:
		echo "#ifndef __ALLMAPS_H__" > $@
		echo "#define __ALLMAPS_H__" >>$@
		$(foreach x, $(GROUPS), echo "#include \"$x.h\"" >> $@)
		echo "#endif" >> $@
		
clean::
	-rm $(SSD)
	-rm $(CLEAN_EXTRA)

	-rm $(TARGETS_O)
	-rm $(addprefix $(BUILD)/, $(addsuffix .noi, $(TARGETS)))
	-rm $(addsuffix .map, $(TARGETS_O))
	-rm $(addsuffix .map, $(TARGETS_O))
	-rm $(GAME_OBJS_O)
	-rm $(WANDER_OBJS_O)
	-rm $(EXTRA_ASM)
	-rm $(LOADER_OBJS_O)	
	-rm $(BUILD)/includes/gen_vars.h
	-rm $(BUILD)/includes/all_maps.h
	-rm $(BUILD)/maps/home.bin
	-rm $(BUILD)/tiles/tile-cutter.xml
	-rm $(BUILD)/tiles/main.pal
	-rm $(addprefix $(BUILD)/tiles/, $(addprefix charac, .rle .til .tilecuts .til.cuts))
	-rm $(addprefix $(BUILD)/tiles/, $(addprefix over.front, .rle .til .til.cuts))
	-rm $(addprefix $(BUILD)/tiles/, $(addprefix over.back, .rle .til .til.cuts))
	-rm $(addprefix $(BUILD)/tiles/, $(addprefix over, .pal .tilecuts.xml))
