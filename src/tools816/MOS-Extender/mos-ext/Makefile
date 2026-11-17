		include ../../../Makefile.defs


AS=ca65
ASFLAGS=--cpu 65816 -I . -I $(INC)
LD=ld65
LDFLAGS=-vm -C mos-ext.cfg

TARGETS=mos-ext.bin mos-ext.dis.asm
OBJS=main cop irq callmos osword
DEPS_S=$(OSINCS) $(wildcard *.inc)

OBJS_B=$(addprefix $(BUILD)/, $(addsuffix .o, $(OBJS)))
TARGETS_B=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_B)
ssd:	all
deploy:	ssd

$(BUILD)/%.o: %.s $(DEPS_S)
	$(AS) $(ASFLAGS) -o $@ $(filter %.s, $^)

$(BUILD)/mos-ext.bin $(BUILD)/mos-ext.sym: $(OBJS_B) mos-ext.cfg
	$(LD) $(LDFLAGS) -m $(basename $@).map -o $@ $(OBJS_B)
	$(SCRIPTS)/ld65map2noi.pl <$(basename $@).map >$(basename $@).sym
	echo "$$.mos-ext 0002000 0002000" >$@.inf

$(BUILD)/mos-ext.dis.asm:$(BUILD)/mos-ext.bin $(BUILD)/mos-ext.sym
	/mnt/c/Users/domin/OneDrive/Documents/GitHub/DeIce68k/TestDisassArm/bin/Debug/net8.0/TestDisass.exe 65816 "$(shell wslpath -w ${BUILD}/mos-ext.bin)" 0x2000 "$(shell wslpath -w ${BUILD}/mos-ext.sym)" >$@

clean:
	-rm $(OBJS_B)
	-rm $(TARGETS_B)
