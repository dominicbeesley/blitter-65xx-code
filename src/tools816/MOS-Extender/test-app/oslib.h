typedef unsigned char byte;

struct osword_timer_block
   {  byte b [5];
   }; 


extern void os_wrch(char c);
extern void os_newl();
extern void os_writes(const char *c);
extern void os_word(byte op, void *block);
extern const char *os_find_open(const char *c, byte mode, int *handle);
extern const char *os_find_close(int handle);
extern int os_bget(int handle);
extern void os_bput(int handle, byte b);

union os_gbpb_blk {
	 struct rw {
		byte handle;
		void *data;
		unsigned long count;
		unsigned long offset;
	} rw;
};

extern void os_gbpb(byte funcode, struct os_gbpbp_blk *blk);
