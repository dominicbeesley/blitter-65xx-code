		include ../../Makefile.defs

SSD=$(SSDS)/model-c-test.ssd
DEPLOY=$(DEPLOY_TOP)/modelctest

SUBDIRS=ansi-text
OBJS=ansi-text/ansi-text.bin
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

$(SSD):	$(OBJS_O)
	dfs form -80 $(SSD)
	dfs title $(SSD) "modctest"
	dfs add $(SSD) $(addsuffix .inf, $(OBJS_O) $(EXTRAS))
