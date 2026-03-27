		include ../Makefile.defs

SSD=$(SSDS)/blittest.ssd
DEPLOY=$(DEPLOY_TOP)/blittest

SUBDIRS=test-aeris test-hdmi test-line-plot test-spi
OBJS=test-aeris/test-aeris.bin test-hdmi/test-hdmi.bin test-line-plot/test-line.bin test-spi/test-spi.bbc

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

$(BUILD)/test-aeris/test-aeris.bin:
	make -C test-aeris all
$(BUILD)/test-hdmi/test-hdmi.bin:
	make -C test-hdmi all
$(BUILD)/test-line-plot/test-line.bin:
	make -C test-line-plot all
$(BUILD)/test-spi/test-spi.bbc:
	make -C test-spi all

$(SSD):	$(OBJS_O)
	dfs form -80 $(SSD)
	dfs title $(SSD) "blittest"
	dfs add $(SSD) $(addsuffix .inf, $(OBJS_O)) 

