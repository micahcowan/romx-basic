all: ROMX-BASIC.DSK

ROMX-BASIC.DSK: src/ROMX-BASIC.DSK
	cp $< $@

.PHONY: src/ROMX-BASIC.DSK
src/ROMX-BASIC.DSK:
	make -C src all

clean:
	rm -f ROMX-BASIC.DSK
	make -C src clean
