# Blitter Examples

This SSD contains a set of example files that are intended to demonstrate the
working of the Blitter "chip".

These examples are in BASIC and coded for clarity rather than the most 
efficient use of the Blitter.

## 1. 1BPPFON

This program demonstrates using the Blitter in one of its simplest use-cases,
where a 1bpp sprite definition (in this case the character ROM) is "exploded" 
to MODE 1 2bpp before being used to "mask" a solid colour on to the screen.

30-40 - change to mode 1 and setup some mode-specific constants such as the
width of a character row in bytes (screen stride).

50-390 - address constants for accessing the Blitter Chip. From 8-bit BASIC the
simplest way is to use the FRED/JIM interface

400 - page in the Blitter by writing the device and page select registers. For
more information on the way JIM/FRED is used in the Blitter see:

[API](https://github.com/dominicbeesley/blitter-vhdl-6502/blob/main/doc/API.md)
[JIM proposal](https://github.com/dominicbeesley/DataCentre/blob/master/jim-spec-2019.txt)

410-440 - repeatedly call PROCBlitCharCell with random coordinates

460 - Make a colour byte, this is a byte that when poked to the screen would
create a solid 4 pixels of colour C%

500 - configure BLITCON to use DMA channels A,C and D. A is the mask data from
the character ROM, C is the original screen contents and D is the channel used
to write back the updated data.

510 - configure FUNCGEN. To plot channel B through the mask from channel A and
the data from channel C through the inverse of the mask.

Referring to the FUNCGEN Venn diagram we can see that bits 6 and 7 are set to
include the intersection of A and B and that bits 1 and 5 are set to include 
the bits for C that do not intersect channel B.





# References

[FUNCGEN Venn diagram](https://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node011E.html)