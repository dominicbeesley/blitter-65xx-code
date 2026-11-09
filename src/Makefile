	include ./Makefile.defs

SUBDIRSWIMAKE:=blitlib demos roms test tools65 examples tools816

$(TOPTARGETS): $(SUBDIRSWIMAKE)

$(SUBDIRSWIMAKE): 
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY:		$(TOPTARGETS) $(SUBDIRSWIMAKE)
