	include ../Makefile.defs

TARGETS=blitlib.lib
OBJS=blit_lib blit_lib__rd_bloc_be blit_lib_copy blit_lib_ctl_full blit_lib_plot
DEPS=blit_int.inc blit_lib.inc $(OSINCS)

.PHONY:	all clean

OBJS_O=$(addprefix $(BUILD)/, $(addsuffix .o, $(OBJS)))
LST_O=$(addprefix $(BUILD)/, $(addsuffix .lst, $(OBJS)))
TARGETS_O=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_O)
clean: 
	-rm -f $(OBJS_O)
	-rm -f $(LST_O)
	-rm -f $(TARGETS_O)


$(BUILD)/blitlib.lib: $(OBJS_O)
	-rm -f $@
	$(AR) v r $@ $(OBJS_O)
	$(AR) v t $@

$(BUILD)/%.o: %.asm $(DEPS)
	$(AS) -o $@ -g $(addprefix -I , $(INC)) -l $(basename $@).lst $<
