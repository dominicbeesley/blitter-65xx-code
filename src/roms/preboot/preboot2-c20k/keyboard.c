#include "hardware.h"
#include "hw.h"


unsigned char keyboard_scan(unsigned char code) {

	unsigned char P, ret;

	P = intoff();

	poke(sheila_SYSVIA_orb, 3);		//stop auto-scan
	poke(sheila_SYSVIA_ddra, 0x7F); //bit 7 in, others out
	poke(sheila_SYSVIA_ora_nh, code);
	ret = peek(sheila_SYSVIA_ora_nh) & 0x80;

	intrestore(P);

	return ret;
}