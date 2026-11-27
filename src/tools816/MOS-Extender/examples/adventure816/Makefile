		include ../../../../Makefile.defs

# adventure816 - advent ported to vbcc 65816 / MOS-Extender
#
# Each program's C files are compiled together (vc -O3 cross-module) into one
# $(BUILD)/<prog>_c.s, kept for reading and linting, then assembled and linked
# with that program's hand-written .s files and the generated map data.

TARGETS=	loader wander		# game: not ported yet

SSD=$(SSDS)/advent816.ssd

#----------------------------------------------------------------- tools
export VBCC        = /home/domin/vbcc65816/vbcc65816_linux/vbcc
COMPILER_ROOT	=	${VBCC}/bin
export PATH     := ${COMPILER_ROOT}:$(PATH)

TILES_DIR=$(BUILD)/tiles
GEN_INC=$(BUILD)/includes

INCS=../../includes $(GEN_INC) $(TILES_DIR) . ../../../../includes

CC=${COMPILER_ROOT}/vc
CFLAGS=-O3 -inline-size=0 +./dom-10000 -c99 $(foreach d,${INCS},-I$(d))
LD=${COMPILER_ROOT}/vlink
LDFLAGS=-m -b rawbin1 -nowarn=22 -Cvbcc -T./vlink.cmd -L${VBCC}/targets/65816-dom/lib
AS=${COMPILER_ROOT}/vasm6502_oldstyle
ASFLAGS= -dotdir -816 -Fvobj $(foreach d,${INCS},-I$(d))
# 65816 size linter: advisory only, runs on every make after the link
LINT=$(SCRIPTS)/lint65816.py -s vasm $(foreach d,${INCS},-I$(d))

_dummy := $(shell mkdir -p $(TILES_DIR) $(GEN_INC))

#----------------------------------------------------------------- libraries
OSLIBEXT_DIR=../../clib/oslib-ext
OSLIBEXT_LIB:=$(abspath $(BUILD)/$(OSLIBEXT_DIR)/liboslibext.a)

MOSEXT_DIR=../../mos-ext
MOSEXT_BIN=$(abspath $(BUILD)/$(MOSEXT_DIR)/mos-ext.bin)

# always ask the sub-makes; they decide whether anything needs rebuilding
$(OSLIBEXT_LIB): FORCE
	$(MAKE) -C $(OSLIBEXT_DIR)

$(MOSEXT_BIN): FORCE
	$(MAKE) -C $(MOSEXT_DIR)

#----------------------------------------------------------------- programs
# per program: C files (compiled together), .s files, and map data or not
game_C=		game dma tile_map adval sprite screenmaths draw_map
game_S=		startup
game_MAPS=	yes
wander_C=	wander dma sprite screenmaths text tile_map draw_map
wander_S=	startup
wander_MAPS=	yes
loader_C=	loader dma
loader_S=	startup rle_asm
loader_MAPS=

# map groups: each makes tiles/<group>.c/.h (see makemapsandcuts2.pl below)
GROUPS=		over
GROUPS_H=	$(addprefix $(TILES_DIR)/, $(addsuffix .h, $(GROUPS)))
GROUPS_O=	$(addprefix $(BUILD)/, $(addsuffix .o, $(GROUPS)))
ALL_MAPS_H=	$(GEN_INC)/all_maps.h

# objects linked into program $(1)
prog_objs=	$(BUILD)/$(1)_c.o $(addprefix $(BUILD)/, $(addsuffix .o, $($(1)_S))) \
		$(if $($(1)_MAPS),$(GROUPS_O))

TARGETS_O=	$(addprefix $(BUILD)/, $(addsuffix .bin, $(TARGETS)))

# a failed vc leaves a part-written _c.s; don't let the next make trust it
.DELETE_ON_ERROR:

.PHONY: all tiles ssd deploy lint clean FORCE $(addprefix lint-, $(TARGETS))

all: $(TARGETS_O) lint

# one set of rules per program
define PROGRAM
$(BUILD)/$(1)_c.s: $(addsuffix .c, $($(1)_C)) $(wildcard *.h) \
		$(if $($(1)_MAPS),$(ALL_MAPS_H) $(GROUPS_H))
	$$(CC) $$(CFLAGS) -S -o $$@ $$(filter %.c, $$^)

$(BUILD)/$(1).bin: $(call prog_objs,$(1)) $(OSLIBEXT_LIB) $(1).cfg
	$$(LD) $$(LDFLAGS) -M$$(basename $$@).map -symfile $$(basename $$@).sym \
		-symfmt "DEF %s %06llx" $(call prog_objs,$(1)) $$(OSLIBEXT_LIB) -o $$@ -lvc
	$$(SCRIPTS)/ld65map2noi.pl <$$(basename $$@).map >$$(basename $$@).noi

