	#include <stdlib.h>
	#include <stdio.h>


extern void os_wrch(char c);
extern void os_newl();
extern void os_writes(const char *c);
extern void os_word(unsigned char op, void *block);

size_t __write(int h, const char *p, size_t l) {
	int i = 0;
	while (i < l) {
		os_wrch(*p++);
		i++;
	}
	return i;
}

typedef unsigned char byte;

struct osword_timer_block
   {  byte b [5];
   }; 

struct osword_timer_block b;

int main(void) {
	
	long l;

	b.b[4] = 4;

	os_wrch('h');

	os_newl();

	for (int i = 0; i < 10; i++) {
		os_writes("Big fat pants");
		os_newl();
	}

	for (int i = 0; i < 10000; i++) {

		os_word(1, &b);

		l = *(long *)&b.b;

		printf("DOG %ld\r\n", l);
	}
}