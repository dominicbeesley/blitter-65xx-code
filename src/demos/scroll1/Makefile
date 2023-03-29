INCS=
AS=ca65 -I ../../../includes -I ../../blitlib
LD=ld65

LIBS=../../blitlib/blitlib.lib
OBJS=
DEPS=$(LIBS) ../../../includes/hardware.inc ../../../includes/oslib.inc ../../../includes/mosrom.inc ../../blitlib/blit_lib.inc

TARGETS=test-real0 test-real1 test-real2 test-real3 test-real4 test-real5

%.o: 	%.asm $(DEPS)
	$(AS) -g -l $(basename $@).lst $<

%.bin %.sy2 %.map: %.o %.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map -o $@ -C $(basename $@).cfg $< $(OBJS) $(LIBS)
	../../../scripts/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	echo EDIT 700 $$(echo -n "$(MODNAME)" | hexdump -ve '1/1 "%X "') 0D 00 >$(basename $@).run.noi
	echo LOAD $$(cygpath -w "$$(realpath "$@")") 2000 B >>$(basename $@).run.noi
	cat $(basename $@).noi >>$(basename $@).run.noi
	echo EDIT zp_mos_txtptr %X16 700 >>$(basename $@).run.noi
	echo R Y 0 >>$(basename $@).run.noi
	echo R PC start_noice >>$(basename $@).run.noi
	echo U start >>$(basename $@).run.noi



all::	$(addsuffix .bin, $(TARGETS))

clean::
	-rm $(addsuffix .bin, $(TARGETS))	
	-rm $(addsuffix .sy2, $(TARGETS))	
	-rm $(addsuffix .map, $(TARGETS))	
	-rm $(addsuffix .lst, $(TARGETS))	
	-rm $(addsuffix .noi, $(TARGETS))	