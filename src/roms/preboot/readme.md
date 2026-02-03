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
with slot #E sideways RAM slot. These are effectively corrupted if the 
ctrl-delete-break key sequence is used. The main system memory and screen
memory will be corrupted and preboot-2 is usually exited with a hard-reset
(by clearing the IER of the system VIA).


## Registers used

TBC


## Debugging

### Notes

Command line to map usb devices to WSL:
	
	usbipd list
	usbipd attach --wsl --busid=6-2
	usbipd detach --busid

Command line to load to SPI flash:

	c:\Gowin\Gowin_V1.9.12_x64\Programmer\bin\programmer_cli.exe --device GW2A-18C --run 39 --spiaddr 0x700000 --mcuFile c:\Users\domin\OneDrive\Documents\GitHub\blitter-65xx-code\build\roms\preboot\preboot2-c20k\preboot2-c20k.bin

