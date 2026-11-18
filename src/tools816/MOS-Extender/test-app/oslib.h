extern void os_wrch(char c);
extern void os_newl();
extern void os_writes(const char *c);
extern void os_word(unsigned char op, void *block);
extern const char *os_find_open(const char *c, unsigned char mode, int *handle);
extern const char *os_find_close(int handle);
extern int os_bget(int handle);
extern void os_bput(int handle, unsigned char b);

struct os_gbpb_blk {
	union rw {
		unsigned char handle;
		void *data;
		unsigned long count;
		unsigned long offset;
	}
}

extern void os_gbpb(unsigned char funcode, struct os_gbpbp_blk *blk);
