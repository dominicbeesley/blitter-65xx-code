		include ../../Makefile.defs

AS=ca65 -U -I $(TOP)/includes -I $(BUILD)
LD=ld65
INCS=$(wildcard $(TOP)/includes/*.inc) $(filter-out version-date.inc, $(wildcard *.inc))
DEPS=$(INCS) 
OBJS=	bltutil_romheader bltutil bltutil_flashutils \
	bltutil_utils bltutil_jimstuff \
	bltutil_sound bltutil_heap bltutil_sound_irq \
	bltutil_cfg bltutil_i2c bltutil_autohazel
OBJS_N=	bltutil_noice
ROMNO=F

TARGETS=bltutil bltutil.e bltutil.n bltutil.n.e

BBCOBJS_O = $(addprefix $(BUILD)/, $(addsuffix .o, $(OBJS)))
ELKOBJS_O = $(addprefix $(BUILD)/E/, $(addsuffix .o, $(OBJS)))
BBCOBJS_N_O = $(addprefix $(BUILD)/N/, $(addsuffix .o, $(OBJS) $(OBJS_N)))
ELKOBJS_N_O = $(addprefix $(BUILD)/NE/, $(addsuffix .o, $(OBJS) $(OBJS_N)))
ALLOBJS_O = $(BBCOBJS_O) $(ELKOBJS_O) $(BBCOBJS_N_O) $(ELKOBJS_N_O)
TARGETS_O = $(addprefix $(BUILD)/, $(addsuffix .rom, $(TARGETS)))

X:=$(shell mkdir $(BUILD)/E)
X:=$(shell mkdir $(BUILD)/N)
X:=$(shell mkdir $(BUILD)/NE)

.PHONY: all clean

all:	$(TARGETS_O)
ssd:	all
deploy:	all

#dont know why I need this but otherwise gnu make deletes the .o files!
.PRECIOUS: $(ALLOBJS_O)

$(BUILD)/version-date.inc: $(DEPS) $(filter-out %.da.asm, $(wildcard *.asm))
	$(SCRIPTS)/gendate.sh $@

$(BUILD)/bltutil_romheader.o: $(BUILD)/version-date.inc
$(BUILD)/E/bltutil_romheader.o: $(BUILD)/version-date.inc

$(BUILD)/%.o: 	%.asm $(DEPS) 
	$(AS) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/E/%.o: 	%.asm $(DEPS) 
	$(AS) -D MACH_ELK -o $@ -g -l $(basename $@).lst $<

$(BUILD)/NE/%.o: 	%.asm $(DEPS) 
	$(AS) -D MACH_ELK -D INC_NOICE -o $@ -g -l $(basename $@).lst $<

$(BUILD)/N/%.o: 	%.asm $(DEPS) 
	$(AS) -D INC_NOICE -o $@ -g -l $(basename $@).lst $<


$(BUILD)/bltutil.rom: $(BBCOBJS_O) bltutil.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C bltutil.cfg $(BBCOBJS_O) $(LIBS)
	echo "$.BLTUTIL FF8000 FF8000" >$@.inf
	$(SCRIPTS)/getsymbols.pl $(ROMNO) <$(basename $@).sy2 >$(basename $@).noi
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)
	$(SCRIPTS)/ld65free.pl bltutil.cfg $(basename $@).map >$(basename $@).free.txt
	cat $(basename $@).free.txt

$(BUILD)/bltutil.e.rom: $(ELKOBJS_O) bltutil.cfg
	echo "E.BLTUTIL FF8000 FF8000" >$@.inf
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C bltutil.cfg $(ELKOBJS_O) $(LIBS)
	$(SCRIPTS)/getsymbols.pl $(ROMNO) <$(basename $@).sy2 >$(basename $@).noi
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)/E
	$(SCRIPTS)/ld65free.pl bltutil.cfg $(basename $@).map >$(basename $@).free.txt
	cat $(basename $@).free.txt

$(BUILD)/bltutil.n.rom: $(BBCOBJS_N_O) bltutil.n.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C bltutil.n.cfg $(BBCOBJS_N_O) $(LIBS)
	echo "$.BLTUTIN FF8000 FF8000" >$@.inf
	$(SCRIPTS)/getsymbols.pl $(ROMNO) <$(basename $@).sy2 >$(basename $@).noi
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)/N
	$(SCRIPTS)/ld65free.pl bltutil.n.cfg $(basename $@).map >$(basename $@).free.txt
	cat $(basename $@).free.txt

$(BUILD)/bltutil.n.e.rom: $(ELKOBJS_N_O) bltutil.n.cfg
	echo "E.BLTUTIN FF8000 FF8000" >$@.inf
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C bltutil.n.cfg $(ELKOBJS_N_O) $(LIBS)
	$(SCRIPTS)/getsymbols.pl $(ROMNO) <$(basename $@).sy2 >$(basename $@).noi
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)/NE
	$(SCRIPTS)/ld65free.pl bltutil.n.cfg $(basename $@).map >$(basename $@).free.txt
	cat $(basename $@).free.txt

clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
	-rm $(patsubst %.rom, %.sy2, $(TARGETS_O))
	-rm $(patsubst %.rom, %.map, $(TARGETS_O))
	-rm $(patsubst %.rom, %.noi, $(TARGETS_O))
	-rm $(patsubst %.rom, %.dbg, $(TARGETS_O))
	-rm $(ALLOBJS_O)
	-rm $(patsubst %.o, %.lst, $(ALLOBJS_O))
	-rm $(patsubst %.o, %.lst.rel, $(ALLOBJS_O))
	-rm $(BUILD)/version-date.inc


