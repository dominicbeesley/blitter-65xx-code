		include ../../Makefile.defs

SSD=$(SSDS)/examblit.ssd
DEPLOY=$(DEPLOY_TOP)/examblit

SUBDIRS=1bppfont
OBJS=1bppfont/1bppfont.tok
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

$(BUILD)/1bppfont/1bppfont.tok:
	make -C 1bppfont all

$(SSD):	$(OBJS_O)
	dfs form -80 $(SSD)
	dfs title $(SSD) "examp blit"
	dfs add $(SSD) $(addsuffix .inf, $(OBJS_O) $(EXTRAS))
