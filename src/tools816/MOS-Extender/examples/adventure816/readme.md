# Advent65

A top-down adventure type tech-demo to demonstrate the blitter chipset's fast
sprite plotting and background preservation capabilities.

The maps and graphics should be prepared with the [Tiled](https://www.mapeditor.org/)
game editor

Note: this demo requires a VideoNULA and for the [Aeris HSync/Vsync pick-up wires to be fitted](https://github.com/dominicbeesley/blitter-vhdl-6502/blob/main/doc/getting-started.md#hookup-the-aeris)

# Wander

Fast sprite plotting and preservation tech demo, use < and > keys for 
more/fewer little Ishbels


# Build notes

This project requires Python 3 (with Pillow) and Perl (with XML::LibXML) it also requires the "BBC Micro" capable version of cc65 from https://github.com/dominicbeesley/cc65

This project also uses the experimental clib rom (included) from https://github.com/dominicbeesley/cc65-clib

