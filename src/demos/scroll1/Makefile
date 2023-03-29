	include ../../Makefile.defs


AS=ca65 -I $(INC) -I $(BLIT_LIB_INC)
LD=ld65

LIBS=$(BLIT_LIB)
DEPS=$(LIBS) $(OSINCS) $(BLIT_LIB_INCS)

TARGETS=test-real0 test-real1 test-real2 test-real3 test-real4 test-real5
TARGETS_O=$(addprefix $(BUILD)/, $(addsuffix .bin, $(TARGETS)))
LST_O=$(addprefix $(BUILD)/, $(addsuffix .lst, $(TARGETS)))
SY2_O=$(addprefix $(BUILD)/, $(addsuffix .sy2, $(TARGETS)))
MAP_O=$(addprefix $(BUILD)/, $(addsuffix .map, $(TARGETS)))
NOI_O=$(addprefix $(BUILD)/, $(addsuffix .noi, $(TARGETS)))
INF_O=$(addprefix $(BUILD)/, $(addsuffix .bin.inf, $(TARGETS)))

SSD=$(SSDS)/demo65.ssd

$(BUILD)/%.o: 	%.asm $(DEPS)
	$(AS) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/%.bin $(BUILD)/%.sy2 $(BUILD)/%.map: %.cfg $(BUILD)/%.o 
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map -o $@ -C $< $(filter %.o, $^) $(LIBS)
	$(SCRIPTS)/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	echo EDIT 700 $$(echo -n "$(MODNAME)" | hexdump -ve '1/1 "%X "') 0D 00 >$(basename $@).run.noi
	echo LOAD $$(cygpath -w "$$(realpath "$@")") 2000 B >>$(basename $@).run.noi
	cat $(basename $@).noi >>$(basename $@).run.noi
	echo EDIT zp_mos_txtptr %X16 700 >>$(basename $@).run.noi
	echo R Y 0 >>$(basename $@).run.noi
	echo R PC start_noice >>$(basename $@).run.noi
	echo U start >>$(basename $@).run.noi
	cp $(notdir $(basename $@)).bin.inf $(BUILD)


all:	$(TARGETS_O) 


ssd:	all $(SSD)

deploy: ssd
	mkdir -p $(DEPLOY_TOP)/demo65
	dfs read -i -d $(DEPLOY_TOP)/demo65 $(SSD)

$(SSD):	$(TARGETS_O) $(wildcard data/*)
	dfs form -80 $(SSD)
	dfs title $(SSD) "demo65"
	dfs add $(SSD) $(addsuffix .inf, $(TARGETS_O))
	dfs add $(SSD) data/*.inf
	dfs opt4 -3 $(SSD)


clean:
	-rm $(TARGETS_O)
	-rm $(LST_O)
	-rm $(SY2_O)
	-rm $(MAP_O)
	-rm $(INF_O)
	-rm $(NOI_O)
	-rm $(SSD)