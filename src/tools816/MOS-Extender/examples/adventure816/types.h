#ifndef __TYPES_H__
#define __TYPES_H__

#include <stdint.h>

#define LPTR void*

#define BOOL uint8_t
#define TRUE 1
#define FALSE 0

#define XSTR(x) #x
#define STR(x)  XSTR(x)

#define DECL_WR8(name, addr) \
        void name(__reg("a") unsigned char v) = \
        "\tsep\t#32\n\tsta\t>" STR(addr) "\n\trep\t#32";
#define DECL_WR16(name, addr) \
        void name(__reg("a") unsigned short v) = "\tsta\t>" STR(addr);
#define DECL_WR32(name, addr) \
        void name(__reg("a/x") unsigned long v) = \
        "\tsta\t>" STR(addr) "\n" \
        "\tpha\n\ttxa\n\tsta\t>" STR(addr) "+2\n\tpla";
#define DECL_WR24(name, addr) \
        void name(__reg("a/x") unsigned long v) = \
        "\tsta\t>" STR(addr) "\n" \
        "\tpha\n\ttxa\n\tsep\t#$20\n\tsta\t>" STR(addr) "+2\n\trep\t#$20\n\tpla";



#define DECL_RD8(name, addr) \
        unsigned char name(void) = "\tsep\t#32\n\tlda\t>" STR(addr) "\n\trep\t#32";
#define DECL_RD16(name, addr) \
        unsigned short name(void) = "\tlda\t>" STR(addr);
#define DECL_RD32(name, addr) \
        unsigned long name(void) = \
        "\tlda\t>" STR(addr) "+2\n\ttax\n\tlda\t>" STR(addr);

#endif