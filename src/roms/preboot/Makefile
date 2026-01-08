		include ../../Makefile.defs

SSD=
DEPLOY=

SUBDIRS=preboot1-c20k
EXTRAS=

.PHONY: clean all $(SUBDIRS)

all: $(SUBDIRS)

clean: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)
