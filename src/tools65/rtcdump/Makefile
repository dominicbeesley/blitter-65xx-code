AS=ca65 -I ../../../includes
LD=ld65

TARG=rtcdump

%.o: 	%.asm $(DEPS) $(INCS)
	$(AS) -g -l $(basename $@).lst $<

%.bin %.sy2 %.map %.noi:	%.o %.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map -o $@ -C $(basename $@).cfg $< $(LIBS)
	../../../scripts/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	echo LOAD `cygpath -a -w $@` 2000 B >$(basename $@).debug.noi
	cat $(basename $@).noi >> $(basename $@).debug.noi
	echo EDIT zp_mos_txtptr 00 07 >>$(basename $@).debug.noi
	echo EDIT 0700 `echo -n -e "W 10 1 2 3 4\r" | hexdump -e '1/1 "%x" " "'` >>$(basename $@).debug.noi
	echo reg PC ENTER_DEBUG >>$(basename $@).debug.noi


all::	$(TARG).bin

clean::
	-rm $(TARG).bin $(TARG).sy2 $(TARG).map $(TARG).lst 2>/dev/nul