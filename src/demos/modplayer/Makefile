		include ../../Makefile.defs

SSD=$(SSDS)/paula.ssd

PAULA_OBJS=modplay/modplay.bin modmenu/modmenu.bin
SUBDIRS=modplay modmenu

PAULA_OBJS_O=$(addprefix $(BUILD)/, $(PAULA_OBJS))

all: $(PAULA_OBJS_O)

ssd: $(SSD)

clean: 
	make -C modmenu clean
	make -C modplay clean
	-rm $(SSD)

deploy: $(SSD)
	mkdir -p $(DEPLOY_TOP)/modplay
	dfs read -i -d $(DEPLOY_TOP)/modplay $(SSD)

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
