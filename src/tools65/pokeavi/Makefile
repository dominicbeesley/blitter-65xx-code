		include ../../Makefile.defs
		
BASICTOOL=basictool

TARGETS=pokeavi.tok

TARGETS_O=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_O)
ssd: all
deploy: ssd

$(BUILD)/pokeavi.tok:pokeavi.bbc
	basictool -t $< $@
	echo '$$.POKEAVI FFFF8023 FFFF8023' >$@.inf

clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
