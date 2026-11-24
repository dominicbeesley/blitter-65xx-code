# MOS-Extender native API

This document describes the COP calls a native 65816 program uses to call
the MOS-Extender. It is a first cut of the new conventions. 

## Calling a COP

A call is a `COP` instruction followed by its signature byte, the call
number:

```
        cop     COP_00_OPWRC
```

Calls may be made, with any register sizes. The caller's M and X sizes are 
restored on return. 

The dispatcher always reads A, X and Y as 16-bit values. If .i8 or .a8 mode is
in force (X=1 or M=1) then the following notes should be considered.
- **A with 8-bit accumulator:** the hidden high byte (`xba`) must be set
  wherever a call uses the full 16 bits of A (pointers). However, it
  can be left unset for 8-bit A calls (such as OSBYTE)
- **X with 8-bit index registers:** fine for X:A pointers. The CPU forces
  the high byte of X to 0, which is the required top byte.
- **Y with 8-bit index registers:** fine for reason codes and other
  8-bit values. 16-bit handles above 255 in Y need 16-bit index
  registers.

COP calls may be made from emulation mode but it should be noted that all COPs
unless otherwise noted will treat memory layout as per native mode mapping.

## Registers are preserved

A call changes only the registers it lists as outputs. A, X, Y, D, B and
the flags other than C and V are returned unchanged, even when the
descriptions below don't say so.

## Pointers to blocks: X:A

Addresses of control blocks or name strings are 32-bit values passed in X:A:
- A = bits 0-15;
- X = bits 16-31: the low byte of X is the bank, the high byte of X must
  be 0.

Within control blocks addresses are 4 bytes, little-endian. The data bank
register (B) is not used to pass addresses.

## Handles and reason codes
- **Handles are 16 bits.** Calls that pass a control block take the handle
  in the block. Calls without a block take it in Y.
- **Reason codes.** A call with several functions takes the reason code in
  Y. OSBYTE is the exception: it keeps the 8-bit MOS registers (A = reason,
  X and Y = parameters).

## 8-bit function codes

Where a function code is passed in Y and is interpreted as 8-bits the caller
should ensure that the MSB is 0. Care should be taken when doing TAY if H might
be non-zero.

## Errors

V is the error flag:

| Exit | Meaning                                                      |
|------|--------------------------------------------------------------|
| V=0  | the call succeeded                                           |
| V=1  | the call failed; X:A points to an error block                |

- **C is not an error flag.** Where a call documents C it is a result or an
  indication, such as end of file in BGET, Escape in OSWORD 0, or the OSBYTE
  C result. Otherwise C is preserved.
- **Other outputs on error:** when V=1 the other outputs of the call are
  undefined.
- **Error block:** read-only, and valid only until the next COP call. Copy
  it if it is needed later.
- **COP numbers or reason codes that aren't implemented** return V=1 with a
  "Not implemented" error.
- **Only an error-returning form exists at present.** There is no
  error-raising form (as with RISC OS SWIs without the X bit).

### Error blocks

| Offset | Size     | Contents                               |
|--------|----------|----------------------------------------|
| +0     | 4 bytes  | error number, low byte first           |
| +4     | n bytes  | message, terminated by &00             |

A block is at most 256 bytes long.

### Error numbers

These follow the RISC OS rules:
- **Bits 0-7:** the basic error number.
- **&00000000-&000000FF:** BBC/MOS-compatible errors. An error from the
  8-bit MOS or a filing system (a BRK) is returned with its 1-byte number
  zero-extended, e.g. &000000D6 "File not found".
- **Bits 8-23:** identify the source of the error (an OS area, a module, a
  filing system).
- **Bit 31:** a serious error or exception that could not be returned in
  the usual way.
- **Bit 30:** always 0 in a system error. Programs may use it to flag
  their own internal errors.
- **Bits 24-29:** reserved, 0.

