.PHONY: all
all: ROMX-BASIC.DSK

ROMX-BASIC.DSK: EMPTY.DSK basic-loader.bin rom-maker.bin SCREEN-SAVER RUNME Makefile
	trap 'rm -f $@; exit 1' EXIT; \
	set -e; \
	cp $< $@; \
	dos33 $@ BSAVE -a 0x6000 rom-maker.bin 'MAKE ASOFT ROM'; \
	dos33 $@ SAVE A RUNME; \
	dos33 $@ HELLO RUNME; \
	dos33 $@ DELETE HELLO; \
	dos33 $@ SAVE A SCREEN-SAVER 'SCREEN SAVER'; \
	dos33 $@ BSAVE -a 0x4500 basic-loader.bin 'ASOFT.LOADER'; \
	trap - EXIT

.SUFFIXES: .bin
.o.bin:
	ld65 -o $@ -t none $<

.s.o:
	ca65 -o $@ --list-bytes 0 --listing $(subst .s,.list,$<) $<

SCREEN-SAVER: screen-saver.bas
	tokenize_asoft < $< >| $@

RUNME: runme.bas
	tokenize_asoft < $< >| $@

basic-loader.o: basic-loader.s launch-error-msg.inc

launch-error-msg.inc: launch-error-msg.txt msgconv.sh
	./msgconv.sh $< > $@ || { rm -f $@; exit 1; }

.PHONY: clean
clean:
	rm -f *.o *.list *.bin launch-error-msg.inc ROMX-BASIC.DSK SCREEN-SAVER
