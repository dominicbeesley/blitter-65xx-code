#include "hardware.h"
#include "hw.h"
#include "buffer.h"

void _keyb_autoscan(unsigned char on) {
	poke(sheila_SYSVIA_orb, on?0xB:0x3);		// start-scan	
	poke(sheila_SYSVIA_ifr, VIA_IFR_BIT_CA2);	// cancel keyboard interrupt
}

unsigned char keyb_check_pressed(unsigned char code) {

	unsigned char P, ret;

	P = intoff();

	poke(sheila_SYSVIA_orb, 3);		//stop auto-scan
	poke(sheila_SYSVIA_ddra, 0x7F); //bit 7 in, others out
	poke(sheila_SYSVIA_ora_nh, code);
	ret = peek(sheila_SYSVIA_ora_nh) & 0x80;
	_keyb_autoscan(peek(sheila_SYSVIA_ier) & VIA_IFR_BIT_CA2);

	intrestore(P);

	return ret;
}

unsigned char key_scan_int(unsigned char mincode, unsigned char ignorecode) {
	signed char curcode = 0x09;
	signed char curcode2;
	
	do {
		//quickly find column
		poke(sheila_SYSVIA_ddra, 0x7F);				// slow bus all output except 7
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
					{
						return curcode2;
					}
				}
				curcode2 += 0x10;
			} while (curcode2 >= 0);
		}

		// next column
		curcode --;
	} while (curcode >= 0);

	return 0;
}

unsigned char keyb_scan(unsigned char mincode) {
	unsigned char P, ret;
	P = intoff();
	_keyb_autoscan(0);
	ret = key_scan_int(mincode, 0xFF);
	_keyb_autoscan(peek(sheila_SYSVIA_ier) & VIA_IFR_BIT_CA2);
	intrestore(P);
	return ret;
}

extern char KEYBOARD_TRANS_TABLE[];

unsigned char keyb_code2ascii(unsigned char code, unsigned char flags) {
	unsigned char ret;
	ret = KEYBOARD_TRANS_TABLE[(code - 0x10) & 0x7F];
	if (ret & 0x80 && (ret & 0x0F) >= 0xC) {
		//TODO: palaver copied from MOS - maybe just change table?
		ret = (ret & 0xF) + 0x7C;
	}
	return ret;
}

void keyb_init() {
	poke(sheila_SYSVIA_ier, VIA_IFR_BIT_ANY|VIA_IFR_BIT_CA2);
	_keyb_autoscan(1);
}

void keyb_irq_ca2() {
	unsigned char kc, ka;
	// had a key-down irq, disable scan
	poke(sheila_SYSVIA_ier, VIA_IFR_BIT_CA2);
	_keyb_autoscan(0);

	kc = keyb_scan(0x10);

	if (ka)
	{
		ka = keyb_code2ascii(kc, 0);
		buffer_add(BUFFER_KEYBOARD, ka);
	}
}

void keyb_irq_t1() {
	unsigned char kc;
	kc = keyb_scan(0x10);
	if (!kc) {
		poke(sheila_SYSVIA_ier, VIA_IFR_BIT_ANY|VIA_IFR_BIT_CA2);
		_keyb_autoscan(1);
	}
}