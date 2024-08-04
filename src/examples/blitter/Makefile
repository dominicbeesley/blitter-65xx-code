		include ../../Makefile.defs

SSD=$(SSDS)/examblit.ssd
DEPLOY=$(DEPLOY_TOP)/examblit

OBJS=	1bppfo1.tok \
		1bppfo2.tok \
		1bppfo3.tok \
		blit1.tok \
		blit2.tok \
		blit3.tok \
		blit4.tok \
		ishsprites.bin 
EXTRAS=$(basename $(wildcard *.inf))

OBJS_O=$(addprefix $(BUILD)/, $(OBJS))

.DELETE_ON_ERROR:

.PHONY: clean all $(SUBDIRS)
.PRECIOUS: $(SSD)

all: $(OBJS_O)
ssd: all $(SSD)

clean: $(SUBDIRS)
	-rm $(OBJS_O)
	-rm $(SSD)
	-rm $(BUILD)/ishsprites.bin

deploy: ssd
	mkdir -p $(DEPLOY)
	dfs read -i -d $(DEPLOY) $(SSD)

$(BUILD)/%.bin: %.bspr
	$(SCRIPTS)/beebspriter2blit.pl --symbols $@.inc --mask $< $@
	echo "S.ISHSPR 020000 020000" > $@.inf


$(BUILD)/%.tok:%.bas
	basictool -2 -t $< $@
	printf "$$.%-7.7s FFFF8023 FFFF8023" $(notdir $(basename $@)) >$@.inf
	basictool $@ $@.bas
	sed -i -E 's/^\s*[0-9]+\s*//' $@.bas


$(SSD):	$(OBJS_O)
	dfs form -80 $(SSD)
	dfs title $(SSD) "examp blit"
	dfs add $(SSD) $(addsuffix .inf, $(OBJS_O) $(EXTRAS))


