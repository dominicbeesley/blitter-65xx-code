#!/usr/bin/env python3
#(-*- coding: utf-8 -*-)

# MIT License
# 
# Copyright (c) 2026 Dossytronics
# https://github.com/dominicbeesley/blitter-65xx-code
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# TileCutter a script to cut up a larger tile image into a set of images 
# suitable for plotting on a BBC Micro in 4-bpp mode.

import sys
import os

def Usage(fh = sys.stderr, message = None, ex = None, exit = 0):
    if message is not None:
        print(message, file=fh)
        print(file=fh)

    if ex is not None:
        print(ex, file=fh)
        print(file=fh)

    print("""USAGE: ml2nula <mlt file> <beeb bin file>

Convert a Spectrum .mlt file suitable to load into a Beeb's memory at 5800""", file=fh)

    if exit != 0:
        sys.exit(exit)


def main():
    if len(sys.argv) != 3:
        Usage(sys.stdout, "Incorrect number of arguments", exit=1)

    mltfilepath = sys.argv[1]
    binfilepath = sys.argv[2]

    try:
        f = open(mltfilepath, 'rb')
    except OSError as ex:
        Usage(message = f"Could not open/read file: {mltfilepath}", ex = ex, exit = 1)
        sys.exit()

    mltraw=None

    with f: 
        mltraw = f.read(0x3000);
        if len(mltraw) != 0x3000:
            Usage(message = f"Not and mlt file must be 0x3000 bytes long")
    mltraw = list(mltraw)

    try:
        fo = open(binfilepath, 'wb')
    except OSError as ex:
        Usage(message = f"Could not open/write file: {binfilepath}", ex = ex, exit = 2)
        sys.exit()

    attroff=32*24*8
    atts=[0] * 8
    px=[0] * 8
    with fo:
        for cr in range(24):
            for col in range(32):
                for pr in range(8):
                    sy = cr*8+pr
                    sx = col
                    addr = (sx & 0x1F) | ((sy & 0x7) << 8) | ((sy & 0x38) << 2) | ((sy & 0xC0) << 5)
                    addra = attroff + sx + sy*32
                    if sx < 32:
                        atts[pr] = mltraw[addra]
                        px[pr] = mltraw[addr]
                        
                    else:
                        atts[pr] = 0
                        px[pr] = 0
                fo.write(bytes(atts))
                fo.write(bytes(px))


main()