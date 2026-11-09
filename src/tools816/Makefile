		include ../Makefile.defs

SSD=$(SSDS)/tools816.ssd
DEPLOY=$(DEPLOY_TOP)/tools816

SUBDIRS=MOS-Extender
OBJS=MOS-Extender/test-app/test.bin MOS-Extender/mos-ext/mos-ext.bin
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

$(BUILD)/MOS-Extender/test-app/test.bin:
	make -C MOS-Extender all

$(SSD):	$(OBJS_O)
	dfs form -80 $(SSD)
	dfs title $(SSD) "tools816"
	dfs add $(SSD) $(addsuffix .inf, $(OBJS_O) $(EXTRAS))
