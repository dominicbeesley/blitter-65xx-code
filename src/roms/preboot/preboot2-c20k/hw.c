#include "hw.h"

void poke(unsigned int a, unsigned char v) {
	*((unsigned char *)a) = v;
}

unsigned char peek(unsigned int a) {
	return *((unsigned char *)a);
}

