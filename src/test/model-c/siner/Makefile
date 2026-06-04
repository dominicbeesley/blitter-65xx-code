		include ../../../Makefile.defs

AS=ca65 -I $(TOP)/includes 
LD=ld65

OBJS=siner sintab sinsprites maths
TARGETS=siner
DEPS=

OBJS_O=$(addprefix $(BUILD)/, $(addsuffix .o, $(OBJS)))
TARGETS_O=$(addprefix $(BUILD)/, $(addsuffix .bin, $(TARGETS)))

all:	$(TARGETS_O)
ssd:	all
deploy:	all

.SECONDARY:

$(BUILD)/%.asm $(BUILD)/%.bbc:%.bspr
	../scripts/bsprcvt.py $< "S_" $(basename $@).spr $(basename $@).bbc
	echo "  .rodata" > $@
	echo "  .export sprite_data, sprite_data_end" >> $@
	echo "sprite_data:" >> $@
	echo "  .incbin \"$(basename $@).spr\"" >> $@
	echo "sprite_data_end:" >> $@
	echo "  .end" >> $@

$(BUILD)/sintab.asm: sintab.pl
	./sintab.pl 512 >$@

$(BUILD)/%.o: 	$(BUILD)/%.asm $(DEPS) $(INCS)
	$(AS) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/%.o: 	%.asm $(DEPS) $(INCS)
	$(AS) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/%.bin: $(OBJS_O) %.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map -o $@ -C $(filter %.cfg, $^) $(OBJS_O) $(LIBS)
	$(SCRIPTS)/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	cp $(notdir $@).inf $(BUILD)
	da65 -S 0x1200 $@ >$@.da.s

clean:
	-rm $(OBJS_O)
	-rm $(patsubst %.o, %.lst, $(OBJS_O))
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
	-rm $(patsubst %.bin, %.sy2, $(TARGETS_O))
	-rm $(patsubst %.bin, %.map, $(TARGETS_O))
	-rm $(patsubst %.bin, %.noi, $(TARGETS_O))
	-rm $(addprefix $(BUILD)/, sintab.asm sinsprites.spr sinsprites.bbc sinsprites.asm siner.bin.da.S)
