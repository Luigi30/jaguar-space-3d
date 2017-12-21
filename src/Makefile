BINFILE = space.jag

ROOT = $(shell cd ..; pwd)
SRCPATH = $(ROOT)/src/
BINPATH = $(ROOT)/bin/
OBJPATH = $(ROOT)/obj/
TOOLPATH= $(ROOT)/tools/

OBJFILES = $(OBJPATH)main.o $(OBJPATH)utils/list.o $(OBJPATH)utils/list_functions.o $(OBJPATH)fixed.o $(OBJPATH)gfx/blit.o $(OBJPATH)mobj.o $(OBJPATH)images.o $(OBJPATH)gfx/palette.o $(OBJPATH)paldata.o $(OBJPATH)dsp.o $(OBJPATH)dsp_68k.o $(OBJPATH)dsp_matrix.o $(OBJPATH)matrix.o $(OBJPATH)linedraw.o $(OBJPATH)gpu.o $(OBJPATH)gpu_68k.o $(OBJPATH)matrix_68k.o $(OBJPATH)matrix_multiplication.o $(OBJPATH)sound_68k.o $(OBJPATH)cube.o
IMAGES = images/atarifont.s images/atarifont8x8.s

UNAME := $(shell uname -a)
ROMPATH = C:\jaguar\space\bin\space.jag

ifeq ($(findstring Microsoft,$(UNAME)),Microsoft)
    VJAGFOLDER=/mnt/e/virtualjaguar/
    ROMPATH=e:\\virtualjaguar\\software\\space.jag
else ifeq ($(findstring NT-5.1,$(VARIABLE)),CYGWIN)
    VJAGFOLDER=../../virtualjaguar
else
    # Not found
    VJAGFOLDER=../../virtualjaguar/
endif

DOCKER = docker.exe run --rm -v c:/jaguar/space/:/usr/src/compile --workdir /usr/src/compile/src toarnold/jaguarvbcc:0.9f
CC = vc
M68KAS = vasmm68k_mot

AS = vasmjagrisc_madmac

LD = vlink
LDFLAGS = -bjagsrv -x -L/home/luigi/vbcc/targets/m68k-jaguar/lib -Tjaguar-elf.ld -nostdlib -minalign 4 -Bstatic -Cvbcc

JAGINCLUDE = /opt/jagdev/target/m68k-jaguar/include
CONVERT = $(TOOLPATH)/converter.exe --target-dir images/ 

GNU_CC = m68k-elf-gcc-7.2.0
CFLAGS = -O0 -MP -MD -std=gnu11 -nostartfiles -I$(VBCC)/targets/m68k-jaguar/include

RMAC = ./rmac.exe
RMACFLAGS = -i$(JAGINCLUDE)

.PHONY: clean

all: build

build:	$(IMAGES) $(OBJFILES)
	cp ../../u235/dsp.obj ../obj/u235.obj
	$(CC) -v -O0 +jaguar.cfg -lm -o $(BINPATH)$(BINFILE) $(OBJFILES) ../obj/u235.obj

clean:
	-rm ../obj/gfx/*
	-rm ../obj/*
	-rm ../bin/*

run:
	cp $(BINPATH)$(BINFILE) $(VJAGFOLDER)/software
	$(VJAGFOLDER)virtualjaguar.exe --alpine $(ROMPATH)

upload:
	-jcp -r
	sleep 2
	jcp -c $(BINPATH)$(BINFILE)

emu:
#	pscp luigi@172.26.218.203:virtualjaguar/release/virtualjaguar.exe ../../virtualjaguar


$(OBJPATH)%.o: %.c %.h
	@mkdir -p $(@D)
	$(CC) -I$(SRCPATH) +jaguar.cfg -I/opt/jagdev/target/m68k-jaguar/include -c -c99 -o $@ $?

$(OBJPATH)%.o: %.asm
	$(CC) +jaguar.cfg -I/opt/jagdev/target/m68k-jaguar/inclujde -c -c99 -o $@ $?

$(OBJPATH)%.o: %.tom.s
	$(AS) -L $@.lst $? -I$(JAGINCLUDE) -I$(SRCPATH) -Fvobj -mgpu -o $@

$(OBJPATH)%.o: %.jerry.s
	$(AS) -L $@.lst $? -I$(JAGINCLUDE) -I$(SRCPATH) -Fvobj -mdsp -o $@

#Images
images/atarifont.s: images/atarifont.gif
	$(CONVERT) --opt-clut --clut $? 

images/atarifont8x8.s: images/atarifont8x8.bmp
	$(CONVERT) --opt-clut --clut $? 
