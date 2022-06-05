override VFILES := $(shell find ./ -type f -name '*.v')

.PHONY: all
all: $(VFILES) march.h
	clear
	v -g run .

march.h: march.glsl
	clear
	v shader . 