CON
_xinfreq=6_250_000  
_clkmode=xtal1+pll16x           

  'For DRV8825
  DirPin = 0
  StpPin = 1 
  SlpPin = 2
  RstPin = 3
  MS2Pin = 4
  MS1Pin = 5
  MS0Pin = 6
  EnaPin = 7  

OBJ
  pst  : "PST_Driver"

  
VAR


PUB Main | i
  Setup
  SetCurrentLimit

PUB SetCurrentLimit

  outa[SlpPin]~~
  
  outa[MS2Pin]~
  outa[MS1Pin]~
  outa[MS0Pin]~

  outa[StpPin]~~
  waitcnt(clkfreq*5+cnt)

  outa[SlpPin]~
                    
PUB Setup
   'setting pin directions
   dira[DirPin]~~
   dira[StpPin]~~
   dira[SlpPin]~~
   dira[RstPin]~~
   dira[MS2Pin]~~
   dira[MS1Pin]~~
   dira[MS0Pin]~~
   dira[EnaPin]~~
   'driver setup
   outa[DirPin]~
   outa[SlpPin]~~
   outa[RstPin]~~
   outa[EnaPin]~
       