# lint after the link; '-' so lint messages never stop the build
lint-$(1): $(BUILD)/$(1).bin
	-$$(LINT) $(addsuffix .s, $($(1)_S)) $(BUILD)/$(1)_c.s
endef
$(foreach p,game wander loader,$(eval $(call PROGRAM,$(p))))

lint: $(addprefix lint-, $(TARGETS))

.SECONDARY: $(foreach p,game wander loader,$(BUILD)/$(p)_c.s)

#----------------------------------------------------------------- compile
# vc's cross-module .s, and hand-written .s
$(BUILD)/%_c.o: $(BUILD)/%_c.s
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/%.o: %.s adv_globals.inc
	$(AS) $(ASFLAGS) -o $@ $<

# generated map data
$(BUILD)/%.o: $(TILES_DIR)/%.c mapdef.h
	$(CC) $(CFLAGS) -c -o $@ $<

#----------------------------------------------------------------- maps, tiles
# makemapsandcuts2.pl writes all of these in one run
$(TILES_DIR)/over.c $(TILES_DIR)/over.h $(TILES_DIR)/over.map \
$(TILES_DIR)/over.tilecuts.xml &: \
		$(wildcard maps/*.tmx) $(wildcard maps/*.tsx) maps/main.pal \
		scripts/makemapsandcuts2.pl
	scripts/makemapsandcuts2.pl $(TILES_DIR) over 0 maps/main.pal $(wildcard maps/*.tmx)

$(ALL_MAPS_H): Makefile
	echo "#ifndef __ALLMAPS_H__" > $@
	echo "#define __ALLMAPS_H__" >>$@
	$(foreach x, $(GROUPS), echo "#include \"$x.h\"" >> $@;)
	echo "#endif" >> $@

$(TILES_DIR)/over.pal $(TILES_DIR)/over.front.til $(TILES_DIR)/over.back.til \
$(TILES_DIR)/over.collide.til &: \
		src-graphics/Overworld16x24.png $(TILES_DIR)/over.tilecuts.xml
	$(SCRIPTS)/tilecutter.py $(TILES_DIR)/over.tilecuts.xml $(shell pwd)

$(TILES_DIR)/charac.til: maps/character.tilecuts.xml src-graphics/character.png
	$(SCRIPTS)/tilecutter.py maps/character.tilecuts.xml $(shell pwd) $(TILES_DIR)

$(TILES_DIR)/%.rle: $(TILES_DIR)/%.til scripts/runlengthencode.pl
	scripts/runlengthencode.pl $< $@

$(TILES_DIR)/%.map.rle: $(TILES_DIR)/%.map scripts/runlengthencode.pl
	scripts/runlengthencode.pl $< $@

# files on the disc: name on disc, then file
DISC_TILES=	T.CHARAC:charac.rle \
		P.MAIN:over.pal \
		T.OBACK:over.back.rle \
		T.OFRONT:over.front.rle \
		T.OCOLL:over.collide.rle \
		M.OVER:over.map.rle
TILES=		$(addprefix $(TILES_DIR)/, $(foreach t,$(DISC_TILES),$(word 2,$(subst :, ,$(t)))))

tiles: $(TILES)

#----------------------------------------------------------------- disc
ssd: $(SSD)

$(SSD): $(TILES) $(TARGETS_O) $(MOSEXT_BIN) ./ssd/_21BOOT.xxx
	dfs form -80 $@
	dfs title $@ advent816
	dfs opt4 -3 $@
	$(foreach t,$(DISC_TILES),dfs add -l FFFF2000 -e FFFF2000 -f '$(word 1,$(subst :, ,$(t)))' $@ $(TILES_DIR)/$(word 2,$(subst :, ,$(t)));)
	$(foreach p,$(TARGETS),dfs add -l 00010000 -e 00010000 -f '$$.$(shell echo $(p) | tr a-z A-Z)' $@ $(BUILD)/$(p).bin;)
	dfs add -l FFFFFFFF -e FFFFFFFF -f '$$.!BOOT' $@ ./ssd/_21BOOT.xxx
	dfs add $@ $(MOSEXT_BIN)

deploy: ssd
	mkdir -p $(DEPLOY_TOP)/advent816
	dfs read -i -d $(DEPLOY_TOP)/advent816 $(SSD)

#----------------------------------------------------------------- clean
# everything this Makefile makes lives in $(BUILD) (libraries have their own)
# guard: only rm -rf a BUILD that ends in this example's own path, so an
# empty or wrong BUILD/RELDIR/BUILD_TOP can't take out the whole build tree
clean::
	-rm -f $(SSD)
	$(if $(filter %/tools816/MOS-Extender/examples/adventure816,$(BUILD)),\
		-rm -rf $(BUILD),\
		$(error clean: refusing to rm -rf BUILD='$(BUILD)'))
