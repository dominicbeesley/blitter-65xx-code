		include ../../Makefile.defs

SSD=$(SSDS)/blbutil-test.ssd
DEPLOY=$(DEPLOY_TOP)/bltutil-test

OBJS=	HEAPFIT.tok 
EXTRAS=$(basename $(wildcard *.inf))

OBJS_O=$(addprefix $(BUILD)/, $(OBJS))

.DELETE_ON_ERROR:

.PHONY: clean all $(SUBDIRS)
.PRECIOUS: $(SSD)

all: $(OBJS_O)
ssd: all $(SSD)

clean: $(SUBDIRS)
	-rm $(OBJS_O)
	-rm $(addprefix .inf, $(OBJS_O))
	-rm $(SSD)

deploy: ssd
	mkdir -p $(DEPLOY)
	dfs read -i -d $(DEPLOY) $(SSD)

$(BUILD)/%.tok $(BUILD)/%.inf:%.bas
	basictool -2 -t $< $@
	printf "$$.%-7.7s FFFF8023 FFFF8023" $(notdir $(basename $@)) >$@.inf
	basictool $@ $@.bas
	sed -i -E 's/^\s*[0-9]+\s*//' $@.bas


$(SSD):	$(OBJS_O)
	dfs form -80 $(SSD)
	dfs title $(SSD) "examp blit"
	dfs add $(SSD) $(addsuffix .inf, $(OBJS_O) $(EXTRAS))


