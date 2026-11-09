
Note: this is just ideas so far no code has been cut yet


# 65816 MOS-Extender

This program can be used to bootstrap a 65816 native mode program under an 
8-bit BBC Micro MOS environment.

The program will set up a set of native mode and extended 65816 vectors in the
redirected hardware vector area at 00 8Fxx and redirect them at shims to allow
native mode applications to call the unmodified 8-bit MOS and handle interrupts
by passing on to 8-bit ROMS.

In addition to the native mode vectors the new ABORT and COP vectors are also
handled in emulation mode.

# Throttling and Memory map

The Blitter's "11" 816 boot mode will be enabled. This means that bank 0 is 
mapped on to bank "FF" in emulation but in native mode bank 0 will map on to
ChipRAM. However care should be taken when using the area to not overwrite
BLTURBO shadow memory. 

Throttling will remain in force in emulation mode and can be controlled in the
usual ways (see the BLTUTIL ```*BLTURBO``` command).

# Interrupts

In the current version all hardware interrupts are passed on to the native MOS
for handling. In future there will be the native vectors to allow direct
interrupt handling - however this is complicated by the fact that interrupts
must be enabled during OS calls down to emulation mode and passed back up to
native mode.
