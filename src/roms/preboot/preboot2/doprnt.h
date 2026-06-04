#ifndef __DPRNT_H__
#define __DPRNT_H__

int	_doprnt(
	  char		*fmt,			/* format string	*/
	  va_list	ap,			/* ap list of values	*/
	  int		(*func)(int, int),	/* char output function	*/
	  int		farg			/* arg for char output	*/
	);

#endif