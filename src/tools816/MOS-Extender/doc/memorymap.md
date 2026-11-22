
# MOS Extender Memory Map

```

                    Emulation Mode                     Native Mode

Log     Phys                                                 
0000    00 0000 +---------------------------------------------------------+     00 0000
                | Shared MOS Zero Page                                    | 
0100    00 0100 +---------------------------------------------------------+     00 0100
                | EMU only Stack                                          |
0200    00 0200 +---------------------------------------------------------+     00 0200
                | Shared MOS System Variables                             |
0300    00 0300 +---------------------------------------------------------+     00 0300
                | Shared VDU Variables                                    | 
0380    00 0380 +---------------------------------------------------------+     00 0380
                | Reserved / CFS / RFS                                    |
0400    00 0400 +---------------------------------------------------------+     00 0400
                | BBC MOS / EMU Language dependent                        |
0800    00 0800 +---------------------------------------------------------+     00 0800
                | Shared SOUND (printer buffer moved?)                    | 
0A00    00 0A00 +---------------------------------------------------------+     00 0A00
                | EMU Transient command buffer                            |
0B00    00 0B00 +---------------------------------------------------------+     00 0B00
                | Soft key buffers                                        |
0C00    00 0C00 +---------------------------------------------------------+     00 0C00
                | Character definitions 128-159                           | 
0D00    00 0D00 +---------------------------------------------------------+     00 0D00
                | EMU NMI / Econet / Ext vectors / ROM private pointers   |
0E00    00 0E00 +---------------------------------------------------------+     00 0E00
                |      ROM workspace or Language reserved for 8-bit       |
1000    FF 1000 +                          +----+-------------------------+     00 1000 
                B                          B    |                         |
                B      ROM workspace       B    |  BLTURBO Lxx reserved   |
1900 (PAGE)     B--------------------------B    |                         |
                B  MOS-EXT loader/emu code B    |                         |
                B  (MAIN, 1900-21FF)       B    |                         |
2200            B--------------------------B    |                         |
                B  MOS-EXT native handlers B    |                         |
                B  (NATH, run at FF 2200)  B    |                         |
2D00            B--------------------------B    |                         |
                B  MOS-EXT BSS             B    |                         |
                B  (emu_err_buf etc.)      B    |                         |
3000            B--------------------------B    |                         |
         HIMEM  B                          B    |                         |
                B      Screen Memory       B    |                         |
                B                          B    |                         |
                B                          B    |                         |
8000    XX XXXX +--------------------------+    +-------------------------+     00 8000
                S                          S    | BLTUTIL workspace       |
                S      Paged ROMs          S    +-------------------------+     00 8C00
                S                          S    | MOS Extender native     |
                S                          S    | workspace (NATV)        |
                S                          S    |   8C00-8DDF             |
                S                          S    +-------------------------+     00 8FE0
                S                          S    | 816 native vectors      |
                S                          S    +-------------------------+     00 9000
                S                          S    |                         |
                S                          S    |                         |     
                S                          S    |    FREE [1]             |
                S                          S    |                         |
                S                          S    |                         |
                S                          S    |-------------------------|     00 A000 ?
                S                          S    | Native stack (grows     |
                S                          S    |   down from 00 AFFF)    |
                S                          S    |-------------------------|     00 B000
                S                          S    |                         |
                S                          S    |    FREE [1]             |     
                S                          S    |                         |
C000    FF C000 +--------------------------+----+-------------------------|     00 C000
                M                                                         |
                M      MOS ROM              HAZEL (BBC B/Elk)             |
                M                                                         |
E000    FF E000 M                          M    +-------------------------|     00 E000
                M                          M    |                         |
                M      MOS ROM             M    |    FREE [1]             |
                M                          M    |                         |
FC00    FF FC00 +--------------------------+    |                         |
          FRED  h                          h    |                         |
FD00    FF FD00 h                          h    |                         |
           JIM  h  Hardware registers      h    |                         |
FE00    FF FE00 h                          h    |                         |
        SHEILA  h                          h    |                         |
FF00    FF FF00 +--------------------------+    +-------------------------+
                M  EMU Ext vector entry    M    | Reserved                |
                M  points and HW vectors   M    | HW vector copy @ 00 FFE0|
                +--------------------------+    +-------------------------+     01 0000
                                                |                         |
                                                |     FREE [2]            |
                                                |                         |
                                                +-------------------------+ HEAPBOT
                                                |                         |
                                                |   BLTUTIL heap          |
                                                |                         |
                                                +-------------------------+ HEAPTOP
                                                |XXXXXXXXXXXXXXXXXXXXXXXXX|
                                                |XXXXXXX RESERVED XXXXXXXX|
                                                |XXXXXXXXXXXXXXXXXXXXXXXXX|
                                                +-------------------------+     FE FC00
                                                | Chipset registers       |
                                                +-------------------------+     FE FD00
                                                |XXXXXXX RESERVED XXXXXXXX|  undefined
                                                +-------------------------+     FF 0000
                                                |                         |
                                                | Mirror of emu bank 0    |
                                                |  (BBC motherboard RAM)  |
                                                |  FF 2200-FF 2CFF:       |
                                                |  MOS-EXT native handlers|
                                                |  (NATH)                 |
                                                +-------------------------+     


```

FREE [1] - this is B0 memory to be allocated by API - currently BASIC, test, 
advent816 use this freely

FREE [2] - this is ChipRAM to be allocated by API currently just assume we can
go up to a reasonable limit