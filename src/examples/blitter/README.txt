# Blitter Examples

This SSD contains a set of example files that are intended to demonstrate the
working of the Blitter "chip".

These examples are in BASIC and coded for clarity rather than the most 
efficient use of the Blitter.

## A note on the ! operator

The Blitter registers are laid out in little-endian format to make it easier
to access registers using the ! operator from BASIC. In cases where there are
pokes to 16-bit registers the ! operator can be used so long as it is 
understood that the following 2 register bytes will be overwritten. For this 
reason the registers should generally be set in an ascending order. For example
the STRIDE registers.

Also, the address registers of the Blitter often share a 4-byte slot with their
associated data register - in general this doesn't matter as the address 
register is usually only set in cases where that channels DMA will be enabled
in which case the data register will be updated by the DMA.

## 1. 1BPPFO1

This program demonstrates using the Blitter in one of its simplest use-cases,
where a 1bpp sprite definition (in this case the character ROM) is "exploded" 
to MODE 1 2bpp before being used to "mask" a solid colour on to the screen.

30-40 change to mode 1 and setup some mode-specific constants such as the
width of a character row in bytes (screen stride).

50-390 address constants for accessing the Blitter Chip. From 8-bit BASIC the
simplest way is to use the FRED/JIM interface

400 page in the Blitter by writing the device and page select registers. For
more information on the way JIM/FRED is used in the Blitter see:

[API](https://github.com/dominicbeesley/blitter-vhdl-6502/blob/main/doc/API.md)
[JIM proposal](https://github.com/dominicbeesley/DataCentre/blob/master/jim-spec-2019.txt)

410-440 repeatedly call PROCBlitCharCell with random coordinates

460 Make a colour byte, this is a byte that when poked to the screen would
create a solid 4 pixels of colour C%

470 Calculate the screen destination adddress.

500 configure BLITCON to use DMA channels A,C and D. A is the mask data from
the character ROM, C is the original screen contents and D is the channel used
to write back the updated data.

510 configure FUNCGEN. To plot channel B through the mask from channel A and
the data from channel C through the inverse of the mask.

Referring to the FUNCGEN Venn diagram we can see that bits 6 and 7 are set to
include the intersection of A and B and that bits 1 and 5 are set to include 
the bits for C that do not intersect channel B.

520-530 set the width in bytes minus one and height minus 1

550-560 set the first/last masks, as we are character cell aligned these should
be set to plot all bits.

570 set the address for channel this is in the MOS ROM at C000 note that as the
Blitter uses 24-bit Physical addresses we must specify bank FF to access the
MOS ROM.

580 set the solid colour by poking the channel B data latch this will be used
as the channel B data for every byte because we didn't set "EXEC_B" at line 
500

590 set the screen destination address calculated on line 470

600 set the stride for channel A, this is the number of bytes between each row
of data. Note that the ! operator is used here to set a 16 bit register.

610 set the stride for channel C, this is the number of bytes between each 
CHARACTER row of data. The address generators for Channel C are set to CELL
mode below which means that for each row of pixels 1 is added to the row start
address to get to the next row except for the 7th row in each cell in which case
the STRIDE-7 is added to jump to the next row of cells.

630 poking this register will start the Blitter because the ACT bit is set in
addition the CELL bit ensures that the C and D channels will have addresses 
generated that are suitable for the BBC Micro's character cell oriented 
display. The 2BPP bits ensure that the data in loaded into channel A are 
"exploded" in a manner that is suitable for 2BPP MODE 1.

660 this procedure pages the Blitter/Chipset page into JIM.





# References

[FUNCGEN Venn diagram](https://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node011E.html)