		include ../../../Makefile.defs

AS=ca65 -U -I $(TOP)/includes -I $(BUILD) -I ../includes
LD=ld65
CC=cl65 -I $(TOP)/includes -I $(BUILD) -I ../includes -O -t none --standard c99
INCS=$(wildcard $(TOP)/includes/*.inc) $(wildcard *.inc) $(wildcard ../includes *.inc)
HS=$(wildcard $(TOP)/includes/*.h) $(wildcard *.h) $(wildcard ../includes *.h)
DEPS=$(INCS) $(HS)

A_OBJS=	preboot2 main_head spi crt0 screen_int surface_int keyboard_int \
		hw_int sound_int app_reboot_int layout_int
C_OBJS=	main screen window surface listbox hex hw keyboard util debug doprnt \
		buffer coords romset ui app_romset app_main_menu app_reboot \
		sound app_clear_bb layout overlay preboot_saves app_romset_list 
LIBS=none.lib

TARGETS=preboot2.bin

OBJS_C20K_O = $(addprefix $(BUILD)/c20k/, $(addsuffix .o, $(C_OBJS) $(A_OBJS)))
TARGETS_C20K_O = $(addprefix $(BUILD)/c20k/, $(TARGETS))
DEFS_C20K = -D PREBOOT_BASE=0x300000 -D C20K

OBJS_MK2_O = $(addprefix $(BUILD)/mk2/, $(addsuffix .o, $(C_OBJS) $(A_OBJS)))
TARGETS_MK2_O = $(addprefix $(BUILD)/mk2/, $(TARGETS))
DEFS_MK2 = -D PREBOOT_BASE=0x180000 -D MK2

TARGETS_O = $(TARGETS_C20K_O) $(TARGETS_MK2_O)
OBJS_O = $(OBJS_C20K_O) $(OBJS_MK2_O)

X:=$(shell mkdir -p $(BUILD)/mk2)
X:=$(shell mkdir -p $(BUILD)/c20k)

.PHONY: all clean

.DELETE_ON_ERROR:

all:	$(TARGETS_O)
ssd:	all
deploy:	all

#dont know why I need this but otherwise gnu make deletes the .o files!
#.PRECIOUS: $(OBJS_O) $(BUILD)/
.SECONDARY:


$(BUILD)/c20k/%.s:	%.c $(DEPS)
	$(CC) $(DEFS_C20K) -S -o $@ -g $<

$(BUILD)/mk2/%.s:	%.c $(DEPS)
	$(CC) $(DEFS_MK2) -S -o $@ -g $<


$(BUILD)/c20k/%.o: 	$(BUILD)/c20k/%.s $(DEPS) 
	$(AS) $(DEFS_C20K) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/mk2/%.o: 	$(BUILD)/mk2/%.s $(DEPS) 
	$(AS) $(DEFS_MK2) -o $@ -g -l $(basename $@).lst $<


$(BUILD)/c20k/%.o: 	%.asm $(DEPS) 
	$(AS) $(DEFS_C20K) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/mk2/%.o: 	%.asm $(DEPS) 
	$(AS) $(DEFS_MK2) -o $@ -g -l $(basename $@).lst $<


$(BUILD)/c20k/main_head.o: main_head.mo7

$(BUILD)/mk2/main_head.o: main_head.mo7

$(BUILD)/c20k/preboot2.bin: $(OBJS_C20K_O) preboot2.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C $(filter %.cfg, $^) $(filter %.o, $^) $(LIBS)
	$(SCRIPTS)/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)/c20k/
	$(SCRIPTS)/ld65free.pl $(filter %.cfg, $^) $(basename $@).map >$(basename $@).free.txt
	da65 -v -S 0xC000 -o $@.da.S $@
	cat $(basename $@).free.txt
	echo "M.C2BOOT2 FFC000 FFC000" >$@.inf
	./genck.pl $@

$(BUILD)/mk2/preboot2.bin: $(OBJS_MK2_O) preboot2.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ -C $(filter %.cfg, $^) $(filter %.o, $^) $(LIBS)
	$(SCRIPTS)/getsymbols.pl <$(basename $@).sy2 >$(basename $@).noi
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)/mk2/
	$(SCRIPTS)/ld65free.pl $(filter %.cfg, $^) $(basename $@).map >$(basename $@).free.txt
	da65 -v -S 0xC000 -o $@.da.S $@
	cat $(basename $@).free.txt
	echo "M.M2BOOT2 FFC000 FFC000" >$@.inf
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
	-rm $(addprefix $(BUILD)/c20k/, $(addsuffix .s, $(C_OBJS)))
	-rm $(addprefix $(BUILD)/mk2/, $(addsuffix .s, $(C_OBJS)))


