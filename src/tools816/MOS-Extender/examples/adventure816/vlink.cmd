MEMSTART = 0x10000;
STACKLEN = 0x400;
RAMSIZE = 0x100000;

MEMORY
{
 zero : org = 0x1000 , len = 128
 ram: org = 0x10000, len = 0x0F0000
}

SECTIONS
{
  zpage (NOLOAD) : {*(zpage) *(zp1) *(zp2)} >zero

  _text = .;
  start : {*(*_text.startup)} >ram
  ndata : { *(*data.near.*) *(*.near.*) } >ram
  _nbss = .;
  nbss : { *(*_bss.*) } >ram
  _nebss = .;

  constr : {*(.dtors) *(.ctors)} >ram

  far1 (BANKSIZE=65536) : { *(SORT_BY_SIZE(*text* *_rodata.far.*))} >ram
  _etext = .;
  _data = .;
  far2 (BANKSIZE=65536) : { *(SORT_BY_SIZE(*_data.far.* *.far.*))} >ram
  huge : { 
    *(*data.*) 
  _edata = .;
  _bss = .;
    *(*bss*) 
  _ebss = .;
  } >ram

  ___heap = ADDR(huge) + SIZEOF(huge);
  _end = ___heap;
  ___heapend = RAMSIZE;
  _heapend = ___heapend;
  __DBR_init = ADDR(ndata);
}
