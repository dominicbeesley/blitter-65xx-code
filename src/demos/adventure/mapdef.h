#ifndef __MAPDEF_H__
#define __MAPDEF_H__

// mapdef is the mapdef data as stored in the maps database

struct mapdef;

typedef struct mapdef_object_teleport {
	struct mapdef *map;
	unsigned char dest_x;
	unsigned char dest_y;
} mapdef_object_teleport_t;

typedef union mapdef_object_data {
	mapdef_object_teleport_t teleport;
} mapdef_object_data_u;

typedef struct mapdef_object {
	unsigned char type;
	unsigned char x;
	unsigned char y;
	mapdef_object_data_u data;
} mapdef_object_t;

#define MAPDEF_OBJ_MAX 8
#define MAPDEF_OBJ_TYPE_TELEPORT 1

typedef struct mapdef {
	unsigned int binary_offs;
	unsigned char width;
	unsigned char height;
	struct mapdef *north;
	struct mapdef *south;
	struct mapdef *east;
	struct mapdef *west;
	mapdef_object_t objects[MAPDEF_OBJ_MAX];
} mapdef_t;

#endif

