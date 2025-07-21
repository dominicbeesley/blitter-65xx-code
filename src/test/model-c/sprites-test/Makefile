		include ../../../Makefile.defs
		
BASICTOOL=basictool

TARGETS=sprtest.tok

TARGETS_O=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_O)
ssd: all
deploy: ssd

$(BUILD)/sprtest.tok:sprtest.bbc
	basictool -t $< $@
	echo '$$.SPRTEST FFFF8023 FFFF8023' >$@.inf

clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
