#include "screenmaths.h"

uint16_t XY_to_dma_scr_adr16(int16_t x, int16_t y) {

	uint16_t p2 = (y & 7) | ((uint16_t)(y & 0xFFF8) * 0x50);
	return p2 + ((uint16_t)(x & 0xFFFE) * 4);

	return 0;
}