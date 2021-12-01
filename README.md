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
(Again, see the ROMXc/e User Manual, under *Adding an
Application Image*, for details.)

# FAQ

## How does it work? (some high-level technical details)

The ROMXc/e supports an "application" ROM chaining feature, whereby the
Apple II is booted into an "application" ROM that contains a simple
payload, and just enough code to copy the payload into RAM at the right
place, before triggering the ROMXc/e to switch to a "real" ROM suitable
for running the system (and containing things like AppleSoft, and the
system monitor, I/O routines, etc.).

The `MAKE ASOFT ROM` tool finds whatever BASIC program is already loaded
into memory, and drops it into a ROM image file together with code to
copy it into RAM on boot. When the ROM image is booted, it copies the
BASIC program, along with itself, into RAM, and then switches the ROM
out for the "main" image (the one that actually contains AppleSoft, like
an Apple II ROM should).

At this point, the real ROM has been loaded but the computer is still
being controlled by the bootloader code in RAM. It can't just jump right
into the startup code from the real ROM, though, because that would
obliterate the BASIC program we just reloaded! But, AppleSoft does a lot
of things when it starts up, and we didn't want to include all that code
in our bootloader. So, after runnning a few setup routines from the
Monitor, we hijack the keyboard input routine, replacing it with our
own, and *then* hand control over to AppleSoft's "cold start" routine.
When AppleSoft finishes setting things up the way it wants them, it
spits out the `]` prompt and waits for keyboard input - that's when our
hijack code pounces! It restores a couple of things that AppleSoft's
startup code blew away so the program is back in place once again, and
then simulates typing `RUN` at the prompt, restoring normal keyboard
input just as it sends the final return-key stroke.

The AppleSoft Autorun bootloader code was based on the ROMX/c/e
project's "Fastload DOS" image code as a template. Source code for the
"Fastload DOS image" is found in the PDF guide within the *ROMify Image
Tutorial.zip* package available at
https://theromexchange.com/documentation/romxce. That code is for
creating 12k ROM images for the original ROMX, however, and not the
ROMXc/e.

## My ROM doesn’t boot! It just gives some dumb message about being a BASIC image that can’t be launched

This message indicates that you forgot to add an `&S1` in the
description line for your ROM image, after you uploaded it to the
ROMXc/e! Or, if you did add it, then it didn't start in the right
column. The exact location of this special marker is important - read
your ROMXc/e manual for details!

You may also get this message if you manage to hit your RESET key while
the bootloader is still starting up.

## How do I save changes to the program after booting from the ROM?

The short answer is - you don't. When your program's ROM is finished
booting, your program is loaded, but there is no DOS (neither DOS, nor
ProDOS). The only facilities for loading or saving a program are the
built-in cassette-interface commands `LOAD` and `SAVE` (as bare words
themselves, no filenames after). These commands just flat-out won't work
on an Apple //c, though they may on a //e.

Power users and developers may know a trick to move the program to a new
location where it won't be destroyed by booting a disk, and then run
`PR#6` with a DOS disk inserted, finally moving the program back to
where it belongs, and fixing up some links (in a similar way that the
AppleSoft Autorun bootloader does, actually!), but describing how to do
do this is unfortunately a bit too involved for this FAQ.

The easiest way to make changes to your BASIC program is to load it from
the original DOS file you made the ROM from in the first place, and save
it back again.

## Why can’t my program access files

If see your BASIC program printing things to the screen like `BLOAD
MYHELPER.B`, that's a likely sign that your program was expecting to be
able to communicate with DOS to save or load data, or machine-language
helpers. That's not possible with this ROM creator, because no DOS is
loaded at all - only the BASIC program itself is present in memory (and
AppleSoft itself, in ROM).

## Why can’t I access 80-column mode or the serial port?

You actually can! But, if your BASIC program was written for a DOS, then
it may be using the approved DOS way for doing that. Since DOS is not
loaded when your BASIC program boots from ROM, you'll need to change it
to use the direct method instead.

For instance, the right way to access 80-column mode from BASIC under
DOS, so that DOS can take care to link everything up appropriately, is
something like:

```
10 PRINT CHR$(4);"PR#3"
```

This is the right way to do it in DOS, because DOS is actually watching
your program output, and will commandeer it when it sees a string like
that. But since no DOS is loaded when you boot from the ROM image, there
is nothing watching program output, and your BASIC program will just
wind up printing the string `PR#3` to the screen instead of switching to
80-column mode.

To fix, it, find it and change it to something like:

```
10 PR#3
```

That's the right way to do it in raw AppleSoft programs. It's the
*wrong* way to do it in files saved to a disk (i.e., in DOS or ProDOS),
because it deprives the DOS of the chance to make sure it won't get
confused about where input and output goes.

The same thing applies to using the serial port to print things, or to
communicate via modem, except the string may be something like `PR#1` or
`PR#2` instead of `PR#3`.

## I have a ROMX, not a ROMXc or e. Can I use AppleSoft Autorun?

Not at this present time. However, I do also have a ROMX, so when I have
time and the inclination, I may adapt the tool to create a version that
works with the ROMX. Naturally, the maximum BASIC program size will be
smaller, as the ROMX only accepts 12k images.

## My BASIC program is too large! The ROMXc/e supports 32k image files, why doesn't your tool create those?

Because it's a little more work, and wasn't necessary for scratching the
particular itch I had - I didn't have any >16k BASIC programs I'm dying
to boot directly into on my Apple II. I may add this capability at some
point in the future. The easiest way to ensure that happens, would be to
get me fired up about your awesome 30k BASIC program! ;)

Realistically, though, I think most BASIC programs that are that large,
also expect to have DOS available, in which case the AppleSoft Autorun
ROM image maker tool may be a poor fit.

## Why can't you just include DOS in the generated ROM, too?

Again, it's more work than I was motivated to do. I may do it in future,
but probably not. It would definitely need to be a 32k ROM image at that
point.

## Your tool is neat! ...But my favorite BASIC program is in Integer Basic. Can you make an Integer Basic Autorun tool?

Not at this time. There isn't enough neat software in Integer BASIC to
motivate this - though it would be lovely to have Bob Bishop's
*Applevision* load at boot!

---

See https://www.theromexchange.com/ for more information about
ROMX and friends
