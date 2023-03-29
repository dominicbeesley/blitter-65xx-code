	.IFNDEF __MOSROM_INC__
__MOSROM_INC__:

;; taken from 6809 version and edited down - these data should be used with care

mos_MACHINE_TYPE_BYTE			:= $63

;; Address of MOS ROM base
MOSROMBASE				:= $C000


FSCV_CODE_OSCLI_UK			:= $03


zp_lang					:= $0000
zp_eco					:= $0090
zp_nmi					:= $00A0
L00A9					:= $00A9
zp_fs_s					:= $00B0
zp_fs_w					:= $00C0
zp_vdu_status				:= $00D0	; VDU Status as read by OSBYTE &75
zp_vdu_grpixmask			:= $00D1	; Graphics pixel mask
zp_vdu_txtcolourOR			:= $00D2	; Text colour OR mask
zp_vdu_txtcolourEOR			:= $00D3	; Text colour EOR mask
zp_vdu_gracolourOR			:= $00D4	; Graphics colour OR mask
zp_vdu_gracolourEOR			:= $00D5	; Graphics colour EOR mask
zp_vdu_gra_char_cell			:= $00D6	; Graphics character cell
zp_vdu_top_scanline			:= $00D8	; Top scan line
zp_vdu_wksp				:= $00DA	; Temporary workspace
;;;;removed !zp_rom_mul			:= $00E0	; BBC, Electron: Row multiplication
zp_cfs_w				:= $00E2
zp_opt_val				:= $00E3	; DB? check
zp_mos_GSREAD_quoteflag			:= $00E4	; GSREAD quote flag
zp_mos_GSREAD_characc			:= $00E5	; GSREAD character accumulator
zp_mos_OS_wksp				:= $00E6	; General OS workspace
zp_mos_autorep_countdown		:= $00E7	; Auto repeat countdown timer
zp_mos_input_buf			:= $00E8	; Input buffer pointer for OSWORD 0
zp_mos_rs423timeout			:= $00EA	; RS423 timeout counter, unused if no RS423
zp_mos_cfs_critical			:= $00EB	; CFS/RFS 'critical' flag
zp_mos_keynumlast			:= $00EC	; Internal key number (last)
zp_mos_keynumfirst			:= $00ED	; Internal key number (first)
zp_mos_jimdevsave			:= $00EE	; Internal key number of character to be ignored by OSBYTE &79, also the 1MHz bus paging register
zp_mos_OSBW_A				:= $00EF	; OSBYTE/OSWORD A reg value
;;;;
zp_mos_OSBW_X				:= $00F0	; OSBYTE/OSWORD X reg value
zp_mos_OSBW_Y				:= $00F1	; OSBYTE/OSWORD Y reg value

zp_mos_txtptr				:= $00F2	; OS Text pointer (eg star commands and filenames)
zp_mos_curROM				:= $00F4	; Currently selected ROM
zp_mos_curPHROM				:= $00F5	; Current PHROM or RFS ROM number or OSRDSC/OSWRSC number
zp_mos_genPTR				:= $00F6	; PHROM/RFSROM/OSRDSC/OSWRSC pointer
zp_mos_X				:= $00F8	; BBC, Electron: Unused, Master: Soft key expansion pointer
zp_mos_OS_wksp2				:= $00FA	; General OS workspace, used by buffer access code in interrupts
zp_mos_INT_A				:= $00FC	; Interrupt Temp A reg store
zp_mos_error_ptr			:= $00FD	; Error message pointer, initially set to language version string
zp_mos_ESC_flag				:= $00FF	; Escape flag (bit 7)

stack					:= $0100
STACKTOP				:= $0200

