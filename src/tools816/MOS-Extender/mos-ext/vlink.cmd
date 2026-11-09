MEMSTART = 0x10000;
STACKLEN = 0x400;
RAMSIZE = 0x200000;

MEMORY
{
 zero : org = 0x00 , len = 0x80
 ram: org = 0x2000, len = 0x1000
}

SECTIONS
{
  zpage (NOLOAD) : {*(zpage) *(zp1) *(zp2)} >zero

  _text = .;
  start : { *(*text.startup)} >ram
  text:   { *(*.text*)} >ram
  ndata : { *(*data*) *(*.near.*) *(*_bss.*) } >ram

  bss (NOLOAD):    { *(*bss*)} >ram
}
