_dummy := $(shell mkdir -p build build/includes)


TILECUT=/cygdrive/d/work/vs2017/AuthorityFileLtd/Games/TileCutter/TileCutter/bin/Debug/TileCutter.exe

LD=ld65
LDOPT=-v -vm
CC=cc65
CCOPT=-g -T -O -Or -r -I ../../../includes -I build/includes -I /usr/local/share/cc65/include
AS=ca65 -I ../../../includes
ASOPT=
LOADER_OBJS=build/loader.o build/dma.o build/myos.o
DEMO_OBJS=build/dma.o build/myos.o build/fontmap.o build/main.o build/aeris-test.o
ASM_DEPS=globals.inc $(wildcard ../../../includes/*.inc)

.PHONY:clean all 

all:bigfonts.ssd


bigfonts.ssd: build/font.til build/main.pal build/loader.bin build/demo.bin
	dfs form -80 bigfonts.ssd
	dfs add -f "T.FONT" bigfonts.ssd build/font.til
	dfs add -f "T.OWL" bigfonts.ssd build/owl.til
	dfs add -f "P.MAIN" bigfonts.ssd build/main.pal
	dfs add -l 0x1900 -e 0x1900 -f "LOADER" bigfonts.ssd build/loader.bin
	dfs add -l 0x1100 -e 0x1100 -f "DEMO" bigfonts.ssd build/demo.bin
	dfs add -f "!BOOT" bigfonts.ssd _21BOOT.txt 
	dfs title bigfonts.ssd "bigfonts"
	dfs opt4 -3 bigfonts.ssd

	mkdir -p ~/hostfs/bigfonts
	dfs read -i -d ~/hostfs/bigfonts -w "*.*" bigfonts.ssd


build/includes/gen_vars.h:
	touch build/includes/gen_vars.h

build/loader.bin: $(LOADER_OBJS) loader.cfg
	$(LD) $(LDOPT) -C loader.cfg -o $@ $(LOADER_OBJS) bbc.lib -m $@.map
	../../../scripts/ld65map2noi.pl <build/loader.bin.map >build/loader.noi

build/demo.bin: $(DEMO_OBJS) demo.cfg
	$(LD) $(LDOPT) -C demo.cfg -o $@ $(DEMO_OBJS) bbc.lib -m $@.map
	../../../scripts/ld65map2noi.pl <build/demo.bin.map >build/demo.noi


$(patsubst %.c, build/%.s, $(wildcard *.c)): build/includes/gen_vars.h globals.h myos.h 

$(patsubst %.s, build/%.o, $(wildcard *.s)): globals.inc

build/%.s:	%.c
		$(CC) $(CCOPT) -o $@ $<

build/%.o:	build/%.s 
		$(AS) $(ASOPT) -l $(basename $@).lst -o $@ $<

build/%.o:	%.s $(ASM_DEPS)
		$(AS) $(ASOPT) -l $(basename $@).lst -o $@ $<


build/fontmap.s: fontmap/ascii2font.txt fontmap/big_fontmap.tmx scripts/fontmap2asm.pl
		scripts/fontmap2asm.pl fontmap/big_fontmap.tmx fontmap/ascii2font.txt build/fontmap.s


build/main.pal build/font.til: src-gra/big_font_parts_mo2_g2.png fontmap/tile-cutter.xml
	$(TILECUT) "$(shell cygpath -w "fontmap/tile-cutter.xml")"


clean::
	-rm -f build/main.pal build/font.til
	-rm -R -f build/*
	-rm bigfonts.ssd
