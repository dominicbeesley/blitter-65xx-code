		include ../../Makefile.defs
		
BASICTOOL=basictool

TARGETS=test1306.tok

TARGETS_O=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_O)
ssd: all
deploy: ssd

$(BUILD)/test1306.tok:test1306.bbc
	basictool -t $< $@
	echo '$$.TST1306 FFFF8023 FFFF8023' >$@.inf

clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
