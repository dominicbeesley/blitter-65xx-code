AS=ca65 -I ../../../includes -I ../../blitlib
LD=ld65

MODNAME="axel_f.mod"
OBJS=modplay.o modload.o
DEPS=modplay.inc helptext.mo7.txt

all::	modplay.bin


%.o: 	%.asm $(DEPS) $(INCS)
	$(AS) -o $@ -g -l $(basename $@).lst $<

%1m.o: 	%.asm $(DEPS) $(INCS)
	$(AS) -o $@ -D HOG1M=1 -g -l $(basename $@).lst $<


modplay.bin: $(OBJS) modplay.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map -o $@ -C $(basename $@).cfg $(OBJS) $(LIBS)
	../../../scripts/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	../../../scripts/bemsymbols.pl $(ROMNO) <$(basename $@).sy2 >$(basename $@).bem

	echo EDIT 700 $$(echo -n "$(MODNAME)" | hexdump -ve '1/1 "%X "') 0D 00 >$(basename $@).run.noi
	echo LOAD $$(cygpath -w "$$(realpath "$@")") 2000 B >>$(basename $@).run.noi
	cat $(basename $@).noi >>$(basename $@).run.noi
	echo EDIT zp_mos_txtptr %X16 700 >>$(basename $@).run.noi
	echo R Y 0 >>$(basename $@).run.noi
	echo R PC start_noice >>$(basename $@).run.noi
	echo U start >>$(basename $@).run.noi





clean::
	-rm *.o
	-rm modplay.bin modplay.sy2 modplay.map modplay.lst 2>/dev/nul
