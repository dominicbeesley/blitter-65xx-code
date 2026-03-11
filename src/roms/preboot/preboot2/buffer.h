#ifndef __BUFFER_H__
#define __BUFFER_H__

#define BUFFER_COUNT 	2
#define BUFFER_KEYBOARD 0
#define BUFFER_SOUND	1

typedef int buffer_ret;
#define BUFRET_OK   0
#define BUFRET_EOF 	-1
#define BUFRET_FULL -1

extern buffer_ret buffer_add(int buffer, char c);
extern buffer_ret buffer_count(int buffer);
extern buffer_ret buffer_get(int buffer, char *c);

#endif