		include ../../Makefile.defs
		
BASICTOOL=basictool

TARGETS=ediddump.tok

TARGETS_O=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_O)
ssd: all
deploy: ssd

$(BUILD)/ediddump.tok:ediddump.bbc
	basictool -t $< $@
	echo '$$.edidump FFFF8023 FFFF8023' >$@.inf

clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
