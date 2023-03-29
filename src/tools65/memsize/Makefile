AS=ca65 -I ../../../includes
LD=ld65

%.o: 	%.asm $(DEPS) $(INCS)
	$(AS) -g -l $(basename $@).lst $<

%.bin %.sy2 %.map %.noi:	%.o %.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map -o $@ -C $(basename $@).cfg $< $(LIBS)
	../../../scripts/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi


all::	memsize.bin

clean::
	-rm memtest.bin memtest.sy2 memtest.map memtest.lst 2>/dev/nul