AS=ca65 -I ../../../includes
LD=ld65
INCS=$(wildcard ../../../includes/*.inc) $(filter-out version-date.inc, $(wildcard *.inc))
DEPS=$(INCS) 
OBJS=	bltutil_romheader bltutil bltutil_flashutils \
	bltutil_utils bltutil_noice bltutil_jimstuff \
	bltutil_sound bltutil_heap bltutil_sound_irq \
	bltutil_cfg
ROMNO=F

BUILD=build

BBCOBJS = $(addprefix $(BUILD)/, $(addsuffix .o, $(OBJS)))
ELKOBJS = $(addprefix $(BUILD)/, $(addsuffix .e.o, $(OBJS)))
ALLOBJS = $(BBCOBJS) $(ELKOBJS)

.PHONY: all clean

all::	$(BUILD)/bltutil.rom $(BUILD)/bltutil.e.rom

#dont know why I need this but otherwise gnu make deletes the .o files!
poo: $(ALLOBJS)

$(BUILD)/version-date.inc: $(DEPS) $(filter-out %.da.asm, $(wildcard *.asm))
	../../../scripts/gendate.sh $@

$(BUILD)/bltutil_romheader.o: $(BUILD)/version-date.inc
$(BUILD)/bltutil_romheader.e.o: $(BUILD)/version-date.inc

$(BUILD)/%.o: 	%.asm $(DEPS) 
	$(AS) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/%.e.o: 	%.asm $(DEPS) 
	$(AS) -D MACH_ELK -o $@ -g -l $(basename $@).lst $<

$(BUILD)/%.rom: $(BBCOBJS) bltutil.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map -o $@ -C bltutil.cfg $(BBCOBJS) $(LIBS)
	echo "$.BLTUTIL FF8000 FF8000" >$@.inf
	da65 -S 0x8000 -v --comments 4 -o $@.da.asm $@
	../../../../scripts/getsymbols.pl $(ROMNO) <$(basename $@).sy2 >$(basename $@).noi
	../../../../scripts/bemsymbols.pl $(ROMNO) <$(basename $@).sy2 >$(basename $@).bem

$(BUILD)/%.e.rom: $(ELKOBJS) bltutil.cfg
	echo "E.BLTUTIL FF8000 FF8000" >$@.inf
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map -o $@ -C bltutil.cfg $(ELKOBJS) $(LIBS)
	da65 -S 0x8000 -v --comments 4 -o $@.e.da.asm $@
	../../../../scripts/getsymbols.pl $(ROMNO) <$(basename $@).sy2 >$(basename $@).noi
	../../../../scripts/bemsymbols.pl $(ROMNO) <$(basename $@).sy2 >$(basename $@).bem

clean::
	-rm build/*


$(shell mkdir -p $(BUILD))