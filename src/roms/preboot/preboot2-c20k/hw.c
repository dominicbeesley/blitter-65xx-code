#include <6502.h>
#include "hardware.h"
#include "hw.h"

#define IRQ_STACK_SIZE 0x400
char IRQ_STACK[IRQ_STACK_SIZE];

void poke(unsigned int a, unsigned char v) {
	*((unsigned char *)a) = v;
}

unsigned char peek(unsigned int a) {
	return *((unsigned char *)a);
}

unsigned char hw_interrupt(void) {
	(*((char *)0x7C4F))++;
	poke(sheila_SYSVIA_ifr, 0x7F);
	return 1;
}

#define PER_1CS 10000

void hw_init(void) {

	//setup timer 1 for 100Hz

	poke(sheila_SYSVIA_acr, VIA_ACR_T1_CONT);
	poke(sheila_SYSVIA_t1ll, (PER_1CS - 2) & 0xFF);
	poke(sheila_SYSVIA_t1lh, (PER_1CS - 2) >> 8);
	poke(sheila_SYSVIA_t1ch, (PER_1CS - 2) >> 8);

	poke(sheila_SYSVIA_ier, VIA_IFR_BIT_ANY|VIA_IFR_BIT_T1);

	set_irq(&hw_interrupt, &IRQ_STACK[0], IRQ_STACK_SIZE);
}