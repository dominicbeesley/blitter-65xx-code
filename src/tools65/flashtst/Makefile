AS=ca65 -I ../../../includes
LD=ld65

%.o: 	%.asm $(DEPS) $(INCS)
	$(AS) -g -l $(basename $@).lst $<

%.bin %.sy2 %.map:	%.o %.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map -o $@ -C $(basename $@).cfg $< $(LIBS)


all::	flashtst.bin

clean::
	-rm flashtst.bin flashtst.sy2 flashtst.map flashtst.lst 2>/dev/nul