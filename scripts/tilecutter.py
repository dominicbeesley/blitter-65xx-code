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
from PIL import Image
from PIL import ImageColor

def Usage(fh = sys.stderr, message = None, ex = None, exit = 0):
    if message is not None:
        print(message, file=fh)
        print(file=fh)

    if ex is not None:
        print(ex, file=fh)
        print(file=fh)

    print("""USAGE: TileCutter <xml def file>

Slice a bitmap up into game tiles""", file=fh)

    if exit != 0:
        sys.exit(exit)

def main():
    if len(sys.argv) != 3 and len(sys.argv) != 4:
        Usage(sys.stdout, "Incorrect number of arguments", exit=1)

    basefile = sys.argv[1]
    if len(sys.argv) == 4:
        basedir = sys.argv[3]
    else:
        basedir = os.path.dirname(basefile)
    sourcedir = sys.argv[2]

    os.path.isdir(sourcedir) or Usage(sys.stderr, f"Source directory \"{sourcedir}\" does not exist", exit=1)

    try:
        d = ET.parse(basefile)
    except Exception as ex:
        Usage(message=f"Error opening file {basefile}", ex=ex, exit=2)


    pal = []
    for i in range(16):    
        if i == 8:
            r = g = b = 128
        else:
            lvl = 127 if i <= 7 else 255
            r = lvl if i & 1 else 0
            g = lvl if i & 2 else 0
            b = lvl if i & 4 else 0
        pal.append((r, g, b))


    bm = None

    xPal = d.find("palette")

    if xPal is not None:
        i = 0
        for xpe in xPal.findall("ent"):
            if i >= 16:
                Usage(sys.stderr, "Too many palette entries", exit=2)
            pal[i] = ImageColor.getrgb(xpe.text)
            i+=1

        if i < 16:
            Usage(sys.stderr, "Too few palette entries", exit=2)

        palFile = os.path.join(basedir,xPal.attrib["file"])

        try:
            palFH=open(palFile, "wb")
        except Exception as ex:
            Usage(message=f"Error opening palette file \"{palFile}\" for output", ex=ex, exit=2)

        with palFH:
            for i in range(16):
                palFH.write(bytes([(i << 4) + (pal[i][0] >> 4), (pal[i][1] & 0xF0) | (pal[i][2]>>4)]))


    for xDf in d.findall("dest"):
        destFileName = xDf.attrib["file"]

        print(f"DEST:{destFileName}")


        szX = int(xDf.attrib.get("size-x") or "16")
        szY = int(xDf.attrib.get("size-y") or "16")
        mask = (xDf.attrib.get("mask") or "").lower().startswith("y");
        imgno = 0;
        destFullName = os.path.join(basedir, destFileName)

        cuts = ET.Element("cuts")

        cuts.set("size-x", str(szX))
        cuts.set("size-y", str(szY))
        cuts.set("mask", "y" if mask else "n")

        try:
            destFH = open(destFullName, "wb")
        except Exception as ex:
            Usage(sys.stderr, f"Cannot open \"{destFullName}\" for output", ex=ex, exit=2)

        with destFH:
            bm=None
            bmpData=None
            bmpWidth=-1
            bmpHeight=-1
            curX=0
            curY=0
            tileIx=0
            try:
                for xe in xDf.findall("*"):
                    if xe.tag == "source":
                        sourceFileName = xe.attrib["file"]
                        sourceFullName = os.path.join(sourcedir, sourceFileName);

                        print(f"SOURCE:{sourceFileName}")

                        if bm is not None:
                            bm.close
                            bm=None

                        try:
                            bm = Image.open(sourceFullName)
                        except Exception as ex:
                            Usage(sys.stderr, f"Cannot open source image file \"{sourceFullName}\" for input", ex=ex, exit=2)

                        bmpWidth = bm.width;
                        bmpHeight = bm.height;
                        if bm.mode != "RGB":
                            bm = bm.convert("RGBA")
                        pixels = bm.load()

                        xdSource = ET.SubElement(cuts, "source")
                        xdSource.set("size-x", str(bmpWidth));
                        xdSource.set("size-y", str(bmpHeight));
                        xdSource.set("filename", sourceFileName);

                        # pixels16 contains palette indexes
                        pixels16 = bmpTo16(pixels, bmpWidth, bmpHeight, pal, mask)

                    elif xe.tag == "move":
                        curX = int(xe.attrib["x"])
                        curY = int(xe.attrib["y"])
                    elif xe.tag == "cut":
                        pixels16 is not None or Usage(sys.stderr, "Error: cut before source", exit=4)

                        nX = int(xe.attrib["x"])
                        nY = int(xe.attrib["y"])
                        cutDir = xe.attrib["dir"]

                        cutDir == "rd" or Usage(sys.stderr, f"Bad direction \"{cutDir}\" only (rd) supported")
                        
                        for j in range(nY):
                            for i in range(nX):
                                tileIx = DoCut(destFH, pixels16, bmpWidth, bmpHeight, szX, szY, curX + szX * i, curY + szY * j, mask, tileIx, cuts)

            finally:
                if bm is not None:
                    bm.close
            cuts_doc = ET.ElementTree(cuts)
            cuts_doc.write(destFullName + ".cuts", encoding="UTF-8", xml_declaration=True)

