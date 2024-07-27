		include ../../../Makefile.defs
		
BASICTOOL=basictool

TARGETS=blit2.tok

TARGETS_O=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_O)
ssd: all
deploy: ssd

$(BUILD)/blit2.tok:blit2.bas
	basictool -t $< $@
	echo '$$.BLIT2 FFFF8023 FFFF8023' >$@.inf

clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
