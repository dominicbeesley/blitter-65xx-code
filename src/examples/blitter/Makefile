		include ../../Makefile.defs

SSD=$(SSDS)/examblit.ssd
DEPLOY=$(DEPLOY_TOP)/examblit

SUBDIRS=1bppfont 1bppfon2 1bppfon3 blit1 blit2 blit3 blit4
OBJS=	1bppfont/1bppfont.tok \
		1bppfon2/1bppfon2.tok \
		1bppfon3/1bppfon3.tok \
		blit1/blit1.tok \
		blit2/blit2.tok \
		blit3/blit3.tok \
		blit4/blit4.tok \
		ishsprites.bin
EXTRAS=$(basename $(wildcard extras/*.inf))

OBJS_O=$(addprefix $(BUILD)/, $(OBJS))

.DELETE_ON_ERROR:

.PHONY: clean all $(SUBDIRS)

all: $(SUBDIRS)
ssd: all $(SSD)

clean: $(SUBDIRS)
	-rm $(SSD)
	-rm $(BUILD)/ishsprites.bin

deploy: ssd
	mkdir -p $(DEPLOY)
	dfs read -i -d $(DEPLOY) $(SSD)

$(BUILD)/%.bin: %.bspr
	$(SCRIPTS)/beebspriter2blit.pl --symbols $@.inc --mask $< $@
	echo "S.ISHSPR 020000 020000" > $@.inf

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

$(BUILD)/1bppfont/1bppfont.tok:
	make -C 1bppfont all
$(BUILD)/1bppfon2/1bppfon2.tok:
	make -C 1bppfon2 all
$(BUILD)/1bppfon3/1bppfon3.tok:
	make -C 1bppfon3 all
$(BUILD)/blit1/blit1.tok:
	make -C blit1 all
$(BUILD)/blit2/blit2.tok:
	make -C blit2 all
$(BUILD)/blit3/blit3.tok:
	make -C blit2 all
$(BUILD)/blit4/blit4.tok:
	make -C blit2 all

$(SSD):	$(OBJS_O)
	dfs form -80 $(SSD)
	dfs title $(SSD) "examp blit"
	dfs add $(SSD) $(addsuffix .inf, $(OBJS_O) $(EXTRAS))

