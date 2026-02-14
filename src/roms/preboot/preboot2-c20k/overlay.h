#ifndef __OVERLAY_H__
#define __OVERLAY_H__

#define APP_OVERLAY_SPI_BASE 0x704000
#define APP_OVERLAY_MEM 0x8000
#define APP_OVERLAY_SIZE 0x4000


extern void overlay_init();

extern void overlay_ensure(int ix);


#endif