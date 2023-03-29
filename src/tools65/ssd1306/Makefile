BASICTOOL=basictool

BUILD=./build
HOSTFS=~/hostfs/tools65

TARGETS=$(BUILD)/test1306.tok

$(shell mkdir -p $(BUILD))

all: hostfs

hostfs: $(BUILD)/test1306.tok
	$(shell mkdir -p $(HOSTFS))
	cp $(BUILD)/test1306.tok* $(HOSTFS)


$(BUILD)/test1306.tok:test1306.bbc
	basictool -t $< $@
	echo '$$.TST1306 FFFF8023 FFFF8023' >$@.inf

clean:
	-rm $(BUILD)/*
