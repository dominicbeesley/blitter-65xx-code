AS=ca65 -I ../../../includes 
LD=ld65

OBJS=test-line.o
DEPS=
INCS=$(wildcard ../../../includes/*.inc)

all::	test-line.bin


%.o: 	%.asm $(DEPS) $(INCS)
	$(AS) -o $@ -g -l $(basename $@).lst $<

test-line.bin: $(OBJS) test-line.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map -o $@ -C $(basename $@).cfg $(OBJS) $(LIBS)
	../../../scripts/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	echo LOAD `cygpath -a -w "test-line.bin"` 2000 B >$(basename $@).game.noi
	cat $(basename $@).noi >> $(basename $@).game.noi
	echo reg PC 2000 >>$(basename $@).game.noi
	cp test-line.bin* ~/hostfs/0.TEST

clean::
	-rm *.o
	-rm test-line.bin test-line.sy2 test-line.map test-line.lst test-line.noi test-line.game.noi 2>/dev/nul