The MOS-Extender's own error numbers (e.g. "Not implemented") are still to
be allocated.

## Calls that pass a control block

- **On entry:** X:A points to the block and Y holds the reason code. Any
  handle goes in the block.
- **On success:** X:A is preserved and the block holds the results.
- **On error:** V=1 and X:A points to the error block, so it no longer
  points to the control block. Keep a copy of the block pointer if you
  need it after an error. The control block may have been partly updated
  by then, for example when an OSGBPB transfer fails part way through.

## Calls

```
; ********************************************************************************
; * COP 00 - OPWRC - write character                                             *
; *                                                                              *
; * Action: Send the byte in A to the VDU drivers (OSWRCH).                      *
; *                                                                              *
; * On entry: A = character code (low byte)                                      *
; * On exit:  -                                                                  *
; ********************************************************************************
```

```
; ********************************************************************************
; * COP 01 - OPWRS - write string immediate                                      *
; *                                                                              *
; * Action: Write the zero-terminated string that follows the COP signature      *
; * byte. Execution continues after the terminating zero.                        *
; *                                                                              *
; * On entry: inline string, terminated by &00                                   *
; * On exit:  -                                                                  *
; *                                                                              *
; * Example:  cop COP_01_OPWRS                                                   *
; *           .byte "Hello", 13, 10, 0                                           *
; ********************************************************************************
```

```
; ********************************************************************************
; * COP 02 - OPWRA - write string at X:A                                         *
; *                                                                              *
; * Action: Write the string at X:A to the VDU drivers.                          *
; *                                                                              *
; * On entry: X:A = pointer to the string                                        *
; *           Y   = terminator option:                                           *
; *                 0 = terminated by &00                                        *
; *                 2 = terminated by &00 or any control character (< &20)       *
; * On exit:  -                                                                  *
; *                                                                              *
; * Errors:   invalid terminator option                                          *
; ********************************************************************************
```

```
; ********************************************************************************
; * COP 03 - OPNLI - BBC OSNEWL                                                  *
; *                                                                              *
; * Action: Send LF CR (&0A, &0D) to the VDU drivers.                            *
; *                                                                              *
; * On entry: -                                                                  *
; * On exit:  -                                                                  *
; ********************************************************************************
```

```
; ********************************************************************************
; * COP 06 - OPOSB - OSBYTE                                                      *
; *                                                                              *
; * Action: Call the 8-bit MOS OSBYTE. The operation depends on the reason       *
; * code in A. Other data can be passed in X and Y; results are returned in      *
; * X and Y.                                                                     *
; *                                                                              *
; * On entry: A = reason code (8 bits)                                           *
; *           X, Y = parameters (8 bits)                                         *
; * On exit:  X, Y = results, as returned by the MOS (zero-extended to 16        *
; *           bits)                                                              *
; *           C    = as returned by the MOS                                      *
; *                                                                              *
; * Note: A, X and Y keep their 8-bit MOS meanings here; this call does not      *
; * follow the X:A pointer convention.                                           *
; ********************************************************************************
```

```
; ********************************************************************************
; * COP 07 - OPOSW - OSWORD                                                      *
; *                                                                              *
; * Action: Call the 8-bit MOS OSWORD. The operation depends on the reason       *
; * code in Y. The control block is copied to MOS memory, OSWORD is called       *
; * and the results are copied back. The block layouts are those of the          *
; * 8-bit MOS (no handle field).                                                 *
; *                                                                              *
; * On entry: X:A = pointer to the control block                                 *
; *           Y   = reason code (8 bits)                                         *
; * On exit:  block updated with the results                                     *
; *           For Y = 0 (read line): Y = line length (including CR),             *
; *           C = 1 if Escape ended the input                                    *
; *                                                                              *
; * Note (OSWORD 0): the buffer address inside the block is a 16-bit MOS         *
; * address (bank FF, or the shared 00 0000-00 0FFF area). A replacement         *
; * read-line call with a 32-bit buffer is planned (OPRDLN).                     *
; ********************************************************************************
```

