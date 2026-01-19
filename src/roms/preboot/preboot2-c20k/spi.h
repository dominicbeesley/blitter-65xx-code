#ifndef __SPI_H__
#define __SPI_H__

void spi_reset(void);

void spi_read_buf(void *buf, unsigned long spi_address, unsigned count);

#endif