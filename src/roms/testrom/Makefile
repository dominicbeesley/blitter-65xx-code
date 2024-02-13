		include ../../Makefile.defs

AS=ca65 -I $(TOP)/includes -I $(BUILD)
LD=ld65
INCS=$(wildcard $(TOP)/includes/*.inc) $(filter-out version-date.inc, $(wildcard *.inc))
DEPS=$(INCS) 
OBJS=	blttest bltutil_utils
ROMNO=A

TARGETS=blttest

OBJS_O = $(addprefix $(BUILD)/, $(addsuffix .o, $(OBJS)))
TARGETS_O = $(addprefix $(BUILD)/, $(addsuffix .rom, $(TARGETS)))

.PHONY: all clean

all:	$(TARGETS_O)
ssd:	all
deploy:	all

.PRECIOUS:build/*

$(BUILD)/version-date.inc: $(DEPS) $(filter-out %.da.asm, $(wildcard *.asm))
	$(SCRIPTS)/gendate.sh $@

$(BUILD)/blttest.o: $(BUILD)/version-date.inc

$(BUILD)/%.o: 	%.asm $(DEPS) 
	$(AS) -o $@ -g -l $(basename $@).lst $<

$(BUILD)/%.rom: $(OBJS_O) %.cfg
	$(LD) -vm -Ln $(basename $@).sy2 -m $(basename $@).map -o $@ -C $(filter %.cfg, $^) $(OBJS_O) $(LIBS)
	echo "$.BLTEST FF8000 FF8000" >$@.inf
	$(SCRIPTS)/getsymbols.pl $(ROMNO) <$(basename $@).sy2 >$(basename $@).noi


clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
	-rm $(patsubst %.rom, %.sy2, $(TARGETS_O))
	-rm $(patsubst %.rom, %.map, $(TARGETS_O))
	-rm $(patsubst %.rom, %.noi, $(TARGETS_O))
	-rm $(OBJS_O)
	-rm $(patsubst %.o, %.lst, $(OBJS_O))


