CON
_xinfreq=6_250_000  
_clkmode=xtal1+pll16x           

  'A4988
  {
  MS3Pin = 0
  MS2Pin = 1
  MS1Pin = 2
  EnaPin = 3
  DirPin = 4
  StpPin = 5 
  SlpPin = 6
  RstPin = 7
  }
  'DRV8825

  MS3Pin = 4
  MS2Pin = 5
  MS1Pin = 6
  EnaPin = 7
  DirPin = 0
  StpPin = 1 
  SlpPin = 2
  RstPin = 3
  

OBJ
  pst  : "PST_Driver"

  
VAR


PUB Main | i
  Setup
  Microstep(4, 200) '80*32*8 for  gear
  'FullStep(200)  


PUB Microstep(fraction,steps) | i

  outa[SlpPin]~~

  if fraction == 2
    outa[MS1Pin]~~
    outa[MS2Pin]~
    outa[MS3Pin]~
  if fraction == 4
    outa[MS1Pin]~
    outa[MS2Pin]~~ 
    outa[MS3Pin]~
  if fraction == 8
    outa[MS1Pin]~~
    outa[MS2Pin]~~ 
    outa[MS3Pin]~
  if fraction == 16
    outa[MS1Pin]~
    outa[MS2Pin]~ 
    outa[MS3Pin]~~
  if fraction == 32
    outa[MS1Pin]~~
    outa[MS2Pin]~ 
    outa[MS3Pin]~~ 
     
  repeat i from 0 to steps*fraction
    outa[StpPin]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[StpPin]~      
    waitcnt(clkfreq/1000+cnt)

  outa[SlpPin]~
    
PUB FullStep(steps) | i

  outa[SlpPin]~~
  
  outa[MS3Pin]~
  outa[MS2Pin]~
  outa[MS1Pin]~

  repeat i from 0 to steps
    outa[StpPin]~~
    waitcnt(clkfreq/1000+cnt)
    outa[StpPin]~
    waitcnt(clkfreq/1000+cnt)

  outa[SlpPin]~
          
PUB Setup
   'setting pin directions
   dira[DirPin] := 1
   dira[StpPin] := 1
   dira[SlpPin] := 1
   dira[RstPin]~~
   dira[MS3Pin]~~
   dira[MS2Pin]~~
   dira[MS1Pin]~~
   dira[EnaPin]~~
   'driver setup
   outa[DirPin]~
   outa[SlpPin]~~
   outa[RstPin]~~
   outa[EnaPin]~
       