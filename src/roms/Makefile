		include ../Makefile.defs

SSD=$(SSDS)/roms65.ssd
DEPLOY=$(DEPLOY_TOP)/roms65

SUBDIRS=bltutil testrom
OBJS=bltutil/bltutil.rom bltutil/bltutil.e.rom testrom/blttest.rom
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

$(BUILD)/bltutil/bltutil.rom $(BUILD)/bltutil/bltutil.e.rom &:
	$(MAKE) -C bltutil all

$(SSD):	$(OBJS_O) $(EXTRAS)
	dfs form -80 $(SSD)
	dfs title $(SSD) "roms65"
	dfs add $(SSD) $(addsuffix .inf, $(OBJS_O)) $(EXTRAS)

