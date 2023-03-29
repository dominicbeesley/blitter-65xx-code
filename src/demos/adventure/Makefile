_dummy := $(shell mkdir -p build build/tiles build/maps build/includes)


TILECUT=/cygdrive/d/work/vs2017/AuthorityFileLtd/Games/TileCutter/TileCutter/bin/Debug/TileCutter.exe

CLEAN_EXTRA= \
				tiles/charac.til \
				tiles/main.pal \
				gen_vars.h

TARGETS=	build/game.bin build/loader.bin build/wander.bin adventure.ssd

LD=ld65
LDOPT=-C game.cfg -v -vm
CC=cc65
CCOPT=-T -O -Or -r -I ../../../includes -I build/includes -I /usr/local/share/cc65/include
AS=ca65 -I ../../../includes
ASOPT=

CLIBDIR=~/cc65-rom

#CLIB=bbc.lib
CLIB=$(CLIBDIR)/clib.lib


.SECONDARY:build/game.s build/dma.s build/loader.s build/wander.s

GAME_OBJS=	build/game.o build/draw_map.o build/dma.o \
		build/myos.o build/tile_map.o build/brk.o \
		build/adval.o build/sprite.o build/screenmaths.o 
WANDER_OBJS=	build/wander.o build/draw_map.o build/dma.o \
		build/myos.o build/tile_map.o build/brk.o \
		build/sprite.o build/screenmaths.o \
		build/text.o
LOADER_OBJS=build/loader.o build/dma.o build/myos.o build/rle_asm.o
INCS=build/includes/ build/includes/gen_vars.h



all:: $(TARGETS)

build/clib.rom:
	cp $(CLIBDIR)/clib.rom build/clib.rom

adventure.ssd: ssd/include.lst tiles build/clib.rom build/wander.bin build/game.bin build/maps/home.bin build/loader.bin 
	../../../scripts/buildssd.sh --dest adventure.ssd --hostfs ~/hostfs --name advent65 ./ssd
	../../../scripts/hostfs2vdfs.sh ~/hostfs/advent65 ~/vdfs/advent65

build/game.bin: $(GAME_OBJS) game.cfg
	$(LD) $(LDOPT) -o $@ $(GAME_OBJS) $(CLIB) -m $@.map
	../../../scripts/ld65map2noi.pl <build/game.bin.map >build/game.noi

build/wander.bin: $(WANDER_OBJS) wander.cfg
	$(LD) $(LDOPT) -o $@ $(WANDER_OBJS) $(CLIB) -m $@.map
	../../../scripts/ld65map2noi.pl <build/wander.bin.map >build/wander.noi


build/loader.bin: $(LOADER_OBJS) loader.cfg
	$(LD) $(LDOPT) -o $@ $(LOADER_OBJS) $(CLIB) -m $@.map
	../../../scripts/ld65map2noi.pl <build/loader.bin.map >build/loader.noi

$(patsubst %.c, build/%.s, $(wildcard *.c)): build/includes/gen_vars.h adv_globals.h myos.h 

$(patsubst %.s, build/%.o, $(wildcard *.s)): adv_globals.inc

build/%.s:	%.c
		$(CC) $(CCOPT) -o $@ $<

build/%.o:	build/%.s 
		$(AS) $(ASOPT) -o $@ $<

build/%.o:	%.s | adv_globals.inc
		$(AS) $(ASOPT) -o $@ $<


build/tiles/%.rle: build/tiles/%.til scripts/runlengthencode.pl
		scripts/runlengthencode.pl $< $@

tiles: build/tiles/charac.rle build/tiles/main.pal build/includes/gen_vars.h build/tiles/over-back.rle build/tiles/over-back.til.cuts build/tiles/over-front.rle build/tiles/over-front.til.cuts

build/tiles/tile-cutter.xml: \
		build/tiles/over-back.cutdefs \
		build/tiles/over-front.cutdefs \
		src-graphics/character.cutdefs \
		src-graphics/palette.xml \
		scripts/build-tilecut.sh
		scripts/build-tilecut.sh

build/includes/gen_vars.h build/tiles/charac.til build/tiles/main.pal build/tiles/over-back.til build/tiles/over-back.til.cuts build/tiles/over-front.til build/tiles/over-front.til.cuts: \
		src-graphics/cave.png \
		src-graphics/character.png \
		src-graphics/Overworld16x24.png \
		src-graphics/objects.png \
		build/tiles/tile-cutter.xml


		$(TILECUT) "$(shell cygpath -w "build/tiles/tile-cutter.xml")"

		echo -n -e "#define CHARAC_SPR_LEN\t" > build/includes/gen_vars.h
		stat -c%s build/tiles/charac.til >> build/includes/gen_vars.h
		echo -n -e "#define BACK_SPR_LEN\t" >> build/includes/gen_vars.h
		stat -c%s build/tiles/over-back.til >> build/includes/gen_vars.h
		echo -n -e "#define FRONT_SPR_LEN\t" >> build/includes/gen_vars.h
		stat -c%s build/tiles/over-front.til >> build/includes/gen_vars.h
		unix2dos build/includes/gen_vars.h


build/maps/home.bin build/tiles/over-back.cutdefs build/tiles/over-front.cutdefs: maps/home2.tmx scripts/makemapsandcuts.pl
		scripts/makemapsandcuts.pl maps/home2.tmx build/tiles/over-back.cutdefs build/tiles/over-front.cutdefs build/maps/home.bin

		
clean::
	-rm -R -f build/*