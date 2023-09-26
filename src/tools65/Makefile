		include ../Makefile.defs

SSD=$(SSDS)/tools65.ssd
DEPLOY=$(DEPLOY_TOP)/tools65

SUBDIRS=srnuke memtest flashtst turbo i2cdump rtcdump memsize ssd1306 pokeavi ediddump
OBJS=srnuke/srnuke.bin memtest/memtest.bin flashtst/flashtst.bin turbo/turbo.bin i2cdump/i2cdump.bin rtcdump/rtcdump.bin memsize/memsize.bin ssd1306/test1306.tok pokeavi/pokeavi.tok ediddump/ediddump.tok
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

$(BUILD)/srnuke/srnuke.bin:
	make -C srnuke all
$(BUILD)/memtest/memtest.bin:
	make -C memtest all
$(BUILD)/flashtst/flashtst.bin:
	make -C flashtst all
$(BUILD)/turbo/turbo.bin:
	make -C turbo all
$(BUILD)/i2cdump/i2cdump.bin:
	make -C i2cdump all
$(BUILD)/rtcdump/rtcdump.bin:
	make -C rtcdump all
$(BUILD)/memsize/memsize.bin:
		make -C memsize all
$(BUILD)/ssd1306/test1306.tok:
		make -C ssd1306 all
$(BUILD)/pokeavi/pokeavi.tok:
		make -C pokeavi all
$(BUILD)/ediddump/ediddump.tok:
		make -C ediddump all

$(SSD):	$(OBJS_O)
	dfs form -80 $(SSD)
	dfs title $(SSD) "tools65"
	dfs add $(SSD) $(addsuffix .inf, $(OBJS_O) $(EXTRAS))
