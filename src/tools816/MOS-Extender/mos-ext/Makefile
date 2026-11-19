		include ../../../Makefile.defs


AS=ca65
ASFLAGS=--cpu 65816 -I . -I $(INC)
LD=ld65
LDFLAGS=-vm

TARGETS=mos-ext.bin mos-ext.dis.asm
OBJS=main cop irq callmos osword osbyte emu_zp
DEPS_S=$(OSINCS) $(wildcard *.inc)

OBJS_B=$(addprefix $(BUILD)/, $(addsuffix .o, $(OBJS)))
TARGETS_B=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_B)
ssd:	all
deploy:	ssd

$(BUILD)/%.o: %.s $(DEPS_S)
	$(AS) $(ASFLAGS) -g -o $@ -l $(basename $@).lst $(filter %.s, $^)

$(BUILD)/mos-ext.bin $(BUILD)/mos-ext.sym: $(OBJS_B) mos-ext.cfg
	$(LD) $(LDFLAGS) -Ln $(basename $@).sy2 -m $(basename $@).map --dbgfile $(basename $@).dbg -o $@ $(filter %.o, $^) -C $(filter %.cfg, $^)
	$(SCRIPTS)/ld65map2noi.pl <$(basename $@).map >$(basename $@).sym
	$(SCRIPTS)/ca65lstupdate.pl $(basename $@).dbg $(BUILD)
	echo "$$.mos-ext 0001900 0001900" >$@.inf

$(BUILD)/mos-ext.dis.asm:$(BUILD)/mos-ext.bin $(BUILD)/mos-ext.sym
	/mnt/c/Users/domin/OneDrive/Documents/GitHub/DeIce68k/TestDisassArm/bin/Debug/net8.0/TestDisass.exe 65816 "$(shell wslpath -w ${BUILD}/mos-ext.bin)" 0x2000 "$(shell wslpath -w ${BUILD}/mos-ext.sym)" >$@

clean:
	-rm $(OBJS_B)
	-rm $(patsubst %.o, %.lst, $(OBJS_B))
	-rm $(patsubst %.o, %.lst.rel, $(OBJS_B))
	-rm $(patsubst %.o, %.lst, $(OBJS_B))
	-rm $(BUILD)/mos-ext.bin
	-rm $(BUILD)/mos-ext.bin.inf
	-rm $(BUILD)/mos-ext.map
	-rm $(BUILD)/mos-ext.dis.asm
	-rm $(BUILD)/mos-ext.sym
	-rm $(BUILD)/mos-ext.sy2
	-rm $(BUILD)/mos-ext.dbg

