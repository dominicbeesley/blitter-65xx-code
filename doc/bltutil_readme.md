This Document contains an overview of the functions provided on the Blitter and Paula hardware by the BLTUTIL rom
=================================================================================================================


ChipRAM memory map 
------------------

ChipRAM can be accessed using the FRED/JIM paging mechanism on all processors or 
directly by processors that support >64k addressing i.e. 65816, 68008


        00 0000         +-----------------------+----+
                        | BLTURBO shadow memory | B  |see BLTURBO command
        00 8000         +-----------------------+----+
                        | BLUTILS ROM workspace | BP |see below
        00 C000         +-----------------------+----+
                        | BBC B/Elk "Hazel"     | B  |  see HAZEL
        01 0000         +-----------------------+----+
                        |                       |    |
                        | User memory           | BP |
                        |                       |    |
        HEAPBOT         +-----------------------+----+  see HEAP OSWORD, ...
                        |                       |    |
                        | Memory heap           | BP |  Used by various commands 
        HEAPTOP         |                       |    |       to load data
        1C 0000 (B)     +-----------------------+----+  see HEAP OSWORD, ...    
        08 0000 (P)     |                       |    |
                        | SWRAM                 | B  |  
                        |                       |    |  
        20 0000 (B)     +-----------------------+----+
                        |                       |    |
                        | RAM repeats           | B  |
                        |                       |    |  
        80 0000 (B)     +-----------------------+----+
                        |                       |    |
                        | Flash ROM             | B  |
                        |                       |    |  
        90 0000 (B)     +-----------------------+----+
                        |                       |    |
                        | Flash repeats         | B  |
                        |                       |    |  
        FE 0000 (BP)    +-----------------------+----+
                        | BLANK                 |    |
        FE FC00 (B)     +-----------------------+----+
                        | Chipset registers     | BP |
        FE FD00 (B)     +-----------------------+----+  
                        | BLANK                 |    |
        FF 0000 (B)     +-----------------------+----+  
                        + BBC Micro main board  | B  |
                        +-----------------------+----+



TODO: Add info on VERSION banks and repeating chipset/version


ROM Workspace 
=============

        00 8000..3      CHECKSUM                        ; reserved for checksum
        00 8004..5      HEAPTOP         (pages)         ; memory limit
        00 8006..7      HEAPBOT         (pages)         ; user memory top
        00 8008..9      HEAPLIM         (pages)         ; lower limit for heap
        00 800A..B      HEAPFREE        (pages)         ; first free heap block 


SOUND sample pointer table
--------------------------

        00 8100..1      Sample 0 start page number
        00 8102..3      Sample 0 length bytes
        00 8104..5      Sample 0 repeat offset bytes
        00 8006         -
        00 8107         Sample 0 flags
                        - $80 present i.e. if not set there's nothing loaded here                       
        ...above repeats for 31 samples
        00 81FF

SOUND workspace PAGE
--------------------

        00 8300         SOUND Enabled
        00 8301         --- spare ---
        00 8302         old INSV
        00 8304         old REMV
        00 8306         old CPNV
        00 8308         old BYTEV

        --- see bltutil.inc TODO: update here when bltutil.inc settled --



SOUND buffers
-------------

        00 8400..A7     SOUND BUFFERS

65816 native vectors
--------------------
        When the 65816 is in native mode, the boot flag is set and a vector pull occurs
        it is fetched from 008Fxx. This can be used to add native vectors when running
        an unmodified MOS

HEAP BLOCK
==========

The topmost page of the heap area is reserved to contain heap allocation table entries:
        Blitter=1DFF00, Paula=07FF00

The allocation table is a single page of 64 entries each entry is
        +0      16bit   PageNum
        +2      16bit   Flags | Number of pages
                Flags are in top two bits of Number of pages
        $80     Entry is used
        $40     Entry is a free "hole" in the map
        



\*COMMANDS
=========

\*ROMS [V][A][C][I][X|0|1] (Blitter only)
-----------------------------------------

Show a list of ROMs

V - Verbose
A - All - show all ROMs including those not 
    recognised or ignored by the OS
C - CRC calculate a CRC for each ROM
I - Ignore the memory inhibit jumper
X - Show alternate ROM set
0 - Show ROM set 0
1 - Show ROM set 1

ROM sets: there are two ROM sets, usually set 0, including the motherboard 
          ROMs at 4..7 is accessed by the T65 core. Set 1 is usually made
          available to the hard processor. This can be swapped by the SWROMx
          jumper.

\*SRCOPY <dest> <src> (Blitter only)
---------------------

Copy from one ROM slot to another

\*SRNUKE (Blitter only)
--------

The SRNUKE utility. This allows erasing of ROMs or clearing of the entire
Flash ROM in case of crashes at boot time this can be invoked by holding then
"£" key at boot.

