override VFILES := $(shell find ./ -type f -name '*.v')
override SFILES := $(shell find ./ -type f -name '*.glsl')

.PHONY: all
all: $(VFILES) march.h
	clear
	v -g -profile profile.txt run .

march.h: $(SFILES)
	clear
	v shader march.glsl

.PHONY: prod
prod: $(VFILES) march.h
	clear
	v -g -prod run .