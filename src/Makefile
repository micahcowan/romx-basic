.PHONY: all
all: ROMX-BASIC.DSK

ROMX-BASIC.DSK: EMPTY.DSK basic-loader.bin Makefile
	trap 'rm -f $@; exit 1' EXIT; \
	set -e; \
	cp $< $@; \
	dos33 $@ BSAVE -a 0x8000 basic-loader.bin BLOADER; \
	trap - EXIT

basic-loader.bin: basic-loader.o
	ld65 -o $@ -t none $<

.s.o:
	ca65 -o $@ --listing $(subst .s,.list,$<) $<

basic-loader.o: basic-loader.s launch-error-msg.inc

launch-error-msg.inc: launch-error-msg.txt msgconv.sh
	./msgconv.sh $< > $@ || { rm -f $@; exit 1; }

.PHONY: clean
clean:
	rm -f *.o *.list *.bin launch-error-msg.inc ROMX-BASIC.DSK
