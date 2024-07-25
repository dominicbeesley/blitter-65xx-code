		include ../../../Makefile.defs
		
BASICTOOL=basictool

TARGETS=1bppfon2.tok

TARGETS_O=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_O)
ssd: all
deploy: ssd

$(BUILD)/1bppfon2.tok:1bppfon2.bas
	basictool -t $< $@
	echo '$$.1BPPFO2 FFFF8023 FFFF8023' >$@.inf

clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
