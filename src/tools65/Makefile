

HOSTFSDIR=~/hostfs/tools65/
SSD=tools65.ssd

SUBDIRS=srnuke memtest flashtst turbo i2cdump rtcdump memsize
OBJS=srnuke/srnuke.bin memtest/memtest.bin flashtst/flashtst.bin turbo/turbo.bin i2cdump/i2cdump.bin rtcdump/rtcdump.bin memsize/memsize.bin
EXTRAS=$(basename $(wildcard extras/*.inf))

.DELETE_ON_ERROR:

.PHONY: all $(SUBDIRS)

all:: $(SUBDIRS) $(OBJS) $(SSD)
clean:: $(SUBDIRS)
	rm -f $(SSD)

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

srnuke/srnuke.bin:
	make -C srnuke all


$(SSD):	$(OBJS)
	dfs form -80 $(SSD)
	dfs title $(SSD) "tools65"
	dfs add $(SSD) $(addsuffix .inf, $(OBJS) $(EXTRAS))

	dfs add $(SSD) XMDump/XMDump.inf

	-mkdir -p $(HOSTFSDIR)

	dfs read -i -w "*.*" -d $(HOSTFSDIR) $(SSD)
