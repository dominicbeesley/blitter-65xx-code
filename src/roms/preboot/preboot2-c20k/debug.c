#include <stdarg.h>
#include "hardware.h"
#include "hw.h"
#include "doprnt.h"

int debug_putc(int dev, int c) {
	while (peek(debug_UART_status) & DBUG_UART_STAT_TXF)	
		;
	poke(debug_UART_data, c);

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
