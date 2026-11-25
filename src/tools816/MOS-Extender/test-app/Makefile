		include ../../../Makefile.defs


# Make a test program
export VBCC        = /home/domin/vbcc65816/vbcc65816_linux/vbcc
COMPILER_ROOT	=	${VBCC}/bin
export PATH     := ${COMPILER_ROOT}:$(PATH)

INCS=../includes

CC=${COMPILER_ROOT}/vc
CFLAGS=-O3 +./dom-10000 -c99 -I${INCS}
LD=${COMPILER_ROOT}/vlink
LDFLAGS=-m -b rawbin1 -nowarn=22 -Cvbcc -T${VBCC}/targets/65816-dom/vlink.cmd -L${VBCC}/targets/65816-dom/lib
AS=${COMPILER_ROOT}/vasm6502_oldstyle
ASFLAGS= -816 -Fvobj -I${INCS}

OSLIBEXT_DIR=../clib/oslib-ext
OSLIBEXT_LIB:=$(abspath $(BUILD)/../clib/oslib-ext/liboslibext.a)

TARGETS=test.bin test.dis.asm
OBJS=test startup


OBJS_B=$(addprefix $(BUILD)/, $(addsuffix .o, $(OBJS)))
TARGETS_B=$(addprefix $(BUILD)/, $(TARGETS))

all: $(TARGETS_B)
ssd:	all
deploy:	ssd

.PHONY: FORCE
$(OSLIBEXT_LIB): FORCE
	$(MAKE) -C $(OSLIBEXT_DIR)

$(BUILD)/%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $^

$(BUILD)/%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $^	

$(BUILD)/test.bin $(BUILD)/test.sym: $(OBJS_B) $(OSLIBEXT_LIB)
	$(LD) $(LDFLAGS) -M$(basename $@).map -symfile $(basename $@).sym -symfmt "DEF %s %06llx" $(OBJS_B) $(OSLIBEXT_LIB) -o $@ -lvc 
	echo "$$.TEST 0010000 0010000" >$@.inf

$(BUILD)/test.dis.asm:$(BUILD)/test.bin $(BUILD)/test.sym
	/mnt/c/Users/domin/OneDrive/Documents/GitHub/DeIce68k/TestDisassArm/bin/Debug/net8.0/TestDisass.exe 65816 "$(shell wslpath -w ${BUILD}/test.bin)" 0x10000 "$(shell wslpath -w ${BUILD}/test.sym)" >$@

clean:
	-rm $(OBJS_B)
	-rm $(TARGETS_B)

