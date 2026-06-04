	include ./Makefile.defs

SUBDIRSWIMAKE:=blitlib demos roms test tools65 examples

$(TOPTARGETS): $(SUBDIRSWIMAKE)

$(SUBDIRSWIMAKE): 
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY:		$(TOPTARGETS) $(SUBDIRSWIMAKE)
