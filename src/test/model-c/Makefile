		include ../../Makefile.defs

SSD=$(SSDS)/model-c-test.ssd
DEPLOY=$(DEPLOY_TOP)/modelctest

SUBDIRS=ansi-text ansi-term sprites-test breakout siner vga-ilace
OBJS=ansi-text/ansi-text.bin ansi-term/ansi-term.bin sprites-test/sprtest.tok breakout/breakout.tok breakout/sprites_all.bin siner/siner.bin vga-ilace/VGA8I.F16
EXTRAS=$(basename $(wildcard extras/*.inf))

OBJS_O=$(addprefix $(BUILD)/, $(OBJS))

.DELETE_ON_ERROR:

.PHONY: clean all $(SUBDIRS)

all: $(SUBDIRS)
ssd: all $(SSD)

clean: $(SUBDIRS)
	-rm $(SSD)

deploy: ssd
	mkdir -p $(DEPLOY)
	dfs read -i -d $(DEPLOY) $(SSD)

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

$(BUILD)/ansi-text/ansi-test.bin:
	make -C ansi-text all
$(BUILD)/ansi-term/ansi-term.bin:
	make -C ansi-term all
$(BUILD)/sprites-test/sprtest.tok:
	make -C ansi-term all
$(BUILD)/breakout/breakout.tok $(BUILD)/breakout/sprites_all.bin:
	make -C ansi-term all

$(SSD):	$(OBJS_O) $(EXTRAS)
	dfs form -80 $(SSD)
	dfs title $(SSD) "modctest"
	dfs add $(SSD) $(addsuffix .inf, $(OBJS_O) $(EXTRAS))
