		include ../../Makefile.defs

AS=ca65 -I $(TOP)/includes 
LD=ld65

SSD=$(SSDS)/nulatest.ssd
DEPLOY=$(DEPLOY_TOP)/nulatest


TARGETS=ATT1 PALTES1 PALTES2 PALTES3 SCRTES1 SCRTES2

DEPS=

TARGETS_O=$(addprefix $(BUILD)/, $(addsuffix .bbc, $(TARGETS)))

all:	$(TARGETS_O)

$(BUILD)/%.bbc: %.bas %.bbc.inf
	basictool -t $< $@
	cp $(notdir $@).inf $@.inf


ssd:	all
	dfs form -80 $(SSD)
	dfs title $(SSD) "nulatest"
	dfs add $(SSD) $(addsuffix .inf, $(TARGETS_O)) 

deploy:	ssd
	mkdir -p $(DEPLOY)
	dfs read -i -d $(DEPLOY) $(SSD)

clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
