# Things needed before can implement

## BLTUTIL

### Memory size 

Really need to detect this at boot time and move the BLTUTIL heap up to meet 
this limit.

### Slot E

This is hardware specified as bank "1F" - move at boot time to top of RAM?
- changes to OSWORD 99/\*ROMS\documentation
- maybe a \*CON. option, possibly shadow other sockets?

### BLTURBO Lxx

Move out of ChipRAM bank 0 to high memory. Having it in bank 0 clashes with 
other bank 0 uses in native mode and bank 0 is a scarce resource. 

Suggest: make Lxx RAM moveable to high memory with an extra hw register to set 
which bank to use - place at top of memory above heap.

