
SPI_INC = 1


		.include "c20k-hardware.inc"
		.include "hardware.inc"
		.include "spi.inc"

		.export 		spi_reset
		.export 		spi_write_last
		.export 		spi_write_cont
		.export 		spi_wait_rd
;		.export		spi_read_buf

;;		.exportzp	zp_spi_addr
;;		.exportzp	zp_spi_len
;;		.exportzp	zp_spi_memptr


XFL_FAST_READ	:= $0B


		.segment "ZPEXT": zeropage
;;zp_spi_addr:	.res	3
;;zp_spi_len:	.res	2
;;zp_spi_memptr:	.res	2
		.code
;=============================================
; S P I
;=============================================

	.proc	spi_reset
		lda	#$10
		sta	fred_SPI_DIV		; fast spi
		lda	#$1C			; select nCS[7]
		sta	fred_SPI_CTL
		sta	fred_SPI_WRITE_END	; start and reset
		jsr	spi_wait_rd
		lda	#$00			; select nCS[0]
		sta	fred_SPI_CTL
		jmp	spi_wait_rd
	.endproc 

	.proc	spi_write_last
		sta	fred_SPI_WRITE_END
		jmp	spi_wait_rd
	.endproc

	.proc	spi_write_cont
		sta	fred_SPI_WRITE_CONT
		;;;;; FALL THRU ;;;;;
	.endproc

	.proc	spi_wait_rd
		bit	fred_SPI_STAT
		bmi	spi_wait_rd
		lda	fred_SPI_READ_DATA
		rts
	.endproc

;;
;;	.proc	spi_read_buf
;;		
;;		lda	zp_spi_len
;;		ora	zp_spi_len+1
;;		beq	@retcc
;;		
;;		lda	#XFL_FAST_READ
;;		jsr	spi_write_cont
;;		lda	zp_spi_addr+2
;;		jsr	spi_write_cont
;;		lda	zp_spi_addr+1
;;		jsr	spi_write_cont
;;		lda	zp_spi_addr+0
;;		jsr	spi_write_cont
;;		
;;		jsr	spi_write_cont		; dummy value
;;		ldy	#0
;;		
;;		jsr	@declen
;;		beq	@last
;;@lp:		jsr	spi_write_cont
;;		sta	(zp_spi_memptr),Y
;;		iny
;;		bne	@sk0
;;		inc	zp_spi_memptr+1
;;@sk0:		jsr	@declen
;;		bne	@lp
;;@last:		jsr	spi_write_last
;;		sta	(zp_spi_memptr),Y
;;		iny
;;
;;@retcc:		clc
;;		rts
;;
;;@declen:		lda	zp_spi_len
;;		bne	@skz
;;		dec	zp_spi_len+1
;;@skz:		dec	zp_spi_len
;;		lda	zp_spi_len
;;		ora	zp_spi_len+1
;;		rts
;;	.endproc