```
; ********************************************************************************
; * COP 0A - OPBGT - BGET                                                        *
; *                                                                              *
; * Action: Read one byte from an open file.                                     *
; *                                                                              *
; * On entry: Y = handle (from OPOPN)                                            *
; * On exit:  A = byte read (zero-extended)                                      *
; *           C = 1 if end of file was reached; A is then undefined              *
; *                                                                              *
; * End of file is an indication, not an error (V stays clear).                  *
; ********************************************************************************
```

```
; ********************************************************************************
; * COP 0B - OPBPT - BPUT                                                        *
; *                                                                              *
; * Action: Write one byte to an open file.                                      *
; *                                                                              *
; * On entry: Y = handle (from OPOPN)                                            *
; *           A = byte to write (low byte)                                       *
; * On exit:  -                                                                  *
; ********************************************************************************
```

```
; ********************************************************************************
; * COP 0C - OPFILE - whole-file operations (OSFILE)                             *
; *                                                                              *
; * Action: Whole-file operations, as the 8-bit MOS OSFILE but with 32-bit       *
; * fields. With an 8-bit filing system a load is carried out as                 *
; * OPEN / GBPB / CLOSE operations.                                              *
; *                                                                              *
; * On entry: X:A = pointer to the control block                                 *
; *           Y   = reason code:                                                 *
; *                  - see 8-bit MOS for reasons                                 *
; *                                                                              *
; * Control block:                                                               *
; *    +0   pointer to filename (32 bits), terminated by CR, control             *
; *         character or space                                                   *
; *    +4   load address (32 bits)                                               *
; *    +8   exec address (32 bits)                                               *
; *    +12  length (32 bits)                                                     *
; *    +16  attributes (32 bits)                                                 *
; *                                                                              *
; * On exit:  Y = object type: 0 = not found, 1 = file, 2 = directory            *
; *           block +4..+19 = the object's catalogue information                 *
; *                                                                              *
; * Load (&FF): if the low byte of the exec address (+8) is 0 the file is        *
; * loaded to the address at +4, otherwise to the file's own load address.       *
; * The address is used as a native 32-bit address (bank = byte +6); there       *
; * is no Tube/I/O processor address mapping.                                    *
; *                                                                              *
; * Errors:   &FF on an object that is not a file: &D6 File not found            *
; *           unsupported reason code: Not implemented                           *
; ********************************************************************************
```

```
; ********************************************************************************
; * COP 15 - OPASC - BBC OSASCI                                                  *
; *                                                                              *
; * Action: Send the byte in A to the VDU drivers. If the byte is &0D            *
; * (carriage return) send &0A, &0D (line feed, carriage return) instead.        *
; *                                                                              *
; * On entry: A = character code (low byte)                                      *
; * On exit:  -                                                                  *
; ********************************************************************************
```

```
; ********************************************************************************
; * COP 22 - OPRLN - read line from input                                        *
; *                                                                              *
; * Action: Read a line of characters from the current input stream into a       *
; * buffer, with the usual line editing (DELETE, CTRL-U). Characters outside     *
; * the low..high range are not stored; the bell sounds if the buffer is full.   *
; * The line ends with CR, which is stored in the buffer but not counted.        *
; * (Same purpose as Communicator OPRLN, but a different control block.)         *
; *                                                                              *
; * On entry: X:A = pointer to the control block:                                *
; *             +0  4 bytes  buffer address                                      *
; *             +4  2 bytes  buffer length - 1 = most characters accepted,       *
; *                          not counting the CR (as OS_ReadLine32 R1)           *
; *             +6  1 byte   lowest character accepted                           *
; *             +7  1 byte   highest character accepted                          *
; *             +8  1 byte   password character, echoed instead of each          *
; *                          accepted character when flags bit 6 is set          *
; *             +9  1 byte   flags:                                              *
; *                            bit 7 = don't echo characters that are not        *
; *                                    accepted into the buffer                  *
; *                            bit 6 = echo the password character (+10)         *
; *                            bits 0-5 reserved, 0                              *
; * On exit:  Y   = number of characters read, not counting the CR               *
; *           C   = 0: line read, terminated by CR                               *
; *           C   = 1: ESCape pressed; Y and the buffer hold the line so far.    *
; *                 The caller must acknowledge the escape (OSBYTE &7E)          *
; *           X:A = preserved (control block)                                    *
; *                                                                              *
; * Errors:   none raised by the call itself; V=1 only for errors from the       *
; *           input stream                                                       *
; ********************************************************************************
```

