         .include "hardware.inc"
         .include "oslib.inc"

;        >XFDump001/s
;        Adapted from Source for *MDUMP by J.G.Harston
;        v0.01 09-Mar-2026, Dominic Beesley
;        

         .globalzp zp_addr, zp_end, zp_os, zp_cols, zp_lptr
zp_addr  := $A8
zp_end   := $AC
zp_os    := $AE
zp_cols  := $AF
zp_lptr  := $F0


         .code

         LDA #135
         JSR OSBYTE

         LDX #$16
         TYA
         BEQ setcols
         CPY #3
         BEQ setcols
         LDX #8

setcols:
         STX zp_addr       ; store it here for now - move later
         LDA #1            ; get command tail
         LDX #zp_lptr         
         LDY #0
         JSR OSARGS        ; NB! writes 4 bytes of memory
  
         LDX #zp_addr      ; get number to here
         LDA (zp_lptr),Y
         CMP #'-'
         BNE mdumpcols
         INY
         JSR GetHex
mdumpcols:
         LDA (zp_lptr),Y
         CMP #13
         BNE @s0
@jbrkSyntax:
         jmp brkSyntax
@s0:     LDA zp_addr
         PHA               ; save columns for later
  
         ; start addr
         JSR GetHex
         BEQ @jbrkSyntax

         CMP #'+'
         PHP
         BNE @s1
         JSR SkipSpace1
@s1:     LDX #zp_end
         JSR GetHex
         PLP
         BNE mdump
         CLC
         LDA zp_addr+0
         ADC zp_end+0
         STA zp_end+0
         LDA zp_addr+1
         ADC zp_end+1
         STA zp_end+1

mdump:
         PLA
         AND #$1F
         CMP #$10
         BCC @s2
         SBC #6
@s2:     STA zp_cols          ; Columns in decimal
mdump1:
loop:
         LDX #2
praddr:
         LDA zp_addr,X
         JSR PrHex
         DEX
         BPL praddr
         JSR GetBytes
         LDX #0
loop1:
         JSR PrSpace
         LDA buff,X
         JSR PrHex
         INX
         CPX zp_cols
         BNE loop1
         JSR PrSpace
         LDX #0
loop2:
         LDA buff,X
         AND #127
         CMP #32
         BCS pr_char
pr_dot:  LDA #'.'
pr_char: CMP #127
         BEQ pr_dot
         JSR OSWRCH
         INX
         CPX zp_cols
         BNE loop2
         JSR OSNEWL
         BIT $FF
         BMI escape

         LDX #$FC
         CLC
         LDA zp_cols
inc_addr:
         ADC zp_addr+4,X
         STA zp_addr+4,X
         LDA #0
         INX
         BNE inc_addr
         LDA zp_addr+1
         EOR zp_end+1
         BNE loop
         LDA zp_end+0
         EOR zp_addr+0
         AND #$F0
         BNE loop
escape:
         LDA #124
         JMP OSBYTE          ; Clear Escape and exit

GetBytes:
         JSR spi_reset
         lda #$B                    ; bulk read
         jsr spi_write_cont
         lda zp_addr+2
         jsr spi_write_cont
         lda zp_addr+1
         jsr spi_write_cont
         lda zp_addr+0
         jsr spi_write_cont
         jsr spi_write_cont         ; dummy read
         LDY#0
getlp:
         jsr spi_write_cont
         STA buff,Y
         INY 
         CPY zp_cols
         BNE getlp
         jsr spi_write_last
         RTS

PrSpace:
         LDA #32
         BNE PrChar
PrHex:
         PHA
         LSR A
         LSR A
         LSR A
         LSR A
         JSR PrDigit
         PLA
PrDigit:
         AND #15
         CMP #10
         BCC PrNybble
         ADC #6
PrNybble:
         ADC #48
PrChar:  JMP OSWRCH
         
GetHex:
         LDA #0
         STA 0,X
         STA 1,X
         STA 2,X
         STA 3,X
GetHexNext:
         LDA (zp_lptr),Y
         CMP #'0'
         BCC SkipSpace
         CMP #'9'+1
         BCC GetHexDigit
         SBC #7
         BCC SkipSpace
         CMP #'@'
         BCS SkipSpace
GetHexDigit:
         AND #$0F
         PHA
         TYA
         PHA
         LDY #4
GetHexMultiply:
         ASL 0,X
         ROL 1,X
         ROL 2,X
         ROL 3,X
         DEY
         BNE GetHexMultiply
         PLA
         TAY
         PLA
         ORA 0,X
         STA 0,X
         INY
         BNE GetHexNext
         
SkipSpace1:
         INY
SkipSpace:
         LDA (zp_lptr),Y
         CMP #' '
         BEQ SkipSpace1
         CMP #13
         RTS
         
         .proc    spi_reset
                  lda      #$10
                  sta      fred_SPI_DIV               ; fast spi
                  lda      #$1C                       ; select nCS[7]
                  sta      fred_SPI_CTL
                  sta      fred_SPI_WRITE_END         ; start and reset
                  jsr      spi_wait_rd
                  lda      #$00                       ; select nCS[0]
                  sta      fred_SPI_CTL
                  jmp      spi_wait_rd
         .endproc 

         .proc    spi_write_last
                  sta      fred_SPI_WRITE_END
                  jmp      spi_wait_rd
         .endproc

         .proc    spi_write_cont
                  sta      fred_SPI_WRITE_CONT
                  ;;;;; FALL THRU ;;;;;
         .endproc

         .proc    spi_wait_rd
                  bit      fred_SPI_STAT
                  bmi      spi_wait_rd
                  lda      fred_SPI_READ_DATA
                  rts
         .endproc


brkSyntax:  
         brk
         .byte    220, "XMDUMP [-cols] #<dev> <start> <zp_end>|+<len>", 0

         .bss
buff:     .res     256
