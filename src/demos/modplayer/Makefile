		include ../../Makefile.defs

SSD=$(SSDS)/paula.ssd

PAULA_OBJS=modplay/modplay.bin modmenu/modmenu.bin
SUBDIRS=modplay modmenu

all: $(PAULA_OBJS) $(SSD)


clean: 
	make -C modmenu clean
	make -C modplay clean
	-rm $(SSD)

deploy: $(SSD)
	mkdir -p $(DEPLOY_TOP)/modplay
	dfs read -i -d $(DEPLOY_TOP)/modplay $(SSD)

modplay/modplay.bin:
	make -C modplay all

modmenu/modmenu.bin:
	make -C modmenu all


$(SSD):	$(PAULA_OBJS) $(wildcard paula_files/.*)
	dfs form -80 $(SSD)
	dfs title $(SSD) "1mpaula"
	dfs add $(SSD) $(addprefix $(BUILD)/, $(addsuffix .inf, $(PAULA_OBJS)))
	dfs add $(SSD) paula_files/*.inf
