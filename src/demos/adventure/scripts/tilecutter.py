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


if len(sys.argv) != 3:
    Usage(sys.stdout, "Incorrect number of arguments", exit=1)

basefile = sys.argv[1]
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

    bm=None
    bmpData=None
    bmpWidth=-1
    bmpHeight=-1
    curX=0
    curY=0
    tileIx=0
    try:
        for xe in xDf.findall("*"):
            print(xe.tag)
            if xe.tag == "source":
                sourceFileName = xe.attrib["file"]
                sourceFullName = os.path.join(sourcedir, sourceFileName);

                if bm is not None:
                    bm.close
                    bm=None

                try:
                    bm = Image.open(sourceFullName)
                except Exception as ex:
                    Usage(sys.stderr, f"Cannot open source image file \"{sourceFullName}\" for input", ex=ex, exit=2)

                bmpWidth = bm.width;
                bmpHeight = bm.height;
#                                         stride = 4 * ((width * 4 + 31) / 32);

#                                         bytes = new byte[height, stride];

#                                         destXw.WriteStartElement("source");
#                                         destXw.WriteAttributeString("size-x", width.ToString());
#                                         destXw.WriteAttributeString("size-y", height.ToString());
#                                         destXw.WriteAttributeString("filename", sourceFileName);



    finally:
        if bm is not None:
            bm.close
    cuts_doc = ET.ElementTree(cuts)
    cuts_doc.write(destFullName, encoding="UTF-8", xml_declaration=True)

        


#                                         //make new 16 colour bitmap with our own palette

#                                         width = (int)bm.Width;
#                                         height = (int)bm.Height;
#                                         stride = 4 * ((width * 4 + 31) / 32);

#                                         bytes = new byte[height, stride];

#                                         destXw.WriteStartElement("source");
#                                         destXw.WriteAttributeString("size-x", width.ToString());
#                                         destXw.WriteAttributeString("size-y", height.ToString());
#                                         destXw.WriteAttributeString("filename", sourceFileName);

#                                         /*
#                                         GCHandle gch = GCHandle.Alloc(bytes, GCHandleType.Pinned);
#                                         try
#                                         {
#                                             Bitmap bm16 = new Bitmap(bm.Width, bm.Height, stride, PixelFormat.Format4bppIndexed, gch.AddrOfPinnedObject());

#                                             ColorPalette p = bm16.Palette;

#                                             for (int i = 0; i < 16; i++)
#                                                 p.Entries[i] = pal[i];

#                                             bm16.Palette = p;

#                                             for (int x = 0; x < bm.Width; x++)
#                                             {
#                                                 for (int y = 0; y < bm.Height; y++)
#                                                 {
#                                                     Color oc = bm.GetPixel(x, y);
#                                                     int ix = 0;
#                                                     double max = 9999999;
#                                                     //find nearest colour
#                                                     for (int i = 0; i < 16; i++)
#                                                     {
#                                                         Color pc = pal[i];
#                                                         double err = Math.Pow(oc.R - pc.R, 2) + Math.Pow(oc.G - pc.G, 2) + Math.Pow(oc.B - pc.B, 2);

#                                                         if (err < max)
#                                                         {
#                                                             max = err;
#                                                             ix = i;
#                                                         }
#                                                     }
#                                                     bytes[y, x >> 1] |= (byte)(((x & 1) != 0) ? ix : ix << 4);
#                                                 }
#                                             }

#                                             bm16.Save($"d:\\temp\\image-{imgno++}.bmp", ImageFormat.Bmp);

#                                         }
#                                         finally
#                                         {
#                                             gch.Free();
#                                         }
#                                         */

#                                     }
#                                     else if (xe.LocalName == "move")
#                                     {
#                                         curX = int.Parse(xe.GetAttribute("x"));
#                                         curY = int.Parse(xe.GetAttribute("y"));
#                                     }
#                                     else if (xe.LocalName == "cut")
#                                     {
#                                         if (bytes == null)
#                                         {
#                                             Usage(Console.Error, "Error: cur before source");
#                                             return 4;
#                                         }

