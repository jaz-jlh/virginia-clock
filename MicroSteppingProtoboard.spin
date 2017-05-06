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

  MS2Pin = 7
  MS1Pin = 6
  'MS0Pin = 6
  'EnaPin = 7
  directionMin = 8
  steppingMin =  9 
  sleepMin   =   10
  directionHour = 11 
  steppingHour =  12
  sleepHour =  13
  'RstPin = 3

  'Hall effect sensor pins
  hallHour = 14
  hallMin = 15


  outerLightStrip = 16
  innerLightStrip = 17

  rightGridLightPin = 4     'TODO rectify pin conflict
  leftGridLightPin = 5



OBJ
  pst  : "PST_Driver"

  'LED Grid Drivers
  rgbLeftGrid : "RGB_LED_Strip_Driver"
  rgbRightGrid : "RGB_LED_Strip_Driver"
  
  'LED Strip Drivers
  'rgbStrip : "RGB_LED_Strip_Driver"
  rgbInner : "WS2812B_RGB_LED_Driver_v2"
  rgbOuter : "WS2812B_RGB_LED_Driver_v2"

  
VAR


PUB Main | w
  pst.start
  Setup
  repeat w from 0 to 5
    rgbLeftGrid.AllOff
    rgbRightGrid.AllOff
    rgbInner.AllOff
    rgbOuter.AllOff
    waitcnt(clkfreq+cnt)  

  countSteps(16,steppingMin,sleepMin)
  waitcnt(clkfreq*100+cnt)


PUB countSteps(fraction,stepPin,sleepPin) | i, count

  outa[sleepPin]~~

  if fraction == 4
    outa[MS1Pin]~~ 
    outa[MS2Pin]~
  if fraction == 16
    outa[MS1Pin]~ 
    outa[MS2Pin]~~
  if fraction == 32
    outa[MS1Pin]~~ 
    outa[MS2Pin]~~ 

  count:=0
  repeat until ina[hallMin] == 0
    outa[stepPin]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[stepPin]~      
    waitcnt(clkfreq/1000+cnt)
  repeat until ina[hallMin] == 1
    outa[stepPin]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[stepPin]~      
    waitcnt(clkfreq/1000+cnt)
    count:=count+1
  repeat until ina[hallMin] == 0
    outa[stepPin]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[stepPin]~      
    waitcnt(clkfreq/1000+cnt)
    count:=count+1

  pst.dec(count)
  pst.NewLine

  outa[sleepPin]~

PUB MinuteRevolution | i, steps  
  repeat i from 1 to 60
    steps:=28
    if i//15 == 0
      steps:=26
    if i==60
      steps:=29
    Microstep(16, steps,steppingMin,sleepMin)
    waitcnt(clkfreq+cnt) 

PUB HourRevolution | i, steps  
  repeat i from 1 to 12
    steps:= 68
    if i//3 == 0
      steps:= 69
    Microstep(16,steps,steppingHour,sleepHour)
    waitcnt(clkfreq+cnt)

PUB Microstep(fraction,steps,stepPin,sleepPin) | i

  outa[sleepPin]~~

  
  if fraction == 4
    outa[MS1Pin]~~ 
    outa[MS2Pin]~
  if fraction == 16
    outa[MS1Pin]~ 
    outa[MS2Pin]~~
  if fraction == 32
    outa[MS1Pin]~~ 
    outa[MS2Pin]~~ 
     
  repeat i from 0 to steps*fraction
    outa[stepPin]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[stepPin]~      
    waitcnt(clkfreq/1000+cnt)

  outa[sleepPin]~
    
{PUB FullStep(steps) | i

  outa[SlpPin]~~
  
  outa[MS2Pin]~
  outa[MS1Pin]~

  repeat i from 0 to steps
    outa[StpPin]~~
    waitcnt(clkfreq/1000+cnt)
    outa[StpPin]~
    waitcnt(clkfreq/1000+cnt)

  outa[SlpPin]~
}          
PUB Setup
   'setting pin directions
   dira[directionHour] := 1
   dira[directionMin] := 1
   dira[steppingHour] := 1
   dira[steppingMin] := 1
   dira[sleepHour] := 1
   dira[sleepMin] := 1
   dira[hallHour] := 0
   dira[hallMin] := 0
   'dira[RstPin]~~
   dira[MS2Pin]~~
   dira[MS1Pin]~~
   'dira[MS0Pin]~~
   'dira[EnaPin]~~
   'driver setup
   outa[directionHour]~~
   outa[directionMin]~
   outa[sleepHour]~
   outa[sleepMin]~
   'outa[RstPin]~~
   'outa[EnaPin]~

   'Light Strips & Grids
   dira[outerLightStrip]~~
   dira[innerLightStrip]~~
   dira[rightGridLightPin]~~
   dira[leftGridLightPin]~~

PUB AutoCalibrate | currentMin, differenceMin, i


  outa[sleepMin]~~
    repeat until ina[hallMin]==0            'step until we see the hall effect sensor
      outa[steppingMin]~~     
      waitcnt(clkfreq/1000+cnt)
      outa[steppingMin]~      
      waitcnt(clkfreq/1000+cnt)
    repeat i from 0 to 200                  'then another 200 steps
     outa[steppingMin]~~     
      waitcnt(clkfreq/1000+cnt)
      outa[steppingMin]~      
      waitcnt(clkfreq/1000+cnt)
  outa[sleepMin]~

  currentMin:= 20
  differenceMin:= currentMin - 22
  if(differenceMin < 0)
    differenceMin:= currentMin + 38

  outa[sleepMin]~~
  repeat i from 0 to 440*differenceMin
    outa[steppingMin]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[steppingMin]~      
    waitcnt(clkfreq/1000+cnt)
  outa[sleepMin]~

        