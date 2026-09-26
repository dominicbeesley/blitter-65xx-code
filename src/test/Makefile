		include ../Makefile.defs

SSD=$(SSDS)/blittest.ssd
NULA_SSD=$(SSDS)/nulatest.ssd
DEPLOY=$(DEPLOY_TOP)/blittest
NULA_DEPLOY=$(DEPLOY_TOP)/nulatest

SUBDIRS=test-aeris test-hdmi test-line-plot test-spi adc-timings test-dma-data nula-tests
OBJS=test-aeris/test-aeris.bin test-hdmi/test-hdmi.bin test-line-plot/test-line.bin test-spi/test-spi.bbc adc-timings/adc-timings.bbc test-dma-data/test-dma-data.bin

OBJS_O=$(addprefix $(BUILD)/, $(OBJS))


.PHONY: clean all $(SUBDIRS)

all: $(SUBDIRS)
ssd: all $(SSD) $(NULA_SSD)

clean: $(SUBDIRS)
	-rm $(SSD)

deploy: ssd
	mkdir -p $(DEPLOY)
	dfs read -i -d $(DEPLOY) $(SSD)
	mkdir -p $(NULA_DEPLOY)
	dfs read -i -d $(NULA_DEPLOY) $(NULA_SSD)

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

$(BUILD)/test-aeris/test-aeris.bin:
	make -C test-aeris all
$(BUILD)/test-hdmi/test-hdmi.bin:
	make -C test-hdmi all
$(BUILD)/test-dma-data/test-dma-data.bin:
	make -C test-dma-data all
$(BUILD)/test-line-plot/test-line.bin:
	make -C test-line-plot all
$(BUILD)/test-spi/test-spi.bbc:
	make -C test-spi all
$(BUILD)/adc-timings/adc-timings.bbc:
	make -C adc-timings all
$(BUILD)/adc-timings/adc-timings.bbc:
	make -C adc-timings all

$(NULA_SSD): 
	make -C nula-tests ssd

$(SSD):	$(OBJS_O)
	dfs form -80 $(SSD)
	dfs title $(SSD) "blittest"
	dfs add $(SSD) $(addsuffix .inf, $(OBJS_O)) 

