		include ../../Makefile.defs

SUBDIRS=test-app mos-ext

.DELETE_ON_ERROR:

.PHONY: clean all $(SUBDIRS)

all: $(SUBDIRS)
ssd:	all
deploy:	ssd
clean: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)
