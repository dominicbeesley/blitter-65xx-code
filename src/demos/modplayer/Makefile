		include ../../Makefile.defs

SSD=$(SSDS)/paula.ssd

PAULA_OBJS=modplay/modplay.bin modmenu/modmenu.bin
SUBDIRS=modplay modmenu

PAULA_OBJS_O=$(addprefix $(BUILD)/, $(PAULA_OBJS))

.PHONY: clean all $(SUBDIRS)

all: $(SUBDIRS)
	make -C modmenu all
	make -C modplay all

ssd: all $(SSD)

clean: $(SUBDIRS)
	-rm $(SSD)

deploy: ssd
	mkdir -p $(DEPLOY_TOP)/modplay
	dfs read -i -d $(DEPLOY_TOP)/modplay $(SSD)

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

$(BUILD)/modplay/modplay.bin:
	make -C modplay all

$(BUILD)/modmenu/modmenu.bin:
	make -C modmenu all


$(SSD):	$(PAULA_OBJS_O) $(wildcard paula_files/.*)
	dfs form -80 $(SSD)
	dfs title $(SSD) "1mpaula"
	dfs add $(SSD) $(addsuffix .inf, $(PAULA_OBJS_O))
	dfs add $(SSD) paula_files/*.inf
	dfs opt4 -3 $(SSD)
