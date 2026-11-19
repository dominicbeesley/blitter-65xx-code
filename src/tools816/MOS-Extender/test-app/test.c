	#include <stdlib.h>
	#include <stdio.h>
	#include "oslib.h"


size_t __write(int h, const char *p, size_t l) {
        size_t i = 0;
        while (i < l) {
                char c = *p++;
                if (c == '\n')
                        os_newl();
                else
                        os_wrch(c);
                i++;
        }
        return i;
}

struct osword_timer_block b;

int open(const char *name) {
	int f = 0xA5;
	const char *err;
	err = os_find_open(name, 0x40, &f);
	if (err) {
		printf ("ERROR opening %s: %s\n", name, (err)?err:"NULL");
		return -1;
	} 
	else
		return f;
}

void dump(const char *name) {

	int f = open(name);
	if (f < 0)
		return;

	printf("Here comes %s\n", name);

	for (int i = 0; i < 8; i++) {
		int x = os_bget(f);
		if (x < 0)
			break;
		printf("%02X ", x);
	}
	printf ("\n");

	os_find_close(f);
}

int main(void) {
	
	long l;

	b.b[4] = 4;

	// mode 7
	os_wrch(22);
	os_wrch(7);

	os_wrch('h');

	os_newl();

	for (int i = 0; i < 5; i++) {
		os_writes("Big fat pants");
		os_newl();
	}

	for (int i = 0; i < 5; i++) {

		os_word(1, &b);

		l = *(long *)&b.b;

		printf("DOG %ld\n", l);
	}


	dump("BOB");
	dump("TEST");

	//load test file at FF7C00
	union os_gbpb_blk gblk;
	int f = open("7.TEST");
	if (f > 0) {
		gblk.rw.handle = f;
		gblk.rw.data = (void *)0xFF7C00;
		gblk.rw.count = 800;
		os_gbpb(4, &gblk);

		printf("RET: %lX %lX %lX\n", gblk.rw.data, gblk.rw.count, gblk.rw.offset);

		os_find_close(f);
	}


	
}