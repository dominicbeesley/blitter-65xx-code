# Sound Quickstart

## Introduction

This document is intended to give a quick overview of using the BLTUTIL ROM
SOUND extensions from BBC BASIC.

You should have installed the BLTUTIL ROM in any ROM slot (though Slot 15 is 
preferable) and be using any of the following hardware/emulator setups

- Hoglet 1MHz bus FPGA dev board with Paula Firmware
- Blitter Mk.2 or Mk.3 with Paula firmware
- B-em version (????)
- BeebEm version (????)


When you boot the machine you should see a "Dossytronics 1M Paula" or 
"Dossytronics 1M Blitter" banner and `*HELP` should show the status of the 
hardware below the BLTUTIL banner.

This document is written with the expectation that the reader will already be
familiar with using the *BBC Basic* *SOUND* and *ENVELOPE* commands. The *BBC 
BASIC User Guide* should be read along side this document.

## Paula

The Paula chipset is based loosely on the Commodore Amiga's Paula chipset. The
Paula chipset had the ability to alter the sample rate on each channel 
independently and to a fine granularity. This allows polyphonic music to be
be played with very little intervention from the CPU. This is in contrast to
popular sound cards for the PC and the sound system of the Acorn Archimedes and
RiscPC where the CPU was expected to re-sample to generate different notes. The
system used in the Music 500/5000 is similar to the Paula concept though doesn't
allow such large samples

This allows an older machine like the BBC Micro to easily play samples and the 
`BLTUTIL` support ROM can add extra sample-driven sound channels that can be
controlled with BBC BASIC using the familiar `SOUND` and `ENVELOPE` commands.

Depending on the hardware you are using there will either be 4 or 8 channels
which can be independently controlled and there will be room for between 470KB
and 7700KB of samples.

## Sample SSD/ADF

There is a sample SSD/ADF that accompanies this document containing files that 
will be referred to in the examples. You may substitute your own files of 
course! See the section [Converting .wav files](#wavfiles) below for information
on how to convert normal .wav files to the 8-bit signed raw sample files used
here.


## Getting started

The first thing that needs to happen is that the BBC BASIC sound extensions need
to be enabled. These are not enabled by default as they tend to slow the machine
down a little when in use. 

[NOTE: about 10% at present but it should be possible to improve this the ROM has
not been optimised]

The sound extensions are enabled with the

`*BLSOUND ON`

command. You should see:

`Paula sound started, channels: 4`

or 

`Paula sound started, channels: 8`

[At present it is not possible to turn off the sound system other than by performing
a Break or Ctrl-Break, more options will be added in future]

The next thing to do is to load a sample (insert the ssd/adl)

`*BLSAMLD S.SQ 1 0`

[A blank line will be printed before the next prompt - don't worry this is a short
sample, for longer samples a series of dots are printed during loading to show
progress]

All being well we have now loaded a simple sample into memory and we can make it play

`SOUND &4010,-15,100,10`

should give a slightly tinny rattly beep!

You should now try loading some other samples and re-trying the sound command above:

`*BLSAMLD S.SIN 1 0`

`*BLSAMLD S.SAW 1 0`

You can try varying the pitch and duration (last two parameters of the sound command)

### *\*BLSAMLD* command

The *BLSAMLD* command is used to load a sample into memory the syntax is

`*BLSAMLD <filename> <sample no> [<repeat>]`

The `sample no` parameter can be used to specify which sample slot to load to and 
can be any number in the range 1-20, sample numbers are quoted in hexadecimal.
This meanes that up to 32 samples can be loaded at once.

The repeat offset is used for repeating samples. So far the samples that we have loaded
have all had a repeat of 0 - that means play the sample to the end and then keep repeating
it. The samples we have loaded have all been 32 samples long, samples that repeat at a
multiple of 2, 4, 8, 16, 32, 64, 128 will be in-tune with sounds played on the usual
BBC sound chip and it is possible to mix the two.

Repeat offsets are specified in hexadecimal and may be negative. When they are negative
they specify an offset from the end of the sample rather than the start so

`*BLSAMLD S.SIN 1 -10`

would load the S.SIN sample in slot #1 and repeat the last 16 samples when playing

### *\*BLSAMCLR*

As well as loading samples you may want to clear them from memory especially if you
run out! 

`*BLSAMCLR <sn>` will clear the sample loaded in slot sn.

`*BLSAMCLR *` will clear all samples

You don't need to clear a sample slot before loading a new sample to that slot but
you may find that if you do a lot of overwrites that memory becomes fragmented and
there might not be room to load a very large sample. In which case you may need to 
clear all the samples out and then load the largest first (the order of the slots
is not important though).

You can see how much memory is free and the largest slot by typing `*BLHINF`

### *\*BLSAMMAP* command

So far we've loaded all our samples into slot one and only played them on a single 
channel but it is simple to load a number samples and play different sounds on 
different channels:

	*BLSAMLD S.SIN 4 0
	*BLSAMLD S.SQ 6 0
	*BLSAMLD S.SAW 8 0
	*BLSAMMAP 0 4
	*BLSAMMAP 1 6
	*BLSAMMAP 2 8

This has loaded three samples to slots 4, 6 and 8 and made these the samples that 
will be played by channels &4000, &4001 and &4002 respectively. Try the following
sound commands:

	SOUND &4010,-15,100,10
	SOUND &4011,-15,100,10
	SOUND &4012,-15,100,10

### *SOUND*

The *BBC BASIC* *SOUND* command works in a similar way to the BBC BASIC command except
that &4000 (decimal 16384) must be added to the channel number. 

It is also possible to specify the sample slot directly (bypassing the `*BLSAMMAP` 
command) by specifying the sample number in the amplitude parameter multiplied by &100
(256 decimal).

	SOUND &4010,&5F1,100,100

Would play sample #5 at volume -15

	SOUND &4010,&1103,100,100

Would play sample #&11 with *ENVELOPE* 3

### *ENVELOPE*

Give an example...works just the same as normal ENVELOPE
## <a name="wavfiles"></a>Converting .wav files 

Use an audio tool like audacity to resample instruments recorded at middle C to 8372 samples per second
[TODO: work out how I did this - I forgot!]

Example:

	*BLSOUND
	*BLSAMLD S.STARDOT 1
	SOUND &4010,&1F1,52,200

[I notice that 32 sample repeats sound out of tune with my other samples done audacity (eg. pipe) sounds
better at 31 samples. Either there's a bug or the 8372 figure is wrong]

## Generating your own samples

The X.GENSIN, X.GENSQ example programs show how those samples were generated

## Example programs

All in BASIC
	
	`PUGWASH`	- Captain Pugwash with original BBC sound
	`PUGBL6`	- Captain Pugwash with the S.PIPE sample
	`PUGBL7`	- Captain Pugwash with the S.PIPE sample

	`BANJO`		- Two dudes playing banjos with BBC sound
	`BANJOB4`	- Two dudes playing banjos with realistic banjo samples!(?)