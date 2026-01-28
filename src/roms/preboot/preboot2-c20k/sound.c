#include "sound.h"


void sound_init(void) {
	//shut up
	sound_poke(0x9F);
	sound_poke(0xBF);
	sound_poke(0xDF);
	sound_poke(0xFF);
}