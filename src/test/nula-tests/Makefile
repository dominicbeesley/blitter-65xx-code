		include ../../Makefile.defs

AS=ca65 -I $(TOP)/includes 
LD=ld65

SSD=$(SSDS)/nulatest.ssd
DEPLOY=$(DEPLOY_TOP)/nulatest


#BBC BASIC
TARGETS_BBC=ATT1 ATT2 ATT3 ATT3L \
			PALTES1 PALTES2 PALTES3 PALTES1L PALTES2L PALTES3L \
			SCRTES1 SCRTES2 \
			SPECPICS THOMSON \
			256PIC
#SPECCY SCREENS
TARGETS_Z=$(basename $(wildcard *.mlt))

TARGETS=$(addsuffix .bbc, $(TARGETS_BBC)) $(addsuffix .Z, $(TARGETS_Z))

DEPS=

TARGETS_O=$(addprefix $(BUILD)/, $(TARGETS))

all:	$(TARGETS_O)

$(BUILD)/%.bbc: %.bas %.bbc.inf
	basictool -t $< $@
	cp $(notdir $@).inf $@.inf

$(BUILD)/%.Z: %.mlt
	./scripts/mlt2nula.py $< $@
	$(eval BN=$(shell echo $< | sed -e 's/\..*//g' -e 's/[^a-zA-Z0-9]/_/g' -e 's/_+/_/g' ))
	echo "Z.$(BN) FF3000 FF3000" >$@.inf

ssd:	all
	dfs form -80 $(SSD)
	dfs title $(SSD) "nulatest"
	dfs add $(SSD) $(addsuffix .inf, $(TARGETS_O)) 
	dfs add $(SSD) $(wildcard extras/*.inf)

deploy:	ssd
	mkdir -p $(DEPLOY)
	dfs read -i -d $(DEPLOY) $(SSD)

clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
