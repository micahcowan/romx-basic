# AppleSoft Autorun for the ROMXc/e

This project provides a tool for the
[ROMXc/e](https://www.theromexchange.com/), to create
ROM images that will boot directly into a running
AppleSoft BASIC program when you turn on your Apple //c
or //e.

Note that a DOS will *not* be included in the resulting ROM,
so while the BASIC program will be pre-loaded into memory and
run automatically at boot, it will not be able to access other
files (or DOS features), and if changes are made to the
program in memory, there will be no means to save those
changes anywhere, even if a disk is inserted. (On a //e, you
may still be able to save to cassette.)

In order to create the 16k ROM file (with space for the
bootloader), your BASIC program must be less than "a bit less
than 16k", currently a maximum of 15,609 bytes.

The resulting ROM file contains only your BASIC program, and
the code required to load it. It doesn't even contain
AppleSoft itself, so you can't boot from it - that is, it's
an "aplication" ROM, not a system ROM. Be sure to add
`&S1` to the description after uploading to your ROMXc/e
(where `1` is the number for a ROM that contains AppleSoft
and the system monitor - the normal Apple boot ROM),
so that the ROMXc/e will know it should change to that ROM
after your program has finished loading into memory.

## Example usage

To create a ROM image from an AppleSoft BASIC program, follow
these steps, with the provided disk image loaded:

1. `LOAD` the BASIC program of your choice. (An example BASIC
program, `SCREEN SAVER`, has been provided on the disk.)
2. `] BLOAD MAKE ASOFT ROM`
3. At the prompt, enter an appropriate name for the ROM file
you wish to create.
4. Upload the ROM image to your ROMXc/e (see your ROMXc/e
User Manual for how to do this)
5. Edit the description to add `&S1` at the appropriate column,
so that the ROMXc/e knows to switch to the "real" ROM after
it's finished loading your BASIC program from this one.
(Again, see the ROMXc/e manual, under "Adding an Application
Image", for details.)

---

See https://www.theromexchange.com/ for more information about
ROMX and friends
