#ifndef __MAPDEF_H__
#define __MAPDEF_H__

// mapdef is the mapdef data as stored in the maps database

typedef struct mapdef {
	unsigned int binary_offs;
	unsigned char width;
	unsigned char height;
} mapdef_t;

#endif

