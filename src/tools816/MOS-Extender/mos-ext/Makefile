		include ../../../Makefile.defs


export VBCC        = /home/domin/vbcc65816/vbcc65816_linux/vbcc
COMPILER_ROOT	=	${VBCC}/bin
export PATH     := ${COMPILER_ROOT}:$(PATH)

INCS=../includes

CC=${COMPILER_ROOT}/vc
CFLAGS=-O3 +./dom-10000 -c99 -I${INCS}
LD=${COMPILER_ROOT}/vlink
LDFLAGS=-m -Mmapfile -b rawbin1 -nowarn=22 -Cvbcc -T./vlink.cmd 
AS=${COMPILER_ROOT}/vasm6502_oldstyle
ASFLAGS= -816 -Fvobj -I${INCS}

TARGETS=mos-ext.bin mos-ext.dis.asm
OBJS=main


OBJS_B=$(addprefix $(BUILD)/, $(addsuffix .o, $(OBJS)))
TARGETS_B=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_B)
ssd:	all
deploy:	ssd

$(BUILD)/%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $^

$(BUILD)/%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $^	

$(BUILD)/mos-ext.bin $(BUILD)/mos-ext.sym: $(OBJS_B)
	$(LD) $(LDFLAGS) -symfile $(basename $@).sym -symfmt "DEF %s %06llx"  $(OBJS_B) -o $@
	echo "$$.mos-ext 0002000 0002000" >$@.inf

$(BUILD)/mos-ext.dis.asm:$(BUILD)/mos-ext.bin $(BUILD)/mos-ext.sym
	/mnt/c/Users/domin/OneDrive/Documents/GitHub/DeIce68k/TestDisassArm/bin/Debug/net8.0/TestDisass.exe 65816 "$(shell wslpath -w ${BUILD}/mos-ext.bin)" 0x2000 "$(shell wslpath -w ${BUILD}/mos-ext.sym)" >$@

clean:
	-rm $(OBJS_B)
	-rm $(TARGETS_B)