\*SRERASE <id> [F][I][X|0|1\] (Blitter only)
---------------------------

F - force (ignore any errors)
I - ignore memory inhibit
X - use alternate ROM set
0 - use ROM set 0
1 - use ROM set 1

\*SRLOAD <filename> <id> [I][X|0|1\] (Blitter only)
---------------------------------

F - force (ignore any errors)
I - ignore memory inhibit
X - use alternate ROM set
0 - use ROM set 0
1 - use ROM set 1

\*XMDUMP [-8|-16] [\#<dev>] <start> <end>|+<len>
-----------------------------------------------

-8      Force 8 columns output
-16     Force 16 columns output
\#<dev> Specify device number (Blitter=&D1, Paula=&D0)
        If no device number is specified Blitter/Paula will be selected if present
<start> Start address in JIM memory
<end>   End address
+<len>  Show <len> bytes

\*NOICE [ON|OFF] (Blitter only)
----------------

Enable NoIce Debugging

\*NOICEBRK (Blitter only)
----------

Enter noice debugger by executing a breakpoint instruction

\*BLTURBO [M[-]] [L<pagemask>] [?] (Blitter only)
----------------------------------

M/M-    Enable/Disable MOS at maximum speed
L00-LFF The number following L forms a bit mask of pages in RAM that are TURBO'd

BLTURBO copies the contents of memory to Chip RAM and causes the CPU to execute from Chip RAM for these pages.
Care should be taken as any writes to the screen memory area will be intercepted. This operates much like
the \*SHADOW command except it can be tuned on a page by page basis.

i.e. BLTURBO L03 will cause pages 0 and 1 (zero page and stack) to be executed from Chip RAM

The format of this command's arguments is likely to change in future to allow:
- speed throttling of ROM's/MOS
- speed throttling of shadow memory


\*BLSOUND [ON|OFF|DETUNE]
-------------------------

Enables the Blitter/Paula OSWORD7/BASIC extensions to run. Various operating system vectors are trapped
and the User VIA's timer 1 is used

The command must be used *before* any of the \*BLSAMLD, \*BLSAMMAP and extended SOUND commands are used

NOTE: as of July 2020, the ON/OFF/DETUNE options do nothing, a BREAK or CTL-BREAK will clear the sample
table and heap. In future releases this will change.

\*BLHINF [V]
------------

Show HEAP information

V - Verbose, prints a list of allocations on the heap

\*BLSAMLD <filename> <SN> [reploffs]
------------------------------------

SN      - sample slot number in hex 0..1F
reploffs- repeat offset in hex, the sample will repeat continuously from this point to its end once it has reached its end

Loads a sample (max. size 64k) into a sample slot. First if there is already a sample in this slot it will be freed from
the heap then the file will be checked for size and a new allocation made on the heap if possible and the sample will be 
loaded.

The sound system expects samples for instruments to be recorded at middle C at a sample rate of 8372 which for a middle
C note should repeat every 32 samples at the fundamental middle C frequency making it easy to specify repeat offsets.

It is often worthwhile for bass instruments to sample at a double sample rate and add 48 (an octave) to the SOUND pitch
to avoid aliasing.

\*BLSAMMAP <CH> <SN>
--------------------

CH      Channel number 0..7
SN      Sample number 0..1F (hex)

Set the default sample number for each channel. If no sample number is specified in the high byte of the volume SOUND
parameter then the default specified here will be used.

\*BLSAMCLR [<SN>|\*]
--------------------

Clear a sample (or all samples) and free the memory from the heap.


OSWORDS
=======


OSWORD 7: SOUND
---------------
        The MOS OSWORD/BASIC SOUND command is extended as follows:
        Channels between &4000 - &5FFF are intercepted by the blitter sound i.e. add &4000 to normal sound command
        Channels 0..7 are allowed hardware dependent whether 4 or 8 channels are supported
                        where an unsupported channel is used it will not play but will be queued
                        as per usual.
        A sample number can be passed in the high byte of Volume so for full volume, sample #2 pass
                        &02F1 as the volume
        If no sample number is passed (i.e. the top byte of volume is 00 or FF then the sample number as mapped
                        with the \*BLSAMMAP command will be used)
        Sync can be 0..7 instead of 0..3


OSWORD 99: BLTUTILS
-------------------

All BLTUTILs control and memory OSWORDs are through a single OSWORD $99 operation codes for different functions
are passed in offset 2 of the memory block:

        A=&99
        +0      Input parameter length
        +1      Output parameter length 
        +2      OP or rom number if < 16

OSWORD 99, OP < 16 Get ROM/SWRAM ChipRAM base address (Blitter only)
------------------------------------------

This call returns the base address of the given ROM in chip RAM

Input
        +2      rom #
        +3      flags

Input Flags:
        &80     current rom set         The currently in-use rom set will be returned, other wise the map indicate by bit 0
        &40     alternate rom set       The alternate rom set will be returned use with &80, this will return alternate
        &20     ignore mem inhibit      Even if the blitter roms are inhibited this will return the blitter address
        &01     force map 1             Return map 1 regardless off current set

Output
        +2      Return flags
        +3..4   Chipram page # of rom base

Return Flags
        &80     Is in flash rom
        &40     Is in a system socket or blitter inhibited or not present
        &20     Blitter has been inhibited
        &02     Is in current ROM set
        &01     Map 1


If the blitter is not present or inhibited (and ignore mem inhibit flag is not set) then the page returned will
be &FF80 and the sys flag will be set


OSWORD 99, OP=&10 Allocate Chip RAM from Heap
---------------------------------------------

Allocate a block of memory from the heap. Blocks are always allocated as a whole number of pages.

First any previously freed memory will be searched for the smallest block that is large enough to fulfil the request. If no matching block is found then the heap will try to extend downwards, if there is not room then the call will fail and return $FFFF. The current implementation allows a maximum of 64 blocks on the heap.

Input
        +3..4   Number of pages to allocate
Output
        +3..4   Page number of memory block or $FFFF for fail

The call may fail if there is not enough free space or the Blitter or Paula can't be found or a zero length block is requested.


OSWORD 99, OP=&11 Free a block of memory
----------------------------------------

A previously allocated block will be freed. The block will be returned either to the list of free blocks or merged with
any neighbouring blocks. If the block is at the bottom of the heap the heap will close up.

Input
        +3..4   Page number of the block to free.

---move this to a general discussion of the heap
This call will attempt to allocate a block of memory on the heap. The heap is limited to 64 blocks of memory but
can allocate any size block that will fit in memory between the low heap limit and the top of memory.

By default the heap can grow all the way down to the top of the 

OSWORD 99, OP=&12 Set HEAPBOT (not yet implemented)
-----------------------------

The heap grows downwards from the upper limit (Blitter=1DFFFF, Paul=07FFFF) towards HEAPBOT (default 010000)
This call can be used to set HEAPBOT, if HEAPBOT cannot be moved (i.e. < 01000 or > hardware limit or clashes
with already allocated heap an error will be indicated in the return value)

Input
        +3..4   new value for HEAPBOT
Output
        +3      0 for success, -ve for error


OSWORD 99, OP=&13 Read/Write i2c
--------------------------------

This call can be used to do writes, reads or combined write followed by reads to/from and attached i2c device

```
        + 3     Number of bytes to write
        + 4     Number of bytes to read
        + 5     i2c Device address
        + 6..   Write/read data
```

The maximum number of bytes that may be read or written is limited to 127

If there is a read following a write and any of the write bytes are not acked by the device or any other the read will be skipped.
The number of bytes written and ack'd will be be subtracted from +3 i.e. +3=0 indicates all written
The number of byte read back into the buffer will be subtracked from +4 i.e. +4=0 indicates all read

The device address at +5 lowest bit will be set to 1 if the device did not acknowledge the address select

If both the number of bytes to read and write are zero then a device select will still be performed and the low bit of the device address at +5 updated. This can be used as a device probe

## i2c CMOS RAM allocations

The mk.2 and mk.3 Blitter boards both contain an i2c EEPROM which may be used for storing configuration data the table below outlines the ranges that have been pre-allocated to the firmware and ranges which may be used freely for end-user applications.

The mk.2 and mk.3 EEPROMs are 64kbit devices with device number A0 the addresses below are in bytes.

### CMOS ranges

| Address       | Description
|---------------|-------------------------------------------------------------
| 0000-0FFF     | User applications, please update this document with details
| 1000-10FF     | OSBYTE A1/A2 - for the Model B / Electron the BLTUTIL rom provides an OSBYTE A1,A2
| 1100-11FF     | BLTUTILs firmware (see table below)
| 1200-1FFF     | Reserved please do not use

### BLTUTIL ROM CMOS usage

| Address       | Description
|---------------|-------------------------------------------------------------
| 1100-1101     | Per-rom Throttle setting, 1 bit for each ROM, set #0 (reversed sense i.e. 0 = throttle)
| 1102-1103     | Per-rom Throttle setting, 1 bit for each ROM, set #1 (reversed sense i.e. 0 = throttle)
| 1104-1105     | Default Turbo/Throttle settings for map 0/1


#### 1104/5 Default Turbo / Throttle settings

| Bit   | Descriptions
|-------|-----------------------------------------------------
| 7     | Throttle CPU (for 65xx) to 2MHz
| 6..0  | Future use, default to '1' if unsure
