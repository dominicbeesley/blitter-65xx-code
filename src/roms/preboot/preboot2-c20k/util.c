#include <stdarg.h>
#include "doprnt.h"
#include "debug.h"

int sputc(int dev, int c) {

	char **p = (char **)dev;
	*((*p)++)=c;
	return c;
}


int	sprintf(
	char *buffer,
	char *fmt,		/* format string		*/
	  ...
	) {
	char *p = buffer;
	int ret;
    va_list ap;
    va_start(ap, fmt);
    ret = _doprnt(fmt, ap, &sputc, (int)&p);
    va_end(ap);

	*p = 0;

    return ret++;
}
