#include <stdio.h>
#include <oslib/os.h>
#include <oslib/osfile.h>
#include "myos.h"

#include "gen_vars.h"

#include "hardware.h"
#include "globals.h"
#include "dma.h"

unsigned char i,j;

void main(void) {

	//naughty - set jim devno but don't save old
	*((unsigned char *)0xEE) = JIM_DEVNO_BLITTER;
	*((unsigned char *)fred_JIM_DEVNO) = JIM_DEVNO_BLITTER;
	*((unsigned char *)fred_JIM_PAGE_LO) = jim_page_CHIPSET & 0xFF;
	*((unsigned char *)fred_JIM_PAGE_HI) = jim_page_CHIPSET >> 8;


//	OSWRCH(22);
//	OSWRCH(7);

	OSWRCH(22);
	OSWRCH(2);

	//reset nula
	*((volatile char *)SHEILA_NULA_CTLAUX) = 0x40;

	for (i = 0; i < 31; i++) {
		OSWRCH(17);
		OSWRCH(128+(i & 15));
		for (j = 0; j < 20; j++) {
			OSWRCH(17);
			OSWRCH(j & 15);
			OSWRCH(65+j);
		}
	}

	osfile_load("B.RAIN", (unsigned char *)0x3C80, NULL, NULL, NULL, NULL);


}