sysvar_OSVARADDR			:= $0236	; fx166/7 &A6/7 Address of OS variables
sysvar_ROMPTRTAB			:= $0238	; fx168/9 &A8/9 Address of ROM pointer table
sysvar_ROMINFOTAB			:= $023A	; fx170/1 &AA/B Address of ROM info table
sysvar_KEYB_ADDRTRANS			:= $023C	; fx172/3 &AC/D Address of key translation table
sysvar_ADDRVDUVARS			:= $023E	; fx174/5 &AE/F Address of VDU variables
sysvar_CFSTOCTR				:= $0240	; fx176	  &B0	CFS timeout counter, decremented every frame flyback
sysvar_CURINSTREAM			:= $0241	; fx177	  &B1	Currently selected input stream set with FX2
sysvar_KEYB_SEMAPHORE			:= $0242	; fx178	  &B2	BBC, Master: Keyboard semaphore
sysvar_PRI_OSHWM			:= $0243	; fx179	  &B3	Primary OSHWM
sysvar_CUR_OSHWM			:= $0244	; fx180	  &B4	Current OSHWM
sysvar_RS423_MODE			:= $0245	; fx181	  &B5	RS423 mode
sysvar_EXPLODESTATUS			:= $0246	; fx182	  &B6	BBC, Electron: Character definition explosion status
sysvar_CFSRFS_SWITCH			:= $0247	; fx183	  &B7	CFS/RFS switch
sysvar_VIDPROC_CTL_COPY			:= $0248	; fx184	  &B8	BBC, Master: RAM copy of VIDPROC control register
sysvar_VIDPROC_PAL_COPY			:= $0249	; fx185	  &B9	BBC, Master: RAM copy of VIDPROC palette register
sysvar_ROMNO_ATBREAK			:= $024A	; fx186	  &BA	ROM active last BRK
sysvar_ROMNO_BASIC			:= $024B	; fx187	  &BB	BASIC ROM number
sysvar_ADC_CUR				:= $024C	; fx188	  &BC	Current ADC Channel
sysvar_ADC_MAX				:= $024D	; fx189	  &BD	Maximum ADC Channel number
sysvar_ADC_ACCURACY			:= $024E	; fx190	  &BE	ADC conversion type/accuracy
sysvar_RS423_USEFLAG			:= $024F	; fx191	  &BF	RS423 use flag
sysvar_RS423_CTL_COPY			:= $0250	; fx192	  &C0	RAM copy of RS423 control register
sysvar_FLASH_CTDOWN			:= $0251	; fx193	  &C1	Flashing colour countdown timer
sysvar_FLASH_SPACE_PERIOD		:= $0252	; fx194	  &C2	Flashing colour space period count set by FX9
sysvar_FLASH_MARK_PERIOD		:= $0253	; fx195	  &C3	Flashing colour mark period count set by FX10
sysvar_KEYB_AUTOREP_DELAY		:= $0254	; fx196	  &C4	Keyboard auto-repeat delay set by FX11
sysvar_KEYB_AUTOREP_PERIOD		:= $0255	; fx197	  &C5	Keyboard auto-repeat period set by FX12
sysvar_EXEC_FILE			:= $0256	; fx198	  &C6	*EXEC file
sysvar_SPOOL_FILE			:= $0257	; fx199	  &C7	*SPOOL file handle
sysvar_BREAK_EFFECT			:= $0258	; fx200	  &C8	ESCAPE, BREAK effect
sysvar_KEYB_DISABLE			:= $0259	; fx201	  &C9	Keyboard disable
sysvar_KEYB_STATUS			:= $025A	; fx202	  &CA	Keyboard status byte
							;Bit 7  =1 shift enabled   
							;Bit 6  =1 control pressed 
							;bit 5  =0 shift lock      
							;Bit 4  =0 Caps lock       
							;Bit 3  =1 shift pressed   

