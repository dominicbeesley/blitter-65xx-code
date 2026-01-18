#ifndef __HW_H__
#define __HW_H__

extern void poke(unsigned int a, unsigned char v);

extern unsigned char peek(unsigned int a);

extern unsigned char intoff();

extern void intrestore(unsigned char P);

extern void hw_init(void);

#endif