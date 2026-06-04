REM > SPITEST : query FPGA ROM, SPI controller at FC5x
S_STAT%=&FC50:S_DIV%=&FC51:S_RD%=&FC52:S_WR_END%=&FC52:S_WR_CONT%=&FC53
:
PROCspi_reset
PRINT "DEV:";
A%=FNspi_write_cont(&90):A%=FNspi_write_cont(&0):A%=FNspi_write_cont(&0):A%=FNspi_write_cont(&0)
PROCHEX(FNspi_write_cont(&0)):PROCHEX(FNspi_write_last(&0))
:
END
:
DEFPROCspi_reset
LOCAL A%
?S_DIV%=&10:REM speed divisor
?S_STAT%=&1C:REM select nCS[7] to cancel any pending stuff
?S_WR_END%=&FF:REM dummy write to clear anything pending, we should wait but BASIC is slow
A%=FNspi_wait_rd
?S_STAT%=&00:REM select nCS[0] to select SPI flash
A%=FNspi_wait_rd
ENDPROC
:
DEFFNspi_write_last(B%)
?S_WR_END%=B%
=FNspi_wait_rd
:
DEFFNspi_write_cont(B%)
?S_WR_CONT%=B%
=FNspi_wait_rd
:
DEFFNspi_wait_rd
REPEAT:UNTIL((?S_STAT%)AND&80)=0
=?S_RD%
:
DEFPROCHEX(B%)
PRINTSTR$~(B%DIV&10);STR$~(B%AND&F);
ENDPROC