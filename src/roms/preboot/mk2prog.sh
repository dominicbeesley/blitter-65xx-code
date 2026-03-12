#/usr/bin/env bash
# Build the preboot-2 and romset and program to an attached mk.2 board

QUARTUS_SH=quartus_sh.exe
QUARTUS_MAP=quartus_map.exe
QUARTUS_FIT=quartus_fit.exe
QUARTUS_ASM=quartus_asm.exe
QUARTUS_PGM=quartus_pgm.exe
QUARTUS_CPF=quartus_cpf.exe


SCRIPTS=../../../scripts/
BUILD=../../../build/roms/preboot/
BUILDP2=$BUILD/preboot2/mk2

set -e

make all
$SCRIPTS/makeromset.pl example-roms-list-mk2.romlst $BUILD/romset.bin

srec_cat -Output $BUILD/romset.hex -Intel $BUILD/romset.bin -Binary
srec_cat -Output $BUILDP2/preboot2.hex -Intel $BUILDP2/preboot2.bin -Binary

$QUARTUS_CPF -c mk2_conv.cof
$QUARTUS_PGM --no_banner --mode=jtag -o "IP;$BUILD/mk2-image.jic"
