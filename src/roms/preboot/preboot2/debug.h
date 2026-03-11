#ifndef __DEBUG_H__
#define __DEBUG_H__

extern void debug_putc(char c);

extern int	debug_printf(
	  char		*fmt,		/* format string		*/
	  ...
	);

#endif