		include ../../../Makefile.defs
		
BASICTOOL=basictool

TARGETS=blit3.tok

TARGETS_O=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_O)
ssd: all
deploy: ssd

$(BUILD)/blit3.tok:blit3.bas
	basictool -t $< $@
	echo '$$.BLIT3 FFFF8023 FFFF8023' >$@.inf

clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
