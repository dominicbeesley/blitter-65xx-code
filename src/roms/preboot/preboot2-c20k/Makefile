		include ../../../Makefile.defs

AS=ca65 -U -I $(TOP)/includes -I $(BUILD) -I ../includes
LD=ld65
CC=cl65 -I $(TOP)/includes -I $(BUILD) -I ../includes -O -t none --standard c99
INCS=$(wildcard $(TOP)/includes/*.inc) $(wildcard *.inc) $(wildcard ../includes *.inc)
HS=$(wildcard $(TOP)/includes/*.h) $(wildcard *.h) $(wildcard ../includes *.h)
DEPS=$(INCS) $(HS)
A_OBJS=	preboot2-c20k main_head spi crt0 screen_int surface_int keyboard_int \
		hw_int sound_int app_reboot_int
C_OBJS=	main screen window surface listbox hex hw keyboard util debug doprnt \
		buffer coords romset ui app_romset app_main_menu strings app_reboot \
		app_romset_list sound
LIBS=none.lib

TARGETS=preboot2-c20k.bin

OBJS_O = $(addprefix $(BUILD)/, $(addsuffix .o, $(C_OBJS) $(A_OBJS)))
TARGETS_O = $(addprefix $(BUILD)/, $(TARGETS))

.PHONY: all clean

.DELETE_ON_ERROR:

all:	$(TARGETS_O)
ssd:	all
deploy:	all

#dont know why I need this but otherwise gnu make deletes the .o files!
#.PRECIOUS: $(OBJS_O) $(BUILD)/
.SECONDARY:

%.o:%.c
$(BUILD)/%.o:%.c

$(BUILD)/%.s:	%.c $(DEPS)
	$(CC) -S -o $@ -g $<

$(BUILD)/%.o: 	$(BUILD)/%.s $(DEPS) 
	$(AS) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/%.o: 	%.asm $(DEPS) 
	$(AS) -o $@ -g -l $(basename $@).lst $<



$(BUILD)/main_head.o: main_head.mo7


$(BUILD)/%.bin: $(OBJS_O) preboot2-c20k.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C $(filter %.cfg, $^) $(OBJS_O) $(LIBS)
	$(SCRIPTS)/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)
	$(SCRIPTS)/ld65free.pl $(filter %.cfg, $^) $(basename $@).map >$(basename $@).free.txt
	da65 -v -S 0xC000 -o $@.da.S $@
	cat $(basename $@).free.txt
	echo "M.PRBOOT2 FFC000 FFC000" >$@.inf
	./genck.pl $@


clean:
	-rm $(TARGETS_O)
	-rm $(patsubst %.bin, %.bin.inf, $(TARGETS_O))
	-rm $(patsubst %.bin, %.sy2, $(TARGETS_O))
	-rm $(patsubst %.bin, %.map, $(TARGETS_O))
	-rm $(patsubst %.bin, %.noi, $(TARGETS_O))
	-rm $(patsubst %.bin, %.dbg, $(TARGETS_O))
	-rm $(OBJS_O)
	-rm $(patsubst %.o, %.lst, $(OBJS_O))
	-rm $(patsubst %.o, %.lst.rel, $(OBJS_O))
	-rm $(addprefix $(BUILD)/, $(addsuffix .s, $(C_OBJS)))


