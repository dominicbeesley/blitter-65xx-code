		include ../../../Makefile.defs

AS=ca65 -U -I $(TOP)/includes -I $(BUILD) -I ../includes
LD=ld65
CC=cl65 -I $(TOP)/includes -I $(BUILD) -I ../includes -O -t none --standard c99
INCS=$(wildcard $(TOP)/includes/*.inc) $(wildcard *.inc) $(wildcard ../includes *.inc)
DEPS=$(INCS)
A_OBJS=preboot2-c20k main_head spi crt0 
C_OBJS=main screen window
LIBS=none.lib

TARGETS=preboot2-c20k.vec

OBJS_O = $(addprefix $(BUILD)/, $(addsuffix .o, $(C_OBJS) $(A_OBJS)))
TARGETS_O = $(addprefix $(BUILD)/, $(TARGETS))

.PHONY: all clean

all:	$(TARGETS_O)
ssd:	all
deploy:	all

#dont know why I need this but otherwise gnu make deletes the .o files!
#.PRECIOUS: $(OBJS_O) $(BUILD)/
.SECONDARY:

$(BUILD)/%.vec:$(BUILD)/%.rom
	$(SCRIPTS)/bin2bitvector.pl $< >$@

%.o:%.c
$(BUILD)/%.o:%.c

$(BUILD)/%.s:	%.c
	$(CC) -S -o $@ -g $<

$(BUILD)/%.o: 	$(BUILD)/%.s $(DEPS) 
	$(AS) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/%.o: 	%.asm $(DEPS) 
	$(AS) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/%.o: 	../lib/%.asm $(DEPS) 
	$(AS) -o $@ -g -l $(basename $@).lst $<



$(BUILD)/main_head.o: main_head.mo7


$(BUILD)/%.rom: $(OBJS_O) preboot2-c20k.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C $(filter %.cfg, $^) $(OBJS_O) $(LIBS)
	$(SCRIPTS)/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)
	$(SCRIPTS)/ld65free.pl $(filter %.cfg, $^) $(basename $@).map >$(basename $@).free.txt
	cat $(basename $@).free.txt
	echo "M.PRBOOT2 FFC000 FFC000" >$@.inf

clean:
	-rm $(TARGETS_O)
	-rm $(patsubst %.vec, %.rom, $(TARGETS_O))
	-rm $(patsubst %.vec, %.rom.inf, $(TARGETS_O))
	-rm $(patsubst %.vec, %.sy2, $(TARGETS_O))
	-rm $(patsubst %.vec, %.map, $(TARGETS_O))
	-rm $(patsubst %.vec, %.noi, $(TARGETS_O))
	-rm $(patsubst %.vec, %.dbg, $(TARGETS_O))
	-rm $(OBJS_O)
	-rm $(patsubst %.o, %.lst, $(OBJS_O))
	-rm $(patsubst %.o, %.lst.rel, $(OBJS_O))
	-rm $(addprefix $(BUILD)/, $(addsuffix .s, $(C_OBJS)))


