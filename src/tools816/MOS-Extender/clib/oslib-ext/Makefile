		include ../../../../Makefile.defs

# liboslib.a - MOS-Extender OS call wrappers for vbcc 65816 C programs.
#
# One small source file per call (os_*.s, or *.c) so that vlink only pulls
# in the calls a program uses: vlink takes whole archive members, an
# object at a time. Shared code (e.g. retcheck) goes in its own file.
#
# Use from a program's Makefile:
#   CFLAGS  += -I<path to here>
#   LDFLAGS += -L$(BUILD_TOP)/<this dir's build dir>
#   link with: ... -loslib -lvc          (-loslib before -lvc)

export VBCC        = /home/domin/vbcc65816/vbcc65816_linux/vbcc
COMPILER_ROOT	=	${VBCC}/bin
export PATH     := ${COMPILER_ROOT}:$(PATH)

INCS=../../includes

CC=${COMPILER_ROOT}/vc
CFLAGS=-O3 +${VBCC}/config/dom-10000 -c99 -I${INCS} -I.
AS=${COMPILER_ROOT}/vasm6502_oldstyle
ASFLAGS= -816 -Fvobj -quiet -I${INCS}
# GNU ar: vlink reads its archives (checked 24 Nov 2026: test-app linked
# from liboslib.a is byte-identical to linking oslib.o directly)
AR=ar
ARFLAGS=rcs

LINT=$(SCRIPTS)/lint65816.py

SRCS_S=$(wildcard *.s)
SRCS_C=$(wildcard *.c)
OBJS_B=$(addprefix $(BUILD)/, $(SRCS_S:.s=.o) $(SRCS_C:.c=.o))

LIB=$(BUILD)/liboslibext.a

LINT_STAMP=$(BUILD)/lint.stamp
INC_DEPS=$(wildcard $(INCS)/*.inc)

all: $(LIB) $(LINT_STAMP)
ssd:	all
deploy:	all

$(LIB): $(OBJS_B)
	-rm -f $@
	$(AR) $(ARFLAGS) $@ $^

$(BUILD)/%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/%.o: %.s
	$(AS) $(ASFLAGS) -o $@ $<

$(LINT_STAMP): $(SRCS_S) $(INC_DEPS)
	$(LINT) -s vasm -I $(INCS) $(SRCS_S)
	touch $@

clean:
	-rm -f $(OBJS_B) $(LIB)
