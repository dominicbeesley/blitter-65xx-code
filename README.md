# blitter-65xx-code
Support and demo code for the Blitter board in a BBC Micro with a 65xx 
processor. 

# Pre-requisites
The following is a (non-exhasutive) list of pre-requisities for the build 
system.

## dfs-0.4
This tool is used for building .ssd disk images it can be obtained at
https://github.com/dominicbeesley/dfs-0.4 

## cc65 v2.18 edfda72a
This is a special BBC Micro - specific cc65 build it can be obtained at
https://github.com/dominicbeesley/cc65/tree/merge-master-20200427 -
The C projects in this folder also rely on a clib-rom and associated link
library located in the src/clib folder. This is an experimental feature
and requires the clib rom to be loaded into slot #1 as a sideways ROM

    \*SRLOAD R.CLIB 1

The R.CLIB file is included on .ssd images where it is required

## python 3
Python is required by the "adventure" and "bigfonts" game/demo. The 
following python libraries should be installed (using pip)

- pillow - an image processing library (replaces PIL)

## perl
Perl 5 is required with the following libraries:

- XML::LibXML
- Data::Dumper
- Image::PNG::Libpng
- Convert::Color
- Math::Trig
- Getopt::Long

These can be installed using CPAN

## GNU Make
The build system relies on gnu-specific extensions and has been tested
agains make 4.3

# Building

To build all the disk images it should be possible to run

    make ssd

from the /src folder. This will creates a set of folders in /build which
contains the intermediate build files and a folder /build/ssd which contains
the finished disk images

If you run a live filing system it is possible to have the build system
extract the disk images with associated .inf files to a folder

    make deploy

Will extract the programs to ~/hostfs/... with a folder created for each
disk image which may be mounted with a remote filing system or vdfs.

You may run the make process in lower level folders if (re)building specific
projects. In most cases the ssd or deploy targets can be used at the relevant
level to rebuild just that specific disk image.

## make overrides

From the command line it is possible to override the location for the build
and deploy targets:

### BUILD_TOP=
This can be used to specify an alternative build root-directory

i.e.

    ~/b65/src/demos/adventure$ make ssd BUILD_TOP=~/b65_build

would build the programs in ~/b65_build/demos/adventures and place disc images
in ~/b65_build/ssd

### DEPLOY_TOP=
This can be used to specify the root-folder to which the deploy target will
deliver files.

i.e.

    ~/b65/src/demos/adventure$ make ssd DEPLOY_TOP=~/beeblink/volumes

would extract the final ssds to the folder ~/beeblink/volumes/advent65




