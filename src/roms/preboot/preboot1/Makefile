		include ../../../Makefile.defs

AS=ca65 -U -I $(TOP)/includes -I $(BUILD) -I ../includes
LD=ld65
INCS=$(wildcard $(TOP)/includes/*.inc) $(wildcard *.inc) $(wildcard ../includes *.inc)
DEPS=$(INCS)
OBJS=preboot1 spi


OBJS_C20K_O = $(addprefix $(BUILD)/c20k/, $(addsuffix .o, $(OBJS)))
TARGETS_C20K_O = $(BUILD)/c20k/preboot1.vec
DEFS_C20K = -D PREBOOT_BASE=0x300000 -D C20K

OBJS_MK2_O = $(addprefix $(BUILD)/mk2/, $(addsuffix .o, $(OBJS)))
TARGETS_MK2_O = $(BUILD)/mk2/preboot1.mif
DEFS_MK2 = -D PREBOOT_BASE=0x180000 -D MK2

TARGETS_O = $(TARGETS_MK2_O) $(TARGETS_C20K_O)

X:=$(shell mkdir -p $(BUILD)/mk2)
X:=$(shell mkdir -p $(BUILD)/c20k)

.PHONY: all clean

all:	$(TARGETS_O)
ssd:	all
deploy:	all

#dont know why I need this but otherwise gnu make deletes the .o files!
.PRECIOUS: $(OBJS_O)

$(BUILD)/c20k/%.vec:$(BUILD)/c20k/%.rom
	$(SCRIPTS)/bin2bitvector.pl $< >$@

$(BUILD)/mk2/%.mif:$(BUILD)/mk2/%.rom
	$(SCRIPTS)/bin2mif.pl $< >$@

$(BUILD)/c20k/%.o: 	%.asm $(DEPS) 
	$(AS) $(DEFS_C20K) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/mk2/%.o: 	%.asm $(DEPS) 
	$(AS) $(DEFS_MK2) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/c20k/%.o: 	../lib/%.asm $(DEPS) 
	$(AS) $(DEFS_C20K) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/mk2/%.o: 	../lib/%.asm $(DEPS) 
	$(AS) $(DEFS_MK2) -o $@ -g -l $(basename $@).lst $<


$(BUILD)/c20k/preboot1.rom: $(OBJS_C20K_O) preboot1.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C $(filter %.cfg, $^) $(OBJS_C20K_O) $(LIBS)
	$(SCRIPTS)/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)/c20k/
	$(SCRIPTS)/ld65free.pl $(filter %.cfg, $^) $(basename $@).map >$(basename $@).free.txt
	cat $(basename $@).free.txt

$(BUILD)/mk2/preboot1.rom: $(OBJS_MK2_O) preboot1.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C $(filter %.cfg, $^) $(OBJS_MK2_O) $(LIBS)
	$(SCRIPTS)/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)/mk2/
	$(SCRIPTS)/ld65free.pl $(filter %.cfg, $^) $(basename $@).map >$(basename $@).free.txt
	cat $(basename $@).free.txt


clean:
	-rm $(TARGETS_O)
	-rm $(patsubst %.vec, %.rom, $(TARGETS_O))
	-rm $(patsubst %.vec, %.sy2, $(TARGETS_O))
	-rm $(patsubst %.vec, %.map, $(TARGETS_O))
	-rm $(patsubst %.vec, %.noi, $(TARGETS_O))
	-rm $(patsubst %.vec, %.dbg, $(TARGETS_O))
	-rm $(OBJS_C20K_O)
	-rm $(OBJS_MK2_O)
	-rm $(patsubst %.o, %.lst, $(OBJS_C20K_O))
	-rm $(patsubst %.o, %.lst.rel, $(OBJS_C20K_O))
	-rm $(patsubst %.o, %.lst, $(OBJS_MK2_O))
	-rm $(patsubst %.o, %.lst.rel, $(OBJS_MK2_O))


