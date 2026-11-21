typedef unsigned char byte;

struct osword_timer_block
   {  byte b [5];
   }; 

struct os_error {
	long errcode;
	char errmsg[251];
};

union os_gbpb_blk {
	 struct rw {
		int handle;
		void *data;
		unsigned long count;
		unsigned long offset;
	} rw;
};

struct os_file_blk {
	const char *filename;
	void *load;
	void *exec;
	long length;
	long attributes;
};

typedef struct os_error os_error;
typedef struct osword_timer_block osword_timer_block;
typedef union os_gbpb_blk os_gbpb_blk;
typedef struct os_file_blk os_file_blk;

extern const os_error *xos_wrch(char c);
extern const os_error *xos_newl();
extern const os_error *xos_writes(const char *c);
extern const os_error *xos_word(byte op, void *block);
extern const os_error *xos_find_open(const char *c, byte mode, int *handle);
extern const os_error *xos_find_close(int handle);
extern const os_error *xos_bget(int handle, int *ret);
extern const os_error *xos_bput(int handle, byte b);
extern const os_error *xos_gbpb(byte funcode, os_gbpb_blk *blk);
extern const os_error *xos_file(byte funtion, os_file_blk *blk);
