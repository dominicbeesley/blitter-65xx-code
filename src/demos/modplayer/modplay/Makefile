		include ../../../Makefile.defs

AS=ca65 -I $(TOP)/includes 
LD=ld65

OBJS=modplay modload
TARGETS=modplay
DEPS=modplay.inc helptext.mo7.txt


OBJS_O=$(addprefix $(BUILD)/, $(addsuffix .o, $(OBJS)))
TARGETS_O=$(addprefix $(BUILD)/, $(addsuffix .bin, $(TARGETS)))

all:	$(TARGETS_O)
deploy: all
ssd:	all


$(BUILD)/%.o: 	%.asm $(DEPS) $(INCS)
	$(AS) -o $@ -g -l $(basename $@).lst $<


$(BUILD)/%.bin: $(OBJS_O) %.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C $(filter %.cfg, $^) $(OBJS_O) 
	$(SCRIPTS)/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)
	cp $(notdir $@).inf $(BUILD)

##	echo EDIT 700 $$(echo -n "$(MODNAME)" | hexdump -ve '1/1 "%X "') 0D 00 >$(basename $@).run.noi
##	echo LOAD $$(cygpath -w "$$(realpath "$@")") 2000 B >>$(basename $@).run.noi
##	cat $(basename $@).noi >>$(basename $@).run.noi
##	echo EDIT zp_mos_txtptr %X16 700 >>$(basename $@).run.noi
##	echo R Y 0 >>$(basename $@).run.noi
##	echo R PC start_noice >>$(basename $@).run.noi
##	echo U start >>$(basename $@).run.noi





clean:
	-rm $(OBJS_O)
	-rm $(OBJS_O)
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
	-rm $(patsubst %.bin, %.sy2, $(TARGETS_O))
	-rm $(patsubst %.bin, %.map, $(TARGETS_O))
	-rm $(patsubst %.bin, %.noi, $(TARGETS_O))
	-rm $(patsubst %.o, %.lst, $(OBJS_O))
