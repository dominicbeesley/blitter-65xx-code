

HOSTFSDIR=~/hostfs/demo65
PAULA_HOSTFSDIR=~/hostfs/paula_demo
SSD=demo65.ssd
PAULA_SSD=paula.ssd

SUBDIRS=modplay scroll1 modmenu
OBJS=modplay/modplay.bin scroll1/test-real0.bin scroll1/test-real1.bin scroll1/test-real2.bin scroll1/test-real3.bin scroll1/test-real4.bin scroll1/test-real5.bin
PAULA_OBJS=modplay/modplay.bin modmenu/modmenu.bin

.PHONY: all $(SUBDIRS)

all:: $(SUBDIRS) $(OBJS) $(PAULA_OBJS) $(SSD) $(PAULA_SSD)
clean:: $(SUBDIRS)
	-rm $(SSD)
	-rm $(PAULA_SSD)

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

modplay/modplay.bin:
	make -C modplay all


$(SSD):	$(OBJS)
	dfs form -80 $(SSD)
	dfs title $(SSD) "demo65"
	dfs add $(SSD) $(addsuffix .inf, $(OBJS))
	dfs add $(SSD) scroll1/data/*.inf
	dfs add $(SSD) files/*.inf
	dfs opt4 -3 $(SSD)

	-mkdir -p $(HOSTFSDIR)

	dfs read -i -w "*.*" -d $(HOSTFSDIR) $(SSD)

$(PAULA_SSD):	$(PAULA_OBJS) $(wildcard paula_files/.*)
	dfs form -80 $(PAULA_SSD)
	dfs title $(PAULA_SSD) "paula"
	dfs add $(PAULA_SSD) $(addsuffix .inf, $(PAULA_OBJS))
	dfs add $(PAULA_SSD) paula_files/*.inf
	dfs opt4 -3 $(PAULA_SSD)

	-mkdir -p $(PAULA_HOSTFSDIR)

	dfs read -i -w "*.*" -d $(PAULA_HOSTFSDIR) $(PAULA_SSD)
