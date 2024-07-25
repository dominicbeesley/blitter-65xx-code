		include ../../../Makefile.defs
		
BASICTOOL=basictool

TARGETS=1bppfon3.tok

TARGETS_O=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_O)
ssd: all
deploy: ssd

$(BUILD)/1bppfon3.tok:1bppfon3.bas
	basictool -t $< $@
	echo '$$.1BPPFO3 FFFF8023 FFFF8023' >$@.inf

clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
