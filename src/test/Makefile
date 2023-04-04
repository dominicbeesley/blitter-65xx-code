		include ../Makefile.defs

SSD=$(SSDS)/blittest.ssd
DEPLOY=$(DEPLOY_TOP)/blittest

SUBDIRS=test-aeris test-hdmi test-line-plot
OBJS=test-aeris/test-aeris.bin test-hdmi/test-hdmi.bin test-line-plot/test-line.bin

OBJS_O=$(addprefix $(BUILD)/, $(OBJS))


.PHONY: clean all $(SUBDIRS)

all: $(SUBDIRS)
ssd: all $(SSD)

clean: $(SUBDIRS)
	-rm $(SSD)

deploy: $(SSD)
	mkdir -p $(DEPLOY)
	dfs read -i -d $(DEPLOY) $(SSD)

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

$(BUILD)/test-aeris/test-aeris.bin:
	make -C test-aeris all
$(BUILD)/test-hdmi/test-hdmi.bin:
	make -C test-hdmi all
$(BUILD)/test-line-plot/test-line.bin:
	make -C test-line-plot all

$(SSD):	$(OBJS_O)
	dfs form -80 $(SSD)
	dfs title $(SSD) "roms65"
	dfs add $(SSD) $(addsuffix .inf, $(OBJS_O)) 

