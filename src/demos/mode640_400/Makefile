_dummy := $(shell mkdir -p build build/includes)



LD=ld65
LDOPT=-v -vm
CC=cc65
CCOPT=-g -T -O -Or -r -I ../../../includes -I /usr/local/share/cc65/include
AS=ca65 -I ../../../includes
ASOPT=
DEMO_OBJS=build/main.o build/myos.o
ASM_DEPS=$(wildcard ../../../includes/*.inc)
DEPS=$(wildcard *.h) build/pics.h

.PHONY:clean all 

all:640x400.ssd


640x400.ssd: build/demo.bin
	dfs form -80 640x400.ssd
	dfs add -l 0xE00 -e 0xE00 -f "DEMO" 640x400.ssd build/demo.bin
	dfs add 640x400.ssd build/*.bbc.inf

	mkdir -p ~/hostfs/640x400
	dfs read -i -d ~/hostfs/640x400 -w "*.*" 640x400.ssd



build/demo.bin: $(DEMO_OBJS) demo.cfg
	$(LD) $(LDOPT) -C demo.cfg -o $@ $(DEMO_OBJS) bbc.lib -m $@.map
	../../../scripts/ld65map2noi.pl <build/demo.bin.map >build/demo.noi


build/%.s:	%.c $(DEPS)
		$(CC) $(CCOPT) -o $@ $<

build/%.o:	build/%.s 
		$(AS) $(ASOPT) -l $(basename $@).lst -o $@ $<

build/%.o:	%.s $(ASM_DEPS)
		$(AS) $(ASOPT) -l $(basename $@).lst -o $@ $<

build/%.bbc:	src_pngs/%.png
		perl png2bbc.pl $< $@

build/pics.h:	$(addprefix build/, $(notdir $(patsubst %.png,%.bbc, $(wildcard src_pngs/*.png))))
		./dopics.sh

clean::
	-rm -R -f build/*
	-rm 640x400.ssd
