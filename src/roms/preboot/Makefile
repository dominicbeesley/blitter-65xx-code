		include ../../Makefile.defs

QUARTUS_SH=quartus_sh.exe
QUARTUS_MAP=quartus_map.exe
QUARTUS_FIT=quartus_fit.exe
QUARTUS_ASM=quartus_asm.exe
QUARTUS_PGM=quartus_pgm.exe
QUARTUS_CPF=quartus_cpf.exe

GOWIN_PROG=./goprog.sh

DEPLOY=$(DEPLOY_TOP)/preboot-test

SUBDIRS=preboot1 preboot2
EXTRAS=$(wildcard extras/*.inf)

OBJS_O=$(addprefix $(BUILD)/, $(OBJS))

.PHONY: FORCE clean all $(SUBDIRS) 

$(BUILD)/romset-c20k.bin: example-roms-list.romlst
	$(SCRIPTS)/makeromset.pl example-roms-list.romlst $@

FORCE: ;

$(BUILD)/preboot2/mk2/preboot2.bin $(BUILD)/preboot2/c20k/preboot2.bin: FORCE
	make -C preboot2 all


%.hex: %.bin
	srec_cat -Output $@ -Intel $< -Binary

$(BUILD)/preboot-mk2.jic: mk2_conv.cof $(BUILD)/romset-mk2.hex $(BUILD)/preboot2/mk2/preboot2.hex
	$(QUARTUS_CPF) -c mk2_conv.cof

$(BUILD)/romset-mk2.bin: example-roms-list-mk2.romlst FORCE
	$(SCRIPTS)/makeromset.pl example-roms-list-mk2.romlst $@



all: $(SUBDIRS) $(BUILD)/romset-c20k.bin $(BUILD)/preboot-mk2.jic

mk2-program: $(BUILD)/preboot-mk2.jic
	echo $(BUILD)/preboot-mk2.jic
	echo $(wslpath -w "$(BUILD)/preboot-mk2.jic")
	$(QUARTUS_PGM) --no_banner --mode=jtag -o "IP;$(shell wslpath -w "$(BUILD)/preboot-mk2.jic")"

c20k-program: $(BUILD)/romset-c20k.bin $(BUILD)/preboot2/c20k/preboot2.bin
#	openFPGALoader --verbose-level 2 --cable ft2232 --write-flash -o 0x300000 --bitstream $(BUILD)/preboot2/c20k/preboot2.bin
#	openFPGALoader --verbose-level 2 --cable ft2232 --write-flash -o 0x320000 --bitstream $(BUILD)/romset-c20k.bin

	$(GOWIN_PROG) --device GW2A-18C --location 8465 --channel 1 --run 39 --spiaddr 0x300000 --mcuFile $(shell wslpath -w "$(BUILD)/preboot2/c20k/preboot2.bin")
	$(GOWIN_PROG) --device GW2A-18C --location 8465 --channel 1 --run 39 --spiaddr 0x320000 --mcuFile $(shell wslpath -w "$(BUILD)/romset-c20k.bin")

clean: $(SUBDIRS)
	-rm $(BUILD)/romset-c20k.bin
	-rm $(BUILD)/preboot-mk2.jic
	-rm $(BUILD)/romset-mk2.bin
	-rm $(BUILD)/romset-mk2.hex 
	-rm $(BUILD)/preboot2/mk2/preboot2.hex

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)



