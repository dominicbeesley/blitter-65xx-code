		include ../../../Makefile.defs

TARGETS=VGA8I
TARGETS_O=$(addprefix $(BUILD)/, $(addsuffix .F16, $(TARGETS)))

all:	$(TARGETS_O)
ssd:	all
deploy:	all


$(BUILD)/%.F16: %.F16.txt %.F16.inf
	$(SCRIPTS)/text2f16.pl $(filter %.F16.txt, $^) $@
	cp $(filter %.F16.inf, $^) $(BUILD)/


clean:
	-rm $(TARGETS_O)
