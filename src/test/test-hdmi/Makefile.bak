AS=ca65 -I ../../../../includes 
LD=ld65

TARG=0_copy_screen
OBJS=$(TARG).o
DEPS=

all::	$(TARG).bin


%.o: 	%.asm $(DEPS) $(INCS)
	$(AS) -o $@ -g -l $(basename $@).lst $<

$(TARG).bin: $(OBJS) $(TARG).cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map -o $@ -C $(basename $@).cfg $(OBJS) $(LIBS)
	../../../../scripts/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	cp $(TARG).bin* ~/hostfs/hdmitest

clean::
	-rm *.o
	-rm $(TARG).bin $(TARG).sy2 $(TARG).map $(TARG).lst 2>/dev/nul
