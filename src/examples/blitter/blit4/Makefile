		include ../../../Makefile.defs
		
BASICTOOL=basictool

TARGETS=blit4.tok

TARGETS_O=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_O)
ssd: all
deploy: ssd

$(BUILD)/blit4.tok:blit4.bas
	basictool -t $< $@
	echo '$$.BLIT4 FFFF8023 FFFF8023' >$@.inf

clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