def bmpTo16(pixels, width, height, pal, mask):
    """Make a 4bpp bitmap, 0x80 for transparent bits"""    
    pr = []
    for y in range(height):
        prr = [0] * width
        for x in range(width):
            c = pixels[x,y]
            ix = nearestInPal(pal, c, mask)
            prr[x] = ix
        pr.append(prr)
    return pr


def nearestInPal(pal, c, mask):
    """find nearest colour"""
    if mask and c[3] < 128:
        return 0x80
    ix = 0
    min = -1;
    for i in range(16):
        pr, pg, pb = toRGB(pal[i])
        r, g, b = toRGB(c)
        err = sq(r - pr) + sq(g - pg) + sq(b - pb)

        if min < 0 or err < min:
            min = err
            ix = i
    return ix
        
def sq(x):
    return x*x

def toRGB(c):
    return (c[0],c[1],c[2])    

def DoCut(destFh, bmp16, bmpW, bmpH, szX, szY, leftX, topY, mask, tileIx, xCuts):

    print(f"CUT:{szX}, {szY}, {leftX}, {topY}, {mask}, {tileIx}")


    (leftX < 0 or topY < 0) and Usage(sys.stderr, f"Out of bounds cut at {leftX},{topY}")
    (leftX + szX < 0 or topY + szY < 0) and Usage(sys.stderr, f"Out of bounds cut at {leftX + szX},{topY + szY}")

    for j in range(szY):
        srcY = topY + j
        
        beebPxRow = [0] * int((szX + 1) / 2)

        for i in range(szX):
            srcX = leftX + i
            ix = bmp16[srcY][srcX] & 0xF

            #print(f"RRRRP{bmp16[srcY]}")

            if ((i & 1) == 0):
                beebPxRow[i >> 1] |= BeebPixLeft(ix)
            else:
                beebPxRow[i >> 1] |= BeebPixRight(ix)

        destFh.write(bytes(beebPxRow))


    if mask:
        for j in range(szY):
            beebMaskRow = [0] * int((szX + 7) / 8)
            srcY = topY + j;
            for i in range(szX):
                srcX = leftX + i;
                if (bmp16[srcY][srcX] & 0x80) == 0:
                    beebMaskRow[i >> 3] |= 1 << (7 - (i & 7));

            destFh.write(bytes(beebMaskRow))


    xCut = ET.SubElement(xCuts, "cut")

    xCut.set("left-x", str(leftX));
    xCut.set("top-y", str(topY));
    xCut.set("index", str(tileIx+1));
    
    return tileIx+1


def BeebPixRight(ix):
    return        (((ix & 8) << 3)
                 + ((ix & 4) << 2)
                 + ((ix & 2) << 1)
                 + (ix & 1))

def BeebPixLeft(ix):
    return BeebPixRight(ix) << 1

#         protected int GetPixel(byte[,] bmp, int x, int y)
#         {
#             byte b = bmp[y, x >> 1];
#             if ((x & 1) != 0)
#                 return b >> 4;
#             else
#                 return b & 0x0F;
#         }


#         #region IDisposable Support
#         private bool disposedValue = false; // To detect redundant calls

#         protected virtual void Dispose(bool disposing)
#         {
#             if (!disposedValue)
#             {
#                 if (disposing)
#                 {
#                     // TODO: dispose managed state (managed objects).
#                 }

#                 // TODO: free unmanaged resources (unmanaged objects) and override a finalizer below.
#                 // TODO: set large fields to null.

#                 disposedValue = true;
#             }
#         }

#         // TODO: override a finalizer only if Dispose(bool disposing) above has code to free unmanaged resources.
#         // ~Program() {
#         //   // Do not change this code. Put cleanup code in Dispose(bool disposing) above.
#         //   Dispose(false);
#         // }

#         // This code added to correctly implement the disposable pattern.
#         public void Dispose()
#         {
#             // Do not change this code. Put cleanup code in Dispose(bool disposing) above.
#             Dispose(true);
#             // TODO: uncomment the following line if the finalizer is overridden above.
#             // GC.SuppressFinalize(this);
#         }
#         #endregion
#     }
# }


main()