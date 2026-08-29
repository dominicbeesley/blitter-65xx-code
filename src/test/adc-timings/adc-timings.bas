REM > ADCTIME : work out EOC time vs sample value formula

*FX 16

DIM code% 100
sam%=&70:tim%=&72:ct%=&74:REM locations for saving sample and EOC time measured using USER VIA T23
UVIA_T2=&FE68
ADC=&FEC0

FOR I%=0 TO 3 STEP 3:P%=code%:[OPT I%
.SAMPLE
PHP:SEI

LDA#0:STA UVIA_T2:STA UVIA_T2+1

LDA#1:STA ADC+0 \START
.lp:BIT ADC+0:BMI lp

LDX UVIA_T2+1:LDA UVIA_T2:BPLsk:LDX UVIA_T2+1:.sk:STX tim%+1:STA tim%
LDA ADC+1:STA sam%+1:LDA ADC+2:STA sam%

PLP:RTS

]:NEXT

CLS

REMFOR I%=0 TO 255:?ct%=I%:CALL SAMPLE:PLOT 69, I%, (((!tim%) EOR &FFFF) + 1) AND &FFFF:NEXT

REPEAT
CALL SAMPLE
P.TAB(0,0);((!sam%) AND &FF00) DIV 64, (((!tim%) EOR &FFFF) + 1) AND &FFFF
PLOT 69, ((!sam%) AND &FFFF) DIV 64, ((((!tim%) EOR &FFFF) + 1) AND &FFFF) / 15
UNTIL0