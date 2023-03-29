

HOSTFSDIR=~/hostfs/roms65/
SSD=roms65.ssd

SUBDIRS=bltutil
OBJS=bltutil/build/bltutil.rom
EXTRAS=$(basename $(wildcard extras/*.inf))

DOCS=bltutil_readme.htm SoundQuickstart.htm

.PHONY: clean all $(SUBDIRS)

all:: $(SUBDIRS) $(SSD) $(DOCS)
clean:: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

$(SSD):	$(OBJS) $(EXTRAS)
	dfs form -80 $(SSD)
	dfs title $(SSD) "roms65"
	dfs add $(SSD) $(addsuffix .inf, $(OBJS) $(EXTRAS)) 
	-mkdir -p $(HOSTFSDIR)
	dfs read -i -w "*.*" -d $(HOSTFSDIR) $(SSD)

	cp $(OBJS) $$(cygpath -O)/BeebEm/BeebFile/BBC

%.htm: %.md
	perl ../../scripts/markdown/markdown.pl $< >$@