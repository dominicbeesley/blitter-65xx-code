AS=ca65 -I ../../../includes 
LD=ld65

OBJS=modmenu.o
DEPS=

all::	modmenu.bin


%.o: 	%.asm $(DEPS) $(INCS)
	$(AS) -o $@ -g -l $(basename $@).lst $<



modmenu.bin: $(OBJS) modmenu.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map -o $@ -C $(basename $@).cfg $(OBJS) $(LIBS)
	../../../scripts/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi


clean::
	-rm *.o
	-rm modmenu.bin modmenu.sy2 modmenu.map modmenu.lst 2>/dev/nul