sysvar_RS423_BUF_EXT			:= $025B	; fx203	  &CB	BBC, Master: Serial input buffer extent
sysvar_RS423_SUPPRESS			:= $025C	; fx204	  &CC	BBC, Master: Serial input supression flag
sysvar_RS423CASS_SELECT			:= $025D	; fx205	  &CD	BBC, Master: Serial/cassette selection flag
sysvar_ECO_OSBW_INTERCEPT		:= $025E	; fx206	  &CE	Econet OSBYTE/OSWORD intercept flag
sysvar_ECO_OSRDCH_INTERCEPT		:= $025F	; fx207	  &CF	Econet OSRDCH intercept flag
sysvar_ECO_OSWRCH_INTERCEPT		:= $0260	; fx208	  &D0	Econet OSWRCH intercept flag
sysvar_SPEECH_SUPPRESS			:= $0261	; fx209	  &D1	Speech suppression status
sysvar_SOUND_SUPPRESS			:= $0262	; fx210	  &D2	Sound suppression status
sysvar_BELL_CH				:= $0263	; fx211	  &D3	BELL channel number
sysvar_BELL_ENV				:= $0264	; fx212	  &D4	BELL envelope number/amplitude
sysvar_BELL_FREQ			:= $0265	; fx213	  &D5	BELL frequency
sysvar_BELL_DUR				:= $0266	; fx214	  &D6	BELL duration
sysvar_STARTUP_DISPOPT			:= $0267	; fx215	  &D7	Startup display and BOOT error options
sysvar_KEYB_SOFTKEY_LENGTH		:= $0268	; fx216	  &D8	Soft key string length
sysvar_SCREENLINES_SINCE_PAGE		:= $0269	; fx217	  &D9	Screen lines since last page
sysvar_VDU_Q_LEN			:= $026A	; fx218	  &DA	256-number of items in VDU queue
sysvar_KEYB_TAB_CHAR			:= $026B	; fx219	  &DB	BBC, Master: TAB key character
sysvar_KEYB_ESC_CHAR			:= $026C	; fx220	  &DC	ESCAPE character
sysvar_KEYB_C0CF_INSERT_INT		:= $026D	; fx221	  &DD	Char &C0-&CF buffer insert interpretation
sysvar_KEYB_D0DF_INSERT_INT		:= $026E	; fx222	  &DE	Char &D0-&DF buffer insert interpretation
sysvar_KEYB_E0EF_INSERT_INT		:= $026F	; fx223	  &DF	Char &E0-&EF buffer insert interpretation
sysvar_KEYB_F0FF_INSERT_INT		:= $0270	; fx224	  &E0	Char &F0-&FF buffer insert interpretation
sysvar_KEYB_808F_INSERT_INT		:= $0271	; fx225	  &E1	Char &80-&8F buffer insert interpretation (FKey)
sysvar_KEYB_909F_INSERT_INT		:= $0272	; fx226	  &E2	Char &90-&9F buffer insert interpretation (Sh+FKey)
sysvar_KEYB_A0AF_INSERT_INT		:= $0273	; fx227	  &E3	Char &A0-&AF buffer insert interpretation (Ct+FKey)
sysvar_KEYB_B0BF_INSERT_INT		:= $0274	; fx228	  &E4	Char &B0-&BF buffer insert interpretation (Ct+Sh+FKey)
sysvar_KEYB_ESC_ACTION			:= $0275	; fx229	  &E5	ESCAPE key action
sysvar_KEYB_ESC_EFFECT			:= $0276	; fx230	  &E6	ESCAPE effects
sysvar_USERVIA_IRQ_MASK_CPY		:= $0277	; fx231	  &E7	User 6522 VIA IRQ mask
sysvar_ACIA_IRQ_MASK_CPY		:= $0278	; fx232	  &E8	6850 ACIA IRQ bit mask
sysvar_SYSVIA_IRQ_MASK_CPY		:= $0279	; fx233	  &E9	System 6522 VIA IRQ mask
sysvar_TUBE_PRESENT			:= $027A	; fx234	  &EA	Tube presence flag
sysvar_SPEECH_PRESENT			:= $027B	; fx235	  &EB	Speech processor presence flag
sysvar_OUTSTREAM_DEST			:= $027C	; fx236	  &EC	Output stream character destination, set with FX3
sysvar_KEY_CURSORSTAT			:= $027D	; fx237	  &ED	Cursor key status, set with FX4
sysvar_FX238				:= $027E	; fx238	  &EE	BBC, Electron: unused
sysvar_FX239				:= $027F	; fx239	  &EF	unused
sysvar_COUNTRY				:= $0280	; fx240	  &F0	Country code
sysvar_USERFLAG				:= $0281	; fx241	  &F1	User flag location, set with FX1
sysvar_SERPROC_CTL_CPY			:= $0282	; fx242	  &F2	BBC, Master: RAM copy of SERPROC control register
sysvar_TIMER_SWITCH			:= $0283	; fx243	  &F3	Timer switch state
sysvar_KEYB_SOFT_CONSISTANCY		:= $0284	; fx244	  &F4	Soft key consistancy flag
sysvar_PRINT_DEST			:= $0285	; fx245	  &F5	Printer destination, set with FX5
sysvar_PRINT_IGNORE			:= $0286	; fx246	  &F6	Printer ignore character, set with FX6
sysvar_BREAK_VECTOR_JMP			:= $0287	; fx247	  &F7	Break Intercept Vector JMP
sysvar_BREAK_VECTOR_LOW			:= $0288	; fx248	  &F8	Break Intercept Vector address low byte
sysvar_BREAK_VECTOR_HIGH		:= $0289	; fx249	  &F9	Break Intercept Vector address high byte
sysvar_SHADOW1				:= $028A	; fx250	  &FA	BBC, Electron: unused, unless shadow screen present
sysvar_SHADOW2				:= $028B	; fx251	  &FB	BBC, Electron: unused, unless shadow screen present
sysvar_CUR_LANG				:= $028C	; fx252	  &FC	Current language ROM
sysvar_BREAK_LAST_TYPE			:= $028D	; fx253	  &FD	Last BREAK type
sysvar_RAM_AVAIL			:= $028E	; fx254	  &FE	BBC: Available RAM
sysvar_STARTUP_OPT			:= $028F	; fx255	  &FF	Startup options
oswksp_VDU_VERTADJ			:= $0290	; VDU vertical adjust, *TV first parameter
oswksp_VDU_INTERLACE			:= $0291	; Interlace toggle flag, *TV second parameter
oswksp_TIME				:= $0292	; TIME value 1, high byte...low byte
oswksp_TIME2				:= $0297	; TIME value 2, high byte...low byte
oswksp_OSWORD3_CTDOWN			:= $029C	; OSWORD 3/4 Countdown interval timer value
oswksp_ROMTYPE_TAB			:= $02A1	; Paged ROM type table
oswksp_INKEY_CTDOWN			:= $02B1	; INKEY countdown timer
oswksp_OSWORD0_LINE_LEN			:= $02B3	; OSWORD 0 maximum line length
oswksp_OSWORD0_MIN_CH			:= $02B4	; OSWORD 0 minimum character
oswksp_OSWORD0_MAX_CH			:= $02B5	; OSWORD 0 maximum character
adc_CH1_LOW				:= $02B6	; Channel 1 ADC value low
adc_CH2_LOW				:= $02B7	; Channel 2 ADC value low
adc_CH3_LOW				:= $02B8	; Channel 3 ADC value low
adc_CH4_LOW				:= $02B9	; Channel 4 ADC value low
adc_CH1_HI				:= $02BA	; Channel 1 ADC value high
adc_CH2_HI				:= $02BB	; Channel 2 ADC value high
adc_CH3_HI				:= $02BC	; Channel 3 ADC value high
adc_CH4_HI				:= $02BD	; Channel 4 ADC value high
adc_CH_LAST				:= $02BE	; Last ADC channel converted
mosvar_EVENT_ENABLE			:= $02BF	; MOS Event enable flags
mosvar_SOFTKEY_PTR			:= $02C9	; Soft key expansion pointer
mosvar_KEYB_AUTOREPEAT_COUNT		:= $02CA	; First auto repeat count
mosvar_KEYB_TWOKEY_ROLLOVER		:= $02CB	; Two key rollover workspace
mosvar_SOUND_SEMAPHORE			:= $02CE	; Sound semaphore
mosbuf_buf_busy				:= $02CF	; Buffer busy flags	      
mosbuf_buf_start			:= $02D8	; Buffer start indexes	      
mosbuf_buf_end				:= $02E1	; Buffer end indexes	      
cfsrfs_BLK_SIZE				:= $02EA	; Block size
cfsrfs_BLK_FLAG				:= $02EC	; Block flag
cfsrfs_LAST_CHA				:= $02ED	; Last input character
osfile_ctlblk				:= $02EE	; OSFILE control blocks for *LOAD, *SAVE, *CREATE and *DELETE.
vduvars_start				:= $0300
vduvar_GRA_WINDOW			:= $0300				
vduvar_GRA_WINDOW_LEFT			:= $0300	; Current graphics window left column in pixels
vduvar_GRA_WINDOW_BOTTOM		:= $0302	; Current graphics window bottom row in pixels
vduvar_GRA_WINDOW_RIGHT			:= $0304	; Current graphics window right column in pixels
vduvar_GRA_WINDOW_TOP			:= $0306	; Current graphics window top row in pixels
vduvar_TXT_WINDOW_LEFT			:= $0308	; Current text window left hand column
vduvar_TXT_WINDOW_BOTTOM		:= $0309	; Current text window bottom row
vduvar_TXT_WINDOW_RIGHT			:= $030A	; Current text window right hand column
vduvar_TXT_WINDOW_TOP			:= $030B	; Current text window top column
vduvar_GRA_ORG_EXT			:= $030C	; Current graphics origin in external coordinates
vduvar_GRA_CUR_EXT			:= $0310	; Current graphics cursor in external coordinates
vduvar_GRA_CUR_INT_OLD			:= $0314	; Old graphics cursor in external coordinates
vduvar_TXT_CUR_X			:= $0318	; Current text cursor X
vduvar_TXT_CUR_Y			:= $0319	; Current text cursor Y
vduvar_GRA_CUR_CELL_LINE		:= $031A	; Line within current graphics cell of graphics cursor
vduvar_VDU_Q_START			:= $031B
vduvar_VDU_Q_END			:= $0324	; end of VDU Q (well 1 after!)
vduvar_GRA_CUR_INT			:= $0324	; Current graphics cursor in internal coordinates
vduvar_TEMP_8				:= $0328	; Bitmap read from screen by OSBYTE 135, various coordinate routines
vduvar_GRA_WKSP				:= $0330	; Graphics workspace
vduvar_6845_CURSOR_ADDR			:= $034A	; Text cursor address for 6845
vduvar_TXT_WINDOW_WIDTH_BYTES		:= $034C	; Text window width in bytes
vduvar_SCREEN_BOTTOM_HIGH		:= $034E	; High byte of bottom of screen memory
vduvar_BYTES_PER_CHAR			:= $034F	; Bytes per character for current mode
vduvar_6845_SCREEN_START		:= $0350	; Screen display start address for 6845
vduvar_BYTES_PER_ROW			:= $0352	; Bytes per screen row
vduvar_SCREEN_SIZE_HIGH			:= $0354	; Screen memory size high byte
vduvar_MODE				:= $0355	; Current screen mode
vduvar_MODE_SIZE			:= $0356	; Memory map type: 0 - 20K, 1 - 16K, 2 - 10K, 3 - 8K, 4 - 1K
vduvar_TXT_FORE				:= $0357	; Foreground text colour
vduvar_TXT_BACK				:= $0358	; Background text colour
vduvar_GRA_FORE				:= $0359	; Foreground graphics colour
vduvar_GRA_BACK				:= $035A	; Background graphics colour
vduvar_GRA_PLOT_FORE			:= $035B	; Foreground plot mode
vduvar_GRA_PLOT_BACK			:= $035C	; Background plot mode
vduvar_VDU_VEC_JMP			:= $035D	; General VDU jump vector
vduvar_CUR_START_PREV			:= $035F	; Cursor start register previous setting
vduvar_COL_COUNT_MINUS1			:= $0360	; Number logical colours -1
vduvar_PIXELS_PER_BYTE_MINUS1		:= $0361	; Pixels per byte -1 (zero if text only mode)
vduvar_LEFTMOST_PIX_MASK		:= $0362	; Leftmost pixel colour mask
vduvar_RIGHTMOST_PIX_MASK		:= $0363	; Rightmost pixel colour mask
vduvar_TEXT_IN_CUR_X			:= $0364	; Text input cursor X
vduvar_TEXT_IN_CUR_Y			:= $0365	; Text input cursor Y
vduvar_MO7_CUR_CHAR			:= $0366	; Teletext output cursor character
vduvar_EXPLODE_FLAGS			:= $0367	; Font explosion flags, b1=224-255 in RAM, b7=32-63 in RAM
vduvar_FONT_LOC32_63			:= $0368	; Font location, characters 32-63
vduvar_FONT_LOC64_95			:= $0369	; Font location, characters 64-95 
vduvar_FONT_LOC96_127			:= $036A	; Font location, characters 96-127
vduvar_FONT_LOC128_159			:= $036B	; Font location, characters 128-159
vduvar_FONT_LOC160_191			:= $036C	; Font location, characters 160-191
vduvar_FONT_LOC192_223			:= $036D	; Font location, characters 192-223
vduvar_FONT_LOC224_255			:= $036E	; Font location, characters 224-255
vduvar_PALLETTE				:= $036F	; Palette for colours 0 to 15

