#include <stdarg.h>
#include "hardware.h"
#include "hw.h"
#include "doprnt.h"


int debug_putc(int dev, int c) {

	static unsigned int ctr;
	static int inhibit;

#ifdef C20K
	while (peek(debug_UART_status) & DBUG_UART_STAT_TXF)	
		;
	poke(debug_UART_data, c);

#endif

#ifndef C20K
	ctr = 0;	
	while (!(peek(sheila_ACIA_CTL) & ACIA_TDRE))
	{
		if (inhibit)
			return c;
		ctr++;
		if (ctr > 60000)
			inhibit = 1;
	}
	inhibit = 0;

	poke(sheila_ACIA_DATA, c);

#endif
	
	return c;
}


int	debug_printf(
	  char		*fmt,		/* format string		*/
	  ...
	) {
	int ret;
    va_list ap;
    va_start(ap, fmt);
    ret = _doprnt(fmt, ap, &debug_putc, 0);
    va_end(ap);

    return ret;
}
