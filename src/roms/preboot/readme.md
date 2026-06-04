# PREBOOT

## Introduction

A need has been identified to have an easy de-bricking system, especially for 
the C20K which cannot be easily be initially bootstrapped without the Flash 
EEPROM chip having been pre-programmed. The Blitter boards can however be 
initially configured by placing physical ROMS in BBC's motherboard 
MOS/BASIC/BLTUTIL rom slots if the ROM images become corrupted. On the C20K
all run-time ROMs are hosted in the Flash EEPROM which can easily be 
overwritten by the user, either accidentally or when testing new 
configurations.

The preboot system provides a complex software ecosystem by including a small
<512 bytes ROM baked into the firmware that bootstraps another larger software
which is loaded from the FPGA configuration SPI Flash EEPROM or FPGA UFM.

### A Note on different ROMS

There are several different types of non- or semi-volatile storage mentioned in
this document:

#### FPGA SPI Flash configuration memory

Also referred to as SPI Flash memory in this document. This is a serial flash
ROM usually around 16 to 64 Mbits in size which is used to store the initial
configuration of the FPGA, loaded to the FPGA at power-on. The user may also 
use the space not used for FPGA configuration for storing data. In the 
pre-boot system the loadable ROM-sets and pre-boot2 program are stored here.

It is hoped that it is less likely that this memory will be inadvertently 
corrupted by user actions.

#### Flash EEPROM

This is used to store the MOS and ROM images which are accessed at run-time by
the FPGA cores. The user may use the SRLOAD, SRERASE etc commands from the 
BLTUTIL ROM to load arbitrary programs to this memory, which can easily lead
to a bricked system.

#### i2c configuration EEPROM

The Blitter and C20K boards also contain a small 64kbit i2c EEPROM which is
used to store configuration for the \*CONFIGURE command. This is not currently
used by Preboot.

#### Battery Backed RAM

The C20K and Blitters contain RAM that can also store ROM-images, this can
easily become corrupted, due to inadvertent use of SRLOAD etc, software 
crashes and bit-rot caused by low batteries.

## Preboot-1

This is a tiny ROM that is substituted for the main MOS image at reset. It 
checks that there is a special keypress (CRTL-DELETE-BREAK) and if so then 
copies the preboot-2 program into the sideways-mos area for map 0 and, if 
the checksum is valid, boots that image. The data for the preboot-2 image 
are stored in the FPGA's SPI flash memory at a set location (board 
dependent).

## Preboot-2

The implements a menu-based system to allow the user to perform a reset of the
ROM images (amongst other things) and then reboot the system.

The preboot-2 may load further data and program overlays from the SPI flash as
it is running.

# Maps

The C20K and Blitter boards have two ROM "maps" map 0 is usually used by the
t65 core for NMOS 6502 compatible ROMs and games and map 1 is typically used
by the hard-cpu (in the case of the C20K the on-board 65816).

The user may switch between rom maps by holding down break for 3 seconds 
or pressing the reset button next to the power socket whilst holding down
option button 1 (on the C20k, second from bottom on left of pcb) or by fitting
the SWROMX button or jumper on the blitter boards.

# Using preboot

The preboot can be entered at any time with suitable firmware by holding down
break-ctrl-backspace (in that order) then release break whilst still holding
ctrl-backspace. The mk.2 blitter board will only enter preboot when the T65
core is active to avoid crashing hard-cpus

