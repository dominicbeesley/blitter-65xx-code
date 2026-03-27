char hex_nyb(unsigned char x) {
	x = x & 0xF;
	if (x < 10)
		return '0' + x;
	else
		return 'A' + x - 10;
}

char * hex_str(char *buf, unsigned char w, unsigned long n) {
	unsigned char i = w;
	while (i > 0) {
		i--;
		buf[i] = hex_nyb(n);
		n = n >> 4;
	}

	return buf + w;
}
