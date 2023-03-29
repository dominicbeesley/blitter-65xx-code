AS=ca65 -I ../../../includes
LD=ld65

%.o: 	%.asm $(DEPS) $(INCS)
	$(AS) -g -l $(basename $@).lst $<

%.bin %.sy2 %.map:	%.o %.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map -o $@ -C $(basename $@).cfg $< $(LIBS)


all::	srnuke.bin

clean::
	-rm srnuke.bin srnuke.sy2 srnuke.map srnuke.lst 2>/dev/nul