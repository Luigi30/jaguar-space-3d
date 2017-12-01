BINFILE = space.jag

SRCPATH = .
BINPATH = ../bin/
OBJPATH = ../obj/
TOOLPATH= ../tools/

OBJFILES = $(OBJPATH)main.o $(OBJPATH)utils/list.o $(OBJPATH)utils/list_functions.o $(OBJPATH)fixed.o $(OBJPATH)gfx/blit.o $(OBJPATH)mobj.o $(OBJPATH)images.o $(OBJPATH)gfx/palette.o $(OBJPATH)paldata.o $(OBJPATH)dsp.o $(OBJPATH)dsp_68k.o $(OBJPATH)dsp_matrix.o $(OBJPATH)matrix.o $(OBJPATH)linedraw.o $(OBJPATH)gpu.o $(OBJPATH)gpu_68k.o $(OBJPATH)matrix_68k.o $(OBJPATH)matrix_multiplication.o
IMAGES = images/atarifont.s images/atarifont8x8.s

UNAME := $(shell uname -a)
ROMPATH = C:\jaguar\space\bin\space.jag

ifeq ($(findstring Microsoft,$(UNAME)),Microsoft)
    VJAGFOLDER=/mnt/e/virtualjaguar/
    ROMPATH=/mnt/c/jaguar/space/bin/space.jag
else ifeq ($(findstring NT-5.1,$(VARIABLE)),CYGWIN)
    VJAGFOLDER=/cygdrive/e/virtualjaguar/
else
    # Not found
    VJAGFOLDER=e:/virtualjaguar/
endif

DOCKER = docker.exe run --rm -v c:/jaguar/space/:/usr/src/compile --workdir /usr/src/compile/src toarnold/jaguarvbcc:0.9f
CC = vc
AS = ~/vasm/vasmjagrisc_madmac
JAGINCLUDE = /opt/jagdev/targets/m68k-jaguar/include
CONVERT = $(TOOLPATH)/converter.exe --target-dir images/ 

GNU_CC = m68k-elf-gcc-7.2.0
CFLAGS = -O0 -MP -MD -std=gnu11 -nostartfiles -I${VBCC}/targets/m68k-jaguar/include

RMAC = ./rmac.exe
RMACFLAGS = -i$(JAGINCLUDE)

.PHONY: clean

all: build

build:	$(IMAGES) $(OBJFILES)
	$(DOCKER) $(CC) -v -O0 +jaguar.cfg -lm -o $(BINPATH)$(BINFILE) $(OBJFILES)

clean:
	-rm ../obj/gfx/*
	-rm ../obj/*
	-rm ../bin/*

run:
        #Adjust this path to your configuration.
	$(VJAGFOLDER)virtualjaguar.exe --alpine $(ROMPATH)

upload:
	-jcp -r
	sleep 2
	jcp -c $(BINPATH)$(BINFILE)

$(OBJPATH)%.o: %.c %.h
	@mkdir -p $(@D)
	$(DOCKER) $(CC) -I$(SRCPATH) +jaguar.cfg -c -c99 -o $@ $?

$(OBJPATH)%.o: %.asm
	$(DOCKER) $(CC) +jaguar.cfg -c -c99 -o $@ $?

$(OBJPATH)%.o: %.tom.s
	$(AS) -L $@.lst $? -I$(JAGINCLUDE) -I$(SRCPATH) -Fvobj -mgpu -o $@

$(OBJPATH)%.o: %.jerry.s
	$(AS) -L $@.lst $? -I$(JAGINCLUDE) -I$(SRCPATH) -Fvobj -mdsp -o $@

#Images
images/atarifont.s: images/atarifont.gif
	$(CONVERT) --opt-clut --clut $? 

images/atarifont8x8.s: images/atarifont8x8.bmp
	$(CONVERT) --opt-clut --clut $? 
