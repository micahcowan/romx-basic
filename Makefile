all: ROMX-BASIC.DSK

ROMX-BASIC.DSK: src/ROMX-BASIC.DSK
	cp $< $@

src/ROMX-BASIC.DSK:
	make -C src all

clean:
	rm -f ROMX-BASIC.DSK
	make -C src clean
