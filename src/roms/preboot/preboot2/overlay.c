#include "overlay.h"
#include "ui.h"
#include "spi.h"
#include "util.h"

extern char buf[];

int overlay_cur_ix;

void overlay_init() {
	overlay_cur_ix = -1;
}

void overlay_ensure(int ix)
{
	unsigned char cksum;
	unsigned char *p;


	if (overlay_cur_ix != ix) {
		set_status("loading...");
		spi_read_buf(
			(void *)APP_OVERLAY_MEM, 
			(unsigned long)APP_OVERLAY_SPI_BASE + (unsigned long)ix*(long)APP_OVERLAY_SIZE,
			APP_OVERLAY_SIZE
			);

		//checksum check
		cksum = 0;
		for (p = (char *)0x8000; p < (char *)0xC000; p++)
			cksum += *p;
		if (cksum != 0)
		{
			sprintf(buf, "Bad CKSUM %X : %02X", 
				(long)ix, 
				(long)cksum);
			set_status(buf);
			overlay_cur_ix = -1;
			return;
		}

		overlay_cur_ix = ix;
	}
}