		include ../../../Makefile.defs

AS=ca65 -U -I $(TOP)/includes -I $(BUILD) -I ../includes
LD=ld65
INCS=$(wildcard $(TOP)/includes/*.inc) $(wildcard *.inc) $(wildcard ../includes *.inc)
DEPS=$(INCS)
OBJS=preboot-run

TARGETS=preboot-run.bin

OBJS_O = $(addprefix $(BUILD)/, $(addsuffix .o, $(OBJS)))
TARGETS_O = $(addprefix $(BUILD)/, $(TARGETS))

.PHONY: all clean

all:	$(TARGETS_O)
ssd:	all
deploy:	all

#dont know why I need this but otherwise gnu make deletes the .o files!
.PRECIOUS: $(OBJS_O)

$(BUILD)/%.o: 	%.asm $(DEPS) 
	$(AS) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/%.o: 	../lib/%.asm $(DEPS) 
	$(AS) -o $@ -g -l $(basename $@).lst $<


$(BUILD)/%.bin: $(OBJS_O) preboot-run.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C $(filter %.cfg, $^) $(OBJS_O) $(LIBS)
	$(SCRIPTS)/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)
	$(SCRIPTS)/ld65free.pl $(filter %.cfg, $^) $(basename $@).map >$(basename $@).free.txt
	cat $(basename $@).free.txt
	echo "$.PBRUN FF2000 FF2000" >$@.inf


clean:
	-rm $(TARGETS_O)
	-rm $(patsubst %.bin, %.rom, $(TARGETS_O))
	-rm $(patsubst %.bin, %.sy2, $(TARGETS_O))
	-rm $(patsubst %.bin, %.map, $(TARGETS_O))
	-rm $(patsubst %.bin, %.noi, $(TARGETS_O))
	-rm $(patsubst %.bin, %.dbg, $(TARGETS_O))
	-rm $(OBJS_O)
	-rm $(patsubst %.o, %.lst, $(OBJS_O))
	-rm $(patsubst %.o, %.lst.rel, $(OBJS_O))


