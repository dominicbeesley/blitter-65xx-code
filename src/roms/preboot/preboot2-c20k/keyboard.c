#include "hardware.h"
#include "hw.h"


unsigned char keyboard_pressed(unsigned char code) {

	unsigned char P, ret;

	P = intoff();

	poke(sheila_SYSVIA_orb, 3);		//stop auto-scan
	poke(sheila_SYSVIA_ddra, 0x7F); //bit 7 in, others out
	poke(sheila_SYSVIA_ora_nh, code);
	ret = peek(sheila_SYSVIA_ora_nh) & 0x80;

	intrestore(P);

	return ret;
}

void _autoscan(void) {
	poke(sheila_SYSVIA_ifr, VIA_IFR_BIT_CA2);	// cancel keyboard interrupt
	poke(sheila_SYSVIA_orb, 0xB);				// start-scan	
}

unsigned char keyboard_scan_int(unsigned char mincode, unsigned char ignorecode) {
	signed char curcode = 0x09;
	signed char curcode2;
	
	do {
		//quickly find column
		poke(sheila_SYSVIA_ddra, 0x7F);				// slow bus all output except 7
		poke(sheila_SYSVIA_orb, 0x3);				// stop auto-scan
		poke(sheila_SYSVIA_ora_nh, 0xF); 			// non exist column
		poke(sheila_SYSVIA_ifr, VIA_IFR_BIT_CA2);	// cancel keyboard interrupt
		poke(sheila_SYSVIA_ora_nh, curcode);		// current column/row
		if (peek(sheila_SYSVIA_ifr) & VIA_IFR_BIT_CA2) {
			// got column
			curcode2 = curcode;
			do {
				if (curcode2 >= mincode)
				{
					poke(sheila_SYSVIA_ora_nh, curcode2);
					curcode2 = peek(sheila_SYSVIA_ora_nh);
					if (curcode2 < 0 && (ignorecode == 0 || ignorecode != curcode2))
						return curcode2;
				}
				curcode2 += 0x10;
			} while (curcode2 >= 0);
		}

		// next column
		curcode --;
	} while (curcode >= 0);

	return 0;
}

unsigned char keyboard_scan(unsigned char mincode) {
	return keyboard_scan_int(mincode, 0xFF);
}
