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
const struct os_error *err;

int open(const char *name) {
	int f = 0xA5;
	err = os_find_open(name, 0x40, &f);
	if (err) {
		printf ("ERROR opening %s: %lx, %s\n", name, err->errcode, err->errmsg);
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
		gblk.rw.data = (void *)(0xFF8000L-800L);
		gblk.rw.count = 800;
		err = os_gbpb(4, &gblk);

		if (err) {
			printf("GBPB ERR: %lx %s\n", (long)err->errcode, err->errmsg);
		}

		printf("RET: %lX %lX %lX\n", (long)gblk.rw.data, gblk.rw.count, gblk.rw.offset);

		os_find_close(f);
	}


	struct os_file_blk fblk;

	//try at specified address
	fblk.filename = "7.TEST";
	fblk.exec = 0;
	fblk.load = (void *)0xFF7B00;
	err = os_file(0xFF, &fblk);
	if (err) {
		printf("OSFILE ERR: %lx %s\n", (long)err->errcode, err->errmsg);
	}

	//try at address in attributes
	fblk.filename = "7.TEST";
	fblk.exec = 0xFF;
	fblk.load = 0x;
	err = os_file(0xFF, &fblk);
	if (err) {
		printf("OSFILE ERR: %lx %s\n", (long)err->errcode, err->errmsg);
		return;
	}

	printf("RET: %lX %lX %lX %lX\n", (long)fblk.load, (long)fblk.exec, (long)fblk.length, (long)fblk.attributes);

	return 0;
}