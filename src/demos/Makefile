	include ../Makefile.defs

SUBDIRSWIMAKE:=scroll1 adventure bigfonts copper mode640_400 modplayer



$(TOPTARGETS): $(SUBDIRSWIMAKE)

$(SUBDIRSWIMAKE): 
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY:		$(TOPTARGETS) $(SUBDIRSWIMAKE)


