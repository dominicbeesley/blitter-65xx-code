	include ../Makefile.defs

SUBDIRSWIMAKE:=scroll1 adventure bigfonts copper modplayer
# mode640_400 - removed



$(TOPTARGETS): $(SUBDIRSWIMAKE)

$(SUBDIRSWIMAKE): 
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY:		$(TOPTARGETS) $(SUBDIRSWIMAKE)


