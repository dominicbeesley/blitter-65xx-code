		include ../../../Makefile.defs

AS=ca65 -U -I $(TOP)/includes -I $(BUILD)
LD=ld65
INCS=$(wildcard $(TOP)/includes/*.inc) $(wildcard *.inc)
DEPS=$(INCS)
OBJS=preboot1-c20k

TARGETS=preboot1-c20k.vec

OBJS_O = $(addprefix $(BUILD)/, $(addsuffix .o, $(OBJS)))
TARGETS_O = $(addprefix $(BUILD)/, $(TARGETS))

.PHONY: all clean

all:	$(TARGETS_O)
ssd:	all
deploy:	all

#dont know why I need this but otherwise gnu make deletes the .o files!
.PRECIOUS: $(OBJS_O)

$(BUILD)/%.vec:$(BUILD)/%.rom
	$(SCRIPTS)/bin2bitvector.pl $< >$@

$(BUILD)/%.o: 	%.asm $(DEPS) 
	$(AS) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/%.rom: $(OBJS_O) preboot1-c20k.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C $(filter %.cfg, $^) $(OBJS_O) $(LIBS)
	$(SCRIPTS)/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)
	$(SCRIPTS)/ld65free.pl $(filter %.cfg, $^) $(basename $@).map >$(basename $@).free.txt
	cat $(basename $@).free.txt

clean:
	-rm $(TARGETS_O)
	-rm $(patsubst %.vec, %.rom, $(TARGETS_O))
	-rm $(patsubst %.vec, %.sy2, $(TARGETS_O))
	-rm $(patsubst %.vec, %.map, $(TARGETS_O))
	-rm $(patsubst %.vec, %.noi, $(TARGETS_O))
	-rm $(patsubst %.vec, %.dbg, $(TARGETS_O))
	-rm $(OBJS_O)
	-rm $(patsubst %.o, %.lst, $(OBJS_O))
	-rm $(patsubst %.o, %.lst.rel, $(OBJS_O))


