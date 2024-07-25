		include ../../../Makefile.defs
		
BASICTOOL=basictool

TARGETS=1bppfont.tok

TARGETS_O=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_O)
ssd: all
deploy: ssd

$(BUILD)/1bppfont.tok:1bppfont.bas
	basictool -t $< $@
	echo '$$.1BPPFONT FFFF8023 FFFF8023' >$@.inf

clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
