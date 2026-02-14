#ifndef __APPS_H__
#define __APPS_H__



struct mmi;

extern const ui_app app_romset;
//extern const ui_app app_romset_list;
extern const ui_app app_main_menu;

struct ui_app_inst;

struct app_main_menu_mmi {
	const char *label;
	struct ui_app_inst *app;
};

struct app_main_menu_data {
	const struct app_main_menu_mmi *items;
	int item_count;
};

struct app_clearbb_data {
	unsigned char ui_state;
	unsigned char map;
	unsigned char flash;
};

struct app_romset_data {
	unsigned char ui_state;
	unsigned char romset_ix;
	unsigned char map;
};


extern const ui_app app_reboot;
extern const ui_app app_clearbb;


#endif;