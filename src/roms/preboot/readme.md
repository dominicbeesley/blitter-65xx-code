# PREBOOT

## Introduction

A need has been identified to have an easy de-bricking system, especially for 
the C20K which cannot be easily be bootstrapped: the Blitter boards can be
fired up from the motherboard MOS/BASIC/BLTUTIL rom slots if the ROM images
become corrupted, but all MOS/ROMS on the C20K are hosted in the Flash EEPROM
which can easily be overwritten by the user.

The preboot system can provided a complex software ecosystem by including a small
<512 bytes ROM baked into the firmware that bootstraps another larger software
which is loaded from the FPGA configuration SPI Flash EEPROM or FPGA UFM.

## Preboot-1

This is a tiny ROM that is substituted for the main ROM at boot time. It checks
that there is a special keypress (CRTL-DELETE-BREAK) and if so then copies the
preboot-2 program into the sideways-mos area for map 0 and, if the checksum is
valid, boots that image. The data for the preboot-2 image are stored in the 
FPGA's SPI flash memory at a set location (board dependent).

## Preboot-2

The implements a menu-based system to allow the user to perform a reset of the
ROM images (amongst other things) and then reboot the system.

The preboot-2 may load further data and program overlays from the SPI flash as
it is running.

## Debugging

### Notes

Command line to map usb devices to WSL:
	
	usbipd list
	usbipd attach --wsl --busid=6-2
	usbipd detach --busid

Command line to load to SPI flash:

	c:\Gowin\Gowin_V1.9.12_x64\Programmer\bin\programmer_cli.exe --device GW2A-18C --run 39 --spiaddr 0x700000 --mcuFile c:\Users\domin\OneDrive\Documents\GitHub\blitter-65xx-code\build\roms\preboot\preboot2-c20k\preboot2-c20k.bin

