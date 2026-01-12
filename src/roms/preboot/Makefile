		include ../../Makefile.defs

SSD=$(SSDS)/preboot-test.ssd
DEPLOY=$(DEPLOY_TOP)/preboot-test

SUBDIRS=preboot1-c20k preboot2-c20k
OBJS=preboot2-c20k/preboot2-c20k.rom
EXTRAS=$(wildcard extras/*.inf)

OBJS_O=$(addprefix $(BUILD)/, $(OBJS))

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

$(BUILD)/preboot2-c20k/preboot2-c20k.rom:
	$(MAKE) -C preboot2-c20k all

$(SSD):	$(OBJS_O) $(EXTRAS)
	dfs form -80 $(SSD)
	dfs title $(SSD) "pbtest"
	dfs add $(SSD) $(addsuffix .inf, $(OBJS_O)) $(EXTRAS)
