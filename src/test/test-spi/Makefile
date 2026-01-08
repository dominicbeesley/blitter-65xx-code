		include ../../Makefile.defs

AS=ca65 -I $(TOP)/includes 
LD=ld65

OBJS=test-spi
TARGETS=test-spi
DEPS=

TARGETS_O=$(addprefix $(BUILD)/, $(addsuffix .bbc, $(TARGETS)))

all:	$(TARGETS_O)
ssd:	all
deploy:	all

$(BUILD)/%.bbc: %.bas %.bbc.inf
	basictool -t $< $@
	cp $(notdir $@).inf $@.inf

clean:
	-rm $(TARGETS_O)
	-rm $(addsuffix .inf, $(TARGETS_O))
