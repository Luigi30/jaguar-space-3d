ROOT = ../../
OBJPATH = ../../obj
CONVERTER_DIR = $(ROOT)/scheme

MODELS = cube cube_two
MODEL_OBJECTS = $(foreach model,$(MODELS),$(OBJPATH)/models/model_$(model).o)
MODEL_ASMS = $(foreach model,$(MODELS),./output/model_$(model).asm)

CC = vc
JAGINCLUDE = /opt/jagdev/target/m68k-jaguar/include

all: $(MODELS) $(MODEL_OBJECTS)

$(MODELS):
	CONVERTER_LIB=$(CONVERTER_DIR) $(CONVERTER_DIR)/bin/convert-model $@

$(OBJPATH)/models/model_%.o: output/model_%.asm     
	$(CC) +../jaguar.cfg -I$(JAGINCLUDE) -c -c99 -o $@ $<

clean:
	rm output/*.asm
	rm *.o
