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
more information on the way JIM/FRED is used in the Blitter see the API and
JIM documents referred below

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


## 2. 1BPPFO2

This example is much the same as the one above except that the start address
on the screen is at an arbitrary row within a cell. This shows that the 
Blitter's CELL mode correctly proceeds to the next row in all cases.


## 3. 1BPPFO3

This example is extended to allow plotting the characters at arbitrary pixel 
positions on the screen and show the use of the SHIFT registers.

500 - here we calculate the number of bits of shift that we will need to apply
to the A register. As this is a 2 bits per pixel mode (4 pixels per character
cell) we will need to shift for up to 4 pixels. If we do need a shift then we
will also need to widen the blit operation by 1 byte.

590 - setting the SHIFT A register also sets the shift B register. Depending on
the number of bits per pixel in force some bits of the value will be ignored in
the SHIFT B register in almost all cases this means that we can just set the
SHIFT A register. Shifts are always to the right. 

Data are shifted from one byte to the next i.e. the "previous" bytes data are
shifted into the current byte. Because of the bit-layout of the BBC screen 
memory shifting pixels is not straight forward. In 2bpp mode for example the
bits will be shifted as below for a shift of 1:

            first byte                  Second byte

Before      P7 P6 P5 P4 P3 P2 P1 P0     C7 C6 C5 C4 C3 C2 C1 C0

After       ?? P7 P6 P5 ?? P3 P2 P1     P4 C7 C6 C5 P0 C3 C2 C1 

610 - as can be seen in the example above in the first byte worth of data 
garbage from the previous contents of the B register are shifted in to the 
channel B data on the first byte of each pixel row. For this reason there is
the MASK_FIRST register which may be set to mask off these unwanted bits.

This register works in the same way as channel A i.e. it is "exploded" to the
correct number of bits per pixel.

620 - BLIT_MASK last is the corollary of BLIT_MASK_FIRST but for the last 
mask byte of a row, here it used to only show the bits that we want in the 
left most pixels.

## 4. BLIT1

This example blits some sprite data contained in a sprite data file onto the 
screen. The sprites are plotted without a mask. The dimensional information for
the sprite is hard-coded.

20 - load the sprite data file to memory this loads the data into bank 2

30 - draw a random background

580 - the EXEC_B is added to draw data through channel B

660 - the DATA_A register is loaded with FF to allow all data to pass to the
screen unmasked.

It is possible, because this example is unmasked to change the FUNCGEN setting
and completely ignore the Channel A masks. That is left as an exercise for the
reader.

## 5. BLIT2

This example blits a sprite at different horizontal pixel alignments within
a character cell and demonstrates an edge case that must be handled where there
is a shift and the number of mask bytes in a row is not equal to the sprite 
data width in bytes divided by the number of bits per pixel.

520 the width of this sprite in bytes is 5 (20 pixels) the width of the mask
is 3 bytes (24 pixels).

590 EXEC_A is added

660-670 because the mask width and sprite data width do not align we need to 
add a fiddle to the LAST_MASK to always allow the first 4 bytes and mask the
second half. This only occurs where the sprite data is so aligned. 

## 6. BLIT 3

This example reads in dimension data for all the sprites in the sprite file and
plots the sprites at random positions on the screen.

## 7. BLIT 4

This example shows the use of the exta Channel E. This can be used to quickly
and efficiently save the screen contents "underneath" a sprite as it is 
blitted. The screen contents so streamed can be restored to the screen with 
another blit operation.

30 - allocate arrays to store a record of the widths and addresses of the 
sprites before they are blitted to the screen.

640-740 - each sprite is unblitted by doing a Channel B to Channel D unmasked
blit. The addresses are those we store in the arrays as we blit the sprites
below.

860 - EXEC_E added

1030 - the addresses for channels D/E are saved along with the width in bytes
and height so that we know what to restore where.

# References

[FUNCGEN Venn diagram](https://amigadev.elowar.com/read/ADCD_2.1/Hardware_Manual_guide/node011E.html)
[API](https://github.com/dominicbeesley/blitter-vhdl-6502/blob/main/doc/API.md)
[JIM proposal](https://github.com/dominicbeesley/DataCentre/blob/master/jim-spec-2019.txt)
[CHIPSET](https://github.com/dominicbeesley/blitter-vhdl-6502/blob/main/doc/chipset.md)