fsvar_seq_block_gap			:= $03D1

;********************************************************
;*           B U F F E R   A D D R E S S E S            *
;********************************************************

BUFFER_KEYB_START			:= $03E0
BUFFER_KEYB_END				:= $03FF
BUFFER_SERI_START			:= $0A00
BUFFER_SERI_END				:= $0AFF
BUFFER_SERO_START			:= $0900
BUFFER_SERO_END				:= $09BF
BUFFER_LPT_START			:= $0880
BUFFER_LPT_END				:= $08BF
BUFFER_SND0_START			:= $0840
BUFFER_SND0_END				:= $084F
BUFFER_SND1_START			:= $0850
BUFFER_SND1_END				:= $085F
BUFFER_SND2_START			:= $0860
BUFFER_SND2_END				:= $086F
BUFFER_SND3_START			:= $0870
BUFFER_SND3_END				:= $087F
BUFFER_SPCH_START			:= $09C0
BUFFER_SPCH_END				:= $09FF


snd_unused1				:= $800	; Unused
snd_q_occupied				:= $804	; Sound queue occupancy flag
snd_amplitude				:= $808	; Current amplitude
snd_amplitude_phase_count		:= $80C	; Number of amplitude phases processed
snd_abs_pitch				:= $810	; Absolute pitch value
snd_pitch_phase_count			:= $814	; Number of pitch phases processed
snd_steps_left				:= $818	; Number of steps to process
snd_duration_ctr			:= $81C	; Duration
snd_duration_mul			:= $820	; Interval multiplier
snd_env_no				:= $824	; Envelope number/auto repeat parameter
snd_length_left				:= $828	; Length of remaining note interval
snd_sync_hold_parm			:= $82C	; Sync hold parameter
snd_chip_pitch				:= $830	; Sound chip current pitch setting
snd_pitch_deviation			:= $834	; Pitch deviation
snd_num_chans_sync			:= $838	; Number of channels required for sync
snd_cur_amp_step			:= $839	; Current amplitude step
snd_cur_target_amplitude		:= $83A	; Current target amplitude
snd_num_chans_hold_sync			:= $83B	; Number of channels on hold for sync

snd_parm_wksp				:= $83C	; Sound parameter calculation workspace
snd_low_parm				:= $83D	; Low order frequency parameter as sent to the sound generator
snd_high_parm				:= $83E	; High order frequency parameter as sent to the sound generator
snd_tempx				:= $83F

snd_envelope_defs			:= $8C0
snd_envelope_STEP			:= $8C0
snd_envelope_PI1			:= $8C1
snd_envelope_PI2			:= $8C2
snd_envelope_PI3			:= $8C3
snd_envelope_PN1			:= $8C4
snd_envelope_PN2			:= $8C5
snd_envelope_PN3			:= $8C6
snd_envelope_AA				:= $8C7
snd_envelope_AD				:= $8C8
snd_envelope_AS				:= $8C9
snd_envelope_AR				:= $8CA
snd_envelope_ALA			:= $8CB
snd_envelope_ALD			:= $8CC



soft_keys_start				:= $B00

vec_nmi					:= $0D00

swrom_wksp_tab				:= $0DF0

	.ENDIF