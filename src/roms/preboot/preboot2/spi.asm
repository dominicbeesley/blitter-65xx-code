
		.include "c20k-hardware.inc"
		.include "hardware.inc"
		.include "zeropage.inc"

		.export 		_spi_reset
		.export		_spi_read_buf


XFL_FAST_READ	:= $0B


;=============================================
; S P I
;=============================================

	.proc	_spi_reset
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

	;; extern void spi_read_buf(void *buf, unsigned long spi_address, unsigned count);
	.proc	_spi_read_buf
		
		sta	tmp1		; len in tmp1
		stx	tmp2		; len h in tmp2
		ora	tmp2		; check for zero len
		beq	@ret
		
		ldy	#5
		lda	(sp),Y
		sta	ptr1+1
		dey
		lda	(sp),Y
		sta	ptr1

		lda	#XFL_FAST_READ
		jsr	spi_write_cont
		ldy	#2
		lda	(sp),Y
		jsr	spi_write_cont
		dey
		lda	(sp),Y
		jsr	spi_write_cont
		dey
		lda	(sp),Y
		jsr	spi_write_cont
		
		jsr	spi_write_cont		; dummy value
		ldy	#0
		
		jsr	@declen
		beq	@last
@lp:		jsr	spi_write_cont
		sta	(ptr1),Y
		iny
		bne	@sk0
		inc	ptr1+1
@sk0:		jsr	@declen
		bne	@lp
@last:		jsr	spi_write_last
		sta	(ptr1),Y
		iny

@ret:		jsr	incsp6
		rts

@declen:		lda	tmp1
		bne	@skz
		dec	tmp2
@skz:		dec	tmp1
		lda	tmp1
		ora	tmp2
		rts
	.endproc