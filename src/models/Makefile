ROOT = ../../
OBJPATH = ../../obj
CONVERTER_DIR = $(ROOT)/scheme

MODELS = cube sphere cone cube_resized gay
MODEL_OBJECTS = $(foreach model,$(MODELS),$(OBJPATH)/models/model_$(model).o)
MODEL_ASMS = $(foreach model,$(MODELS),./output/model_$(model).asm)

CC = vc
JAGINCLUDE = /opt/jagdev/target/m68k-jaguar/include

all: $(MODELS) $(MODEL_OBJECTS)

$(MODELS):
	dos2unix input/$@.obj
	gsi $(CONVERTER_DIR)/convert-model.scm $@

$(OBJPATH)/models/model_%.o: output/model_%.asm
	$(CC) +../jaguar.cfg -I$(JAGINCLUDE) -c -c99 -o $@ $<

clean:
	rm output/*.asm
	rm *.o