#                                         int nX = int.Parse(xe.GetAttribute("x"));
#                                         int nY = int.Parse(xe.GetAttribute("y"));
#                                         string dir = xe.GetAttribute("dir");

#                                         switch (dir)
#                                         {
#                                             case "rd":
#                                                 for (int j = 0; j < nY; j++)
#                                                     for (int i = 0; i < nX; i++)
#                                                         DoCut(destB, bm, bytes, width, height, stride, szX, szY, curX + szX * i, curY + szY * j, mask, destXw, ref tileIx);
#                                                 break;
#                                             default:
#                                                 Usage(Console.Error, $"Bad direction for cut=\"{dir}\"");
#                                                 break;
#                                         }


#                                     }
#                                 }

#                                 if (bytes != null)
#                                     destXw.WriteEndElement();
#                                 destXw.WriteEndElement();

#                             }
#                         }
#                     }
#                 }
#             } finally
#             {
#                 if (bm != null)
#                     bm.Dispose();
#             }

#             return 0;
#         }

#         protected void DoCut(BinaryWriter bw, IImage orgBm, byte[,] bmp, int bmpW, int bmpH, int bmpStride, int szX, int szY, int leftX, int topY, bool mask, XmlWriter xw, ref int tileIx)
#         {
#             if (bw == null)
#                 throw new ArgumentNullException("bw");

#             byte[] beebPxRow = new byte[((szX + 1) / 2)];

#             if (bmp == null)
#                 Usage(Console.Error, "No source set before a cut!");

#             if (leftX < 0 || topY < 0)
#                 Usage(Console.Error, $"Out of bounds cut at {leftX},{topY}");
#             if (leftX + szX < 0 || topY + szY < 0)
#                 Usage(Console.Error, $"Out of bounds cut at {leftX + szX},{topY + szY}");

#             for (int j = 0; j < szY; j++)
#             {
#                 for (int i = 0; i < beebPxRow.Length; i++)
#                     beebPxRow[i] = 0;

#                 int srcY = topY + j;
#                 for (int i = 0; i < szX; i++)
#                 {
#                     int srcX = leftX + i;
#                     int ix = GetPixel(bmp, srcX, srcY);

#                     if ((i & 1) == 0)
#                         beebPxRow[i >> 1] |= BeebPixLeft(ix);
#                     else
#                         beebPxRow[i >> 1] |= BeebPixRight(ix);
#                 }
#                 bw.Write(beebPxRow);
#             }

#             if (mask)
#             {
#                 byte[] beebMaskRow = new byte[(szX + 7) / 8];

#                 for (int j = 0; j < szY; j++)
#                 {
#                     for (int i = 0; i < beebMaskRow.Length; i++)
#                         beebMaskRow[i] = 0;

#                     int srcY = topY + j;
#                     for (int i = 0; i < szX; i++)
#                     {
#                         int srcX = leftX + i;
#                         int A = orgBm.GetPixel(srcX, srcY).A;

#                         if (A > 128)
#                             beebMaskRow[i >> 3] |= (byte)(1 << (7 - (i & 7)));
#                     }
#                     bw.Write(beebMaskRow);
#                 }

#             }

#             xw.WriteStartElement("cut");
#             xw.WriteAttributeString("left-x", leftX.ToString());
#             xw.WriteAttributeString("top-y", topY.ToString());
#             xw.WriteAttributeString("index", (++tileIx).ToString());
#             xw.WriteEndElement();
#         }

#         protected byte BeebPixLeft(int ix)
#         {
#             return (byte)(((ix & 8) << 3)
#                 + ((ix & 4) << 2)
#                 + ((ix & 2) << 1)
#                 + (ix & 1));
#         }

#         protected byte BeebPixRight(int ix)
#         {
#             return (byte)(BeebPixLeft(ix) << 1);
#         }

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
