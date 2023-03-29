	include ./Makefile.defs

#SUBDIRSWIMAKE:=$(shell for a in $$(find -mindepth 1 -type d); do if [ -e $$a/Makefile ]; then echo $$a; fi; done;)
SUBDIRSWIMAKE:=demos

$(TOPTARGETS): $(SUBDIRSWIMAKE)

$(SUBDIRSWIMAKE): 
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY:		$(TOPTARGETS) $(SUBDIRSWIMAKE)
