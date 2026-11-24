		include ../../../../Makefile.defs

AS=ca65
LD=ld65
INCDIRS=../../includes-ca65 $(TOP)/includes $(BUILD) .
INCS=$(foreach dir,$(INCDIRS),$(wildcard $(dir)/*.inc)) 
DEPS=$(INCS) 
OBJS=	bas816new arith_new
ROMNO=
ASFLAGS=$(foreach dir,$(INCDIRS),-I $(dir)) 
ASDEFS=-D MOSEXT
LINT=$(SCRIPTS)/lint65816.py

TARGETS=bas816new_MOS_EXT

OBJS_O = $(addprefix $(BUILD)/, $(addsuffix .o, $(OBJS)))
TARGETS_O = $(addprefix $(BUILD)/, $(addsuffix .bin, $(TARGETS)))

.PHONY: all clean

all:	$(TARGETS_O) lint
ssd:	all
deploy:	all


lint::
	$(LINT) $(ASDEFS) $(foreach d,$(INCDIRS), -I $(d)) $(addsuffix .asm, $(OBJS))

$(BUILD)/%.o: 	%.asm $(DEPS) 
	$(AS) $(ASFLAGS) -g $(ASDEFS) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/%.bin: $(OBJS_O) %.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C $(filter %.cfg, $^) $(OBJS_O) $(LIBS)
	$(SCRIPTS)/getsymbols.pl $(ROMNO) <$(basename $@).sy2 >$(basename $@).noi
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)
	cp $(notdir $@).inf $(BUILD)


clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
	-rm $(patsubst %.bin, %.sy2, $(TARGETS_O))
	-rm $(patsubst %.bin, %.map, $(TARGETS_O))
	-rm $(patsubst %.bin, %.noi, $(TARGETS_O))
	-rm $(patsubst %.bin, %.dbg, $(TARGETS_O))
	-rm $(OBJS_O)
	-rm $(patsubst %.o, %.lst, $(OBJS_O))
	-rm $(patsubst %.o, %.lst.rel, $(OBJS_O))


