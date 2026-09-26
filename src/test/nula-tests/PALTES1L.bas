    0REM >test palette flash and phys colour 
    1REM mapping to nula palette
    2MODE 4:?&FE22=&40:?&FE22=&11
    3?&FE21=&0F:REM make flashing B/W stripes down screen
    4?&FE23=&03:?&FE23=45:REM on real NULA gives blueish 
    5REM background with flashing white stripes
