BINDIR = bin

all: convert-model

convert-model: convert-model.scm
	gsc -o $(BINDIR)/convert-model -exe convert-model.scm

clean:
	rm bin/*