```
; ********************************************************************************
; * COP 26 - OPXHA - address of immediate string                                 *
; *                                                                              *
; * Action: Return the address of the zero-terminated string that follows        *
; * the COP signature byte. Execution continues after the terminating zero.      *
; *                                                                              *
; * On entry: inline string, terminated by &00                                   *
; * On exit:  X:A = pointer to the string                                        *
; ********************************************************************************
```

```
; ********************************************************************************
; * COP 27 - OPBHI - immediate far address                                       *
; *                                                                              *
; * Action: Return the 3-byte address that follows the COP signature byte.       *
; * Execution continues after it.                                                *
; *                                                                              *
; * On entry: inline 24-bit address (low byte first)                             *
; * On exit:  X:A = the address (top byte 0)                                     *
; ********************************************************************************
```

```
; ********************************************************************************
; * COP 44 - OPOPN - open file                                                   *
; *                                                                              *
; * Action: Open a file (OSFIND).                                                *
; *                                                                              *
; * On entry: X:A = pointer to the filename, terminated by CR, control           *
; *                 character or space                                           *
; *           Y   = mode: &40 = input, &80 = output, &C0 = update                *
; * On exit:  Y   = handle (16 bits)                                             *
; *                                                                              *
; * Errors:   filing system errors; the file could not be opened                 *
; ********************************************************************************
```

```
; ********************************************************************************
; * COP 45 - OPCLS - close file                                                  *
; *                                                                              *
; * Action: Close a file opened with OPOPN (OSFIND 0).                           *
; *                                                                              *
; * On entry: Y = handle; Y = 0 closes all open files                            *
; * On exit:  -                                                                  *
; ********************************************************************************
```

```
; ********************************************************************************
; * COP 4C - OPGBPB - multiple byte get/put (OSGBPB)                             *
; *                                                                              *
; * Action: Read or write a block of bytes from/to an open file, as the          *
; * 8-bit MOS OSGBPB but with a 16-bit handle and 32-bit fields. Transfers       *
; * are bounced through a MOS-side buffer in chunks.                             *
; *                                                                              *
; * On entry: X:A = pointer to the control block                                 *
; *           Y   = reason code:                                                 *
; *                 1 = put bytes at the pointer given in the block              *
; *                 2 = put bytes at the current file pointer                    *
; *                 3 = get bytes from the pointer given in the block            *
; *                 4 = get bytes from the current file pointer                  *
; *                                                                              *
; * Control block:                                                               *
; *    +0   handle (16 bits)                                                     *
; *    +2   data address (32 bits)                                               *
; *    +6   number of bytes to transfer (32 bits)                                *
; *    +10  file pointer (32 bits, reasons 1 and 3)                              *
; *                                                                              *
; * On exit:  +2  advanced by the number of bytes transferred                    *
; *           +6  = number of bytes NOT transferred                              *
; *           +10 = the new file pointer                                         *
; *                                                                              *
; * End of file (reasons 3, 4) is not an error: it shows as a non-zero           *
; * count at +6 on exit.                                                         *
; *                                                                              *
; * Errors:   unsupported reason code (0, 5-8): Not implemented                  *
; ********************************************************************************
```
