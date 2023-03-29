AS=ca65 -I ../../../includes 
LD=ld65

OBJS=test-aeris.o
DEPS=

all::	test-aeris.bin


%.o: 	%.asm $(DEPS) $(INCS)
	$(AS) -o $@ -g -l $(basename $@).lst $<

test-aeris.bin: $(OBJS) test-aeris.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map -o $@ -C $(basename $@).cfg $(OBJS) $(LIBS)
	../../../scripts/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	cp test-aeris.bin* ~/hostfs/0.TEST

clean::
	-rm *.o
	-rm test-aeris.bin test-aeris.sy2 test-aeris.map test-aeris.lst 2>/dev/nul
