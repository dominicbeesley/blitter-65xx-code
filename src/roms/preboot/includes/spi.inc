	.ifndef SPI_INC
SPI_INC=1

		.import 	spi_reset
		.import 	spi_write_last
		.import 	spi_write_cont
		.import 	spi_wait_rd
		.import 	spi_read_buf

		.importzp	zp_spi_addr
		.importzp	zp_spi_len
		.importzp	zp_spi_memptr

	.endif

