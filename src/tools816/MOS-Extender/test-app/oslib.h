typedef unsigned char byte;

struct osword_timer_block
   {  byte b [5];
   }; 


struct os_error {
	long errcode;
	char errmsg[251];
};

extern void os_wrch(char c);
extern void os_newl();
extern void os_writes(const char *c);
extern void os_word(byte op, void *block);
extern const struct os_error *os_find_open(const char *c, byte mode, int *handle);
extern const struct os_error *os_find_close(int handle);
extern int os_bget(int handle);
extern void os_bput(int handle, byte b);

union os_gbpb_blk {
	 struct rw {
		int handle;
		void *data;
		unsigned long count;
		unsigned long offset;
	} rw;
};

extern const struct os_error *os_gbpb(byte funcode, union os_gbpb_blk *blk);


struct os_file_blk {
	const char *filename;
	void *load;
	void *exec;
	long length;
	long attributes;
};

extern const struct os_error *os_file(byte funtion, struct os_file_blk *blk);
