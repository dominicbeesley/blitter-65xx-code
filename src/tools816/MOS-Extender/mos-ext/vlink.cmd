MEMSTART = 0x10000;
STACKLEN = 0x400;
RAMSIZE = 0x200000;

MEMORY
{
 zero : org = 0x80 , len = 0x0A
 ram: org = 0x2000, len = 0x1000
 FFram: org = 0xFF2000, len = 0x1000
 natv: org = 0x8C00, len = 0x01E0
}

SECTIONS
{
  zpage (NOLOAD) : {*(zpage) *(zp1) *(zp2)} >zero

  _text = .;
  start : { *(*text.startup)} >ram
  text:   { *(*.text*)} >ram
  ndata : { *(*data*) *(*.near.*) *(*rodata*) } >ram
_nat_wksp_start = .;
  vdata : { *(*nat_wksp_text) } >natv AT>ram 
  /* a dummy to reset to >ram numbering */
  vv :  {} >ram     
_nat_wksp_end = .;
_nat_wksp_len = _nat_wksp_end - _nat_wksp_start;
  
  bob = .;

  fftext 0xFF0000 + bob : { 
    *(*nat_handler_text) 
  } >FFram AT>ram 


  bss (NOLOAD):    { *(*bss*)} >ram
}
