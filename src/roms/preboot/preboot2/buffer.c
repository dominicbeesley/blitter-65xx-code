
#include "buffer.h"

struct s_buffer {
	unsigned char len;
	unsigned char read_ix;
	unsigned char write_ix;
	char *buf;
};

char key_buf[9];
char sound_buf[9];

struct s_buffer BUFS[] = {
	{ 8, 0, 0, key_buf},
	{ 8, 0, 0, sound_buf}
};

// Empty slot for full case, make thread safe, add updates write_ix, get update read_ix

buffer_ret buffer_add(int buffer, char c) {
	struct s_buffer *b;
	unsigned char newix;

	b = &BUFS[buffer];

	newix = b->write_ix + 1;
	while (newix >= b->len)
		newix -= b->len;

	if (newix != b->read_ix) {
		b->buf[newix] = c;
		b->write_ix = newix;
		return BUFRET_OK;
	} else
		return BUFRET_FULL;

}

buffer_ret buffer_count(int buffer) {
	struct s_buffer *b;
	int c;

	b = &BUFS[buffer];

	c = b->write_ix - b->read_ix;
	while (c < 0)
		c += b->len;

	return c;
}

buffer_ret buffer_get(int buffer, char *c) {
	struct s_buffer *b;
	unsigned char newix;
	unsigned char ret;

	b = &BUFS[buffer];

	if (b->write_ix != b->read_ix) {
		newix = b->read_ix;
		newix++;
		while (newix >= b->len)
			newix -= b->len;
		*c = b->buf[newix];
		b->read_ix = newix;
		return BUFRET_OK;
	} else
		return BUFRET_EOF;

}
