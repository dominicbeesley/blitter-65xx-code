		include ../../../Makefile.defs
		
BASICTOOL=basictool

TARGETS=blit1.tok

TARGETS_O=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_O)
ssd: all
deploy: ssd

$(BUILD)/blit1.tok:blit1.bas
	basictool -t $< $@
	echo '$$.BLIT1 FFFF8023 FFFF8023' >$@.inf

clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
