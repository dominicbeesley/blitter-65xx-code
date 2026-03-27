#ifndef __SPI_H__
#define __SPI_H__

extern void spi_reset(void);

extern void spi_read_buf(void *buf, unsigned long spi_address, unsigned count);

#endif