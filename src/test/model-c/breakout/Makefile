		include ../../../Makefile.defs
		
BASICTOOL=basictool

TARGETS=breakout.tok sprites_all.bin

TARGETS_O=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_O)
ssd: all
deploy: ssd

$(BUILD)/breakout.tok:breakout.bbc $(BUILD)/sprites_all.bbc
	cat $(BUILD)/sprites_all.bbc breakout.bbc >$(BUILD)/bastmp.bbc
	basictool -p -t $(BUILD)/bastmp.bbc $@
	echo '$$.BRKOUT FFFF8023 FFFF8023' >$@.inf

$(BUILD)/%.bin $(BUILD)/%.bbc:%.bspr
	../scripts/bsprcvt.py $< "S_" $(basename $@).bin $(basename $@).bbc

$(BUILD)/sprites_all.bbc: $(BUILD)/sprites.bbc $(BUILD)/balls.bbc
	cat $^ >$@

$(BUILD)/sprites_all.bin: $(BUILD)/sprites.bin $(BUILD)/balls.bin
	cat $(BUILD)/sprites.bin $(BUILD)/balls.bin > $(BUILD)/sprites_all.bin
	echo "S.BRKOUT FFFF3000 FFFF3000" >$(BUILD)/sprites_all.bin.inf

clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
	-rm $(BUILD)/bastmp.bbc
	-rm $(BUILD)/sprites.bbc
	-rm $(BUILD)/sprites.bin
	-rm $(BUILD)/balls.bbc
	-rm $(BUILD)/balls.bin
	-rm $(BUILD)/sprites_all.bbc