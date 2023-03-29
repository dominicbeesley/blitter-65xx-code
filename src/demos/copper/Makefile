_dummy := $(shell mkdir -p build build/includes)


LD=ld65
LDOPT=-v -vm
CC=cc65
CCOPT=-g -T -O -Or -r -I ../../../includes -I build/includes -I /usr/local/share/cc65/include
AS=ca65 -I ../../../includes
ASOPT=
LOADER_OBJS=build/loader.o build/dma.o build/myos.o
DEMO_OBJS=build/dma.o build/myos.o build/main.o build/aeris-test.o build/rainbow.o build/effects.o
ASM_DEPS=globals.inc $(wildcard ../../../includes/*.inc)

.PHONY:clean all 

all:copper.ssd


copper.ssd: build/loader.bin build/demo.bin
	dfs form -80 copper.ssd
	dfs add -l 0xE00 -e 0xE00 -f "$.LOADER" copper.ssd build/loader.bin
	dfs add -l 0xE00 -e 0xE00 -f "$.DEMO" copper.ssd build/demo.bin
	dfs add -f "B.RAIN" copper.ssd assets/RAIN.B
	dfs add -f "$.!BOOT" copper.ssd _21BOOT.txt
	dfs opt4 -3 copper.ssd

	mkdir -p ~/hostfs/copper
	dfs read -i -d ~/hostfs/copper -w "*.*" copper.ssd


build/includes/gen_vars.h:
	touch build/includes/gen_vars.h

build/loader.bin: $(LOADER_OBJS) loader.cfg
	$(LD) $(LDOPT) -C loader.cfg -o $@ $(LOADER_OBJS) bbc.lib -m $@.map
	../../../scripts/ld65map2noi.pl <build/loader.bin.map >build/loader.noi

build/demo.bin: $(DEMO_OBJS) demo.cfg
	$(LD) $(LDOPT) -C demo.cfg -o $@ $(DEMO_OBJS) bbc.lib -m $@.map
	../../../scripts/ld65map2noi.pl <build/demo.bin.map >build/demo.noi


build/rainbow.s: rainbow.pl
	./rainbow.pl > build/rainbow.s

$(patsubst %.c, build/%.s, $(wildcard *.c)): build/includes/gen_vars.h globals.h myos.h 

$(patsubst %.s, build/%.o, $(wildcard *.s)): globals.inc

build/%.s:	%.c
		$(CC) $(CCOPT) -o $@ $<

build/%.o:	build/%.s 
		$(AS) $(ASOPT) -l $(basename $@).lst -o $@ $<

build/%.o:	%.s $(ASM_DEPS)
		$(AS) $(ASOPT) -l $(basename $@).lst -o $@ $<



clean::
	
	-rm -R -f build/*
	-rm copper.ssd
