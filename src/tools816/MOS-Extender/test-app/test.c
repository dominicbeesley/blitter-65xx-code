	#include <stdlib.h>
	#include <stdio.h>


extern void os_wrch(char c);
extern void os_newl();
extern void os_writes(const char *c);
extern void os_word(unsigned char op, void *block);
extern const char *os_find_open(const char *c, unsigned char mode, int *handle);
extern const char *os_find_close(int handle);

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

void dump(const char *name) {
	int f = 0xA5;
	const char *err;
	err = os_find_open(name, 0x40, &f);
	if (err) {
		printf ("ERROR opening %s: %s\r\n", name, (err)?err:"NULL", f);
		return;
	} 

	printf("Here comes %s\r\n", name);



	os_find_close(f);
}

int main(void) {
	
	long l;

	b.b[4] = 4;

	os_wrch('h');

	os_newl();

	for (int i = 0; i < 5; i++) {
		os_writes("Big fat pants");
		os_newl();
	}

	for (int i = 0; i < 5; i++) {

		os_word(1, &b);

		l = *(long *)&b.b;

		printf("DOG %ld\r\n", l);
	}


	dump("BOB");
	dump("TEST");

}