The machine should now reboot to the preboot main-menu, if it doesn't then it
might be that a correct preboot image has not been located in the FPGA's SPI
flash memory. See [Troubleshooting](#troubleshooting) for details.

In general navigation is by using the up and down keys to select menu items
and pressing RETURN to select an item. ESCape can be used to exit a menu.

## Mk.2 SYStem ROM slots

On the Mk.2 Blitter when clearing or loading to Map 0 slots 4-7 and the MOS 
slot cannot be written as the motherboard IC's are used. In these cases those
slots will be skipped with a warning. If you need to load an alteranative OS 
ROM (i.e. Tricky's test ROM) then you should use the SWROMX facility to switch
maps to map 1.

## Clear memory

This option can be used to erase the battery backed and Flash EEPROMS should
they become corrupted. You will be asked several questions before being asked
to confirm.

Map 0, 1, B: this indicates which ROM-set is to be erased
(F)lash, (R)am or (B)oth: whether to erase Flash EEPROM or battery backed RAM

Once this has been performed you may need to load a new ROMset for the map(s)
you have just erased.

## Load ROMSET

This option can be used to initialise the Flash and BB ROMs from a pre-baked 
image containing a number of ROMs called a "romset". A romset will usually,
in addition to filing-system and utility ROMs, contain a MOS image which will
be used to initialise the operating system slot.

You will be presented with a list of romsets that are available in the FPGA's
SPI Flash memory as a list. You can select an item from the list by using the
up and down cursor keys and either RETURN to select that image or 'I' to 
inspect the contents of the romset (press ESCape to return to the list of 
romsets).

When you have selected a ROMset to load you will be prompted which map to load
to 0 or 1. 

Note: when loading to a map any ROM slots that are not present in the image
will _not_ be erased, for this reason it is usually wise to used the clear
memory function to clear a map before loading a romset.

## Reboot

This will return you to normal operation. Alternatively a long-break can be
used to reboot normally. 

Note: due to certain limitations in the firmware it is only possible to exit
the preboot menu to T65 mode with Map 0 active. If you wish to switch to another
mode i.e. hard CPU or swap the rom maps then you should exit with a long 
ctrl-break to cause the machine to reset and re-scan the jumpers.

# Preparing you board for Preboot

You FPGA needs to be loaded with a newer (Feb 2026) firmware which has the 
preboot-1 code baked into the FPGA core, you must then also load the preboot-2
program and the romsets to the FPGA's SPI flash memory.

*@AndyC - These instructions have been written for the gowin programmer_cli
utility, mainly because I couldn't get my openFPGAloader to load binary files
to SPI Flash. I'm not sure if that is due to me running on WSL instead of 
true Linux, an outdated openFPGAloader or just that openFPGAloader doesn't
support the Primer 20K! The symptoms are that it starts to program, then 
complains about the Flash being unknown/protected. But it does seem to 
bulk-erase the SPI - rather than just erasing the sectors it needs to. It 
would be good if you could provide any insights!*

*@AndyC - according to Hoglet you may or may not need to add a 
--cable-index 5 argument to all the commands below, or do further fannying 
around to get the Gowin programmer_cli program to work! Let me know how you 
get on!*

The Gowin programmer tool on windows is rather fussy and must be started
either with the current directory set to the programmer\bin directory of the
Gowin tools or with the full path to the tool specified on the command line.
When specifying --fsFile or --mcuFile arguments the full path must be 
specified.

## Flash new firmware to SPI

The files below can all be found in the latest release of the main firmware
[git](https://github.com/dominicbeesley/blitter-vhdl-6502/releases)

### Mk.2 blitter

Use the Altera programming tool to burn the 

### C20K

GoWin:
```
	> [full path to gowin programmer]/programmer_cli --device GW2A-18C --run 36 --fsFile [full path to C20K.fs or C20K816only.fs]
	> [full path to gowin programmer]/programmer_cli --device GW2A-18C --run 32 --spiaddr 0x300000 --mcuFile "[full path...]/preboot2-c20k.bin"
	> [full path to gowin programmer]/programmer_cli --device GW2A-18C --run 32 --spiaddr 0x320000 --mcuFile "[full path...]/romset-c20k.bin"
```

openFPGAloader:
```
	> openFPGALoader --verbose-level 2 --cable ft2232 --write-flash  [full path to C20K.fs or C20K816only.fs]
	> openFPGALoader --verbose-level 2 --cable ft2232 --write-flash -o 0x300000 --bitstream [full path...]/preboot2-c20k.bin
	>openFPGALoader --verbose-level 2 --cable ft2232 --write-flash -o 0x320000 --bitstream [full path...]//romset-c20k.bin
```

NOTE: As of 31/3/2026 both openFPGALoader (running under WSL) and the 
programmer_cli tool fail to program the Primer 20K. For openFPGA loader
there is a well-known "Error: ftdi_read_data in mpsse_read" which still
seems to not be resolved on WSL under Windows. The gowin programmer_cli
fails with "Error: Flsh format error". For this reason under Windows it
is recommended to use the Gowin Windows Programmer app in 
"exFlash C Bin Erase, Program thru GAO-Bridge", being careful to set the
correct SPI base addresses 0x300000 and 0x320000

# Creating Romsets

You may use the [makeromset.pl](../../../scripts/makeromset.pl) script to 
create your own romset binaries that can be loaded to the SPI Flash.

The script takes a text file describing the roms to load, where they are
located on your filing system and which slots they should occupy. An example
script is provided [example-roms-list.romlst](example-roms-list.romlst)

TODO: documentation for creating a .lst file

# Troubleshooting

The preboot ROM may not boot it:
 - the SPI Flash is locked by other software
 - you have an older firmware before mid-Feb 2026
 - the SPI Flash image has been corrupted
 - you have not correctly loaded the preboot-2 image to the SPI Flash

In the first case a full power-cycle can sometimes clear the problem.

If you have an older firmware or you wish to update the preboot-2 image or
romsets then follow the [Preparing for preboot](#preparing-for-preboot)
instructions.

The Caps and Shift-lock LEDs can be used to check the preboot process.


On a ctrl-backspace-break: the shift-lock LED should illuminate for 
around 1/4s and then both Caps and Shift-lock should go out before the
pre-boot menu appears. If the caps-lock LED also flashes for 1/4 second
then that indicates that the preboot2 image was not found or had a bad
checksum follow the instructions above to prime the FPGA for preboot again.

# Technical notes

## Memory usage

### Preboot-1

3 bytes of zero page at FD-FF are corrupted in the system memory area plus
a number of bytes at the top of page 1. It is intended that there be a 
reserved area to save/restore these locations. On 6502 based systems it is
expected that these locations will be intialised by the operating system.

If preboot-2 is to be entered then the memory used by preboot-2 will be 
overwritten by the load routine.

### Preboot-2

The MOSRAM (shadow MOS) of bank 0 is used to host the PREBOOT-2 image along
the whole of main-memory. These are effectively corrupted if the 
ctrl-delete-break key sequence is used. For this reason preboot-2 is 
always exited with a hard-reset (by clearing the IER of the system VIA) which
will force the MOS to do a cold-restart.

## Registers used

TBC


## Debugging

### Notes

Command line to map usb devices to WSL:
	
	usbipd list
	usbipd attach --wsl --busid=6-2
	usbipd detach --busid

Command line to load to SPI flash:

	c:\Gowin\Gowin_V1.9.12_x64\Programmer\bin\programmer_cli.exe --device GW2A-18C --run 39 --spiaddr 0x300000 --mcuFile c:\Users\domin\OneDrive\Documents\GitHub\blitter-65xx-code\build\roms\preboot\preboot2-c20k\preboot2-c20k.bin


TODO:
 - make preboot-1 image deploy from code project to vhdl proj instead of hard-coded paths in c20k.vhd, c20k816only.vhd
 - make preboot-1 preserve ZP, STACK data areas when not booting
 - make an "exit-preboot" register to release hard cpu from reset and/or suspect t65