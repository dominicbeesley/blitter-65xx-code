#include <6502.h>
#include "types.h"
#include "hardware.h"
#include "hw.h"

#define IRQ_STACK_SIZE 0x400
char IRQ_STACK[IRQ_STACK_SIZE];

unsigned long time = 0;

void poke(unsigned int a, unsigned char v) {
	*((unsigned char *)a) = v;
}

unsigned char peek(unsigned int a) {
	return *((unsigned char *)a);
}

unsigned long get_time(void) {
	char P = intoff();
	unsigned long ret = time;
	intrestore(P);
	return ret;
}

extern void keyb_irq_t1(void);
extern void keyb_irq_ca2(void);
extern bool keyb_key_down;
unsigned char hw_interrupt(void) {

	unsigned char b;

	b = peek(sheila_SYSVIA_ifr);
	if (b & VIA_IFR_BIT_ANY)
	{
		b = b & ~ VIA_IFR_BIT_ANY;

		if (b & VIA_IFR_BIT_T1)
		{
			time++;
			if (!(peek(sheila_SYSVIA_ier) & VIA_IFR_BIT_CA2))
				keyb_irq_t1();
		}

		if (b & VIA_IFR_BIT_CA2)
			keyb_irq_ca2();

		poke (sheila_SYSVIA_ifr, b);
	}


	return 1;
}


void hw_init(void) {

	//setup timer 1 for 100Hz

	set_irq(&hw_interrupt, &IRQ_STACK[0], IRQ_STACK_SIZE);
}