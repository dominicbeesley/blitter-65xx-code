#!/usr/bin/env python3
#(-*- coding: utf-8 -*-)

# MIT License
# 
# Copyright (c) 2023 Dossytronics
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
import xml.etree.ElementTree as ET
import base64

def Usage(fh = sys.stderr, message = None, ex = None, exit = 0):
	if message is not None:
		print(message, file=fh)
		print(file=fh)

	if ex is not None:
		print(ex, file=fh)
		print(file=fh)

	print("""USAGE: bsprcvt.py <.bspr in> <symprefix> <out.bin> <out.bas>

 Convert a .bspr to a binary file suitable for ModelC sprites and output 
 .bas text file containing variable defs
""", file=fh)
	if exit != 0:
		sys.exit(exit)


def main():

	b16 = 0;

	i = 1;
	while i < len(sys.argv) and sys.argv[i].startswith("-"):
		match argv[i]:
			case "-16":
				b16 = 1
			case _:
				raise f"Bad switch {argv[i]}"
		i = i + 1

	if len(sys.argv) != i + 4:
		Usage(sys.stdout, "Incorrect number of arguments", exit=1)

	fn_in = sys.argv[i+0]
	sym_pre = sys.argv[i+1]
	fn_bin = sys.argv[i+2]
	fn_bas = sys.argv[i+3]

	try:
		d = ET.parse(fn_in)
	except Exception as ex:
		Usage(message=f"Error opening file {fn_in}", ex=ex, exit=2)

	rt = d.getroot()

	if rt.tag != "SpriteSheet":
		Usage(message=f"Bad xml input - incorrect root tag \"{rt.tag}\"", exit=3)

	mode = rt.attrib["Mode"]
	bin_offs = 0;

	if mode == "2" or mode == "Sprite16":
		b16 = 1

	with open(fn_bin, 'wb') as f_bin:
		with open(fn_bas, 'w') as f_bbc:
			for xS in rt.findall("*//Sprite"):
				sprname = xS.attrib["Name"]
				sprw = int(xS.attrib["Width"])
				if (sprw != 16):
					raise Exception(f"Bad width on {sprname} {sprw}!=16")
				sprh = int(xS.attrib["Height"])
 
				f_bbc.write(f"{sym_pre}{sprname}_O={bin_offs}\n")
				
				xBitmap = xS.find("Bitmap")
				if xBitmap is None:
					raise("No bitmap")

				px = base64.b64decode(xBitmap.text)

				for j in range(sprh):
					pixel32 = 0
					ww = max(sprw,16)
					for i in range(ww):
						pixel32 = pixel32 << 2 | px[i+j*sprw] & 3
					pixel32 << 2*(16-sprw)

					f_bin.write(pixel32.to_bytes(4, 'big'))

				bin_offs += sprh*4

				if b16:

					f_bbc.write(f"{sym_pre}{sprname}_O16={bin_offs}\n")
					
					for j in range(sprh):
						pixel32 = 0
						ww = max(sprw,16)
						for i in range(ww):
							pixel32 = pixel32 << 2 | ((px[i+j*sprw] & 0xC) >> 2)
						pixel32 << 2*(16-sprw)

						f_bin.write(pixel32.to_bytes(4, 'big'))

					bin_offs += sprh*4


main()