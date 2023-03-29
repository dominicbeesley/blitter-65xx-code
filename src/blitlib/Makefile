AS=ca65
LD=ld65
AR=ar65

TARGETS=blitlib.lib
INCDIRS=../../includes .
OBJS=blit_lib.o blit_lib__rd_bloc_be.o blit_lib_copy.o blit_lib_ctl_full.o blit_lib_plot.o
DEPS=blit_int.inc blit_lib.inc ../../includes/hardware.inc

.PHONY:	all clean

all:: $(TARGETS)
clean:: 
	-rm -f $(TARGETS)
	-rm -f $(OBJS)
	-rm -f *.lst

blitlib.lib: $(OBJS)
		echo $(OBJS)
		-rm -f $@
		$(AR) v r $@ $(OBJS)
		$(AR) v t $@

%.o:		%.asm $(DEPS)
		$(AS) -o $@ -g $(addprefix -I , $(INCDIRS)) -l $(basename $@).lst $<
