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
  leftGridLightPin = 5
  'Set clock to noon button
  setNoonButton = 18

OBJ
  'pst  : "PST_Driver"
  rgbLeftGrid : "RGB_LED_Strip_Driver"   

  
VAR


PUB Main | i
  waitcnt(clkfreq+cnt)
  dira[leftGridLightPin]~~
  rgbLeftGrid.start(leftGridLightPin, 9)
  rgbLeftGrid.AllOff
  repeat i from 0 to 8
    rgbLeftGrid.LED(i,rgbLeftGrid#orange)
  rgbLeftGrid.AllOff
  dira[setNoonButton]~
        
  Setup
  'HourRevolution

  outa[MS1Pin]~ 
  outa[MS2Pin]~~
  
  repeat
    if ina[setNoonButton] == 1           'When the reset button is pushed, this code will rotate the two rings until it finds
      outa[sleepMin]~~
      repeat until ina[hallMin]==0       'the hall effect sensor, and then will step them based on the number of times necessary
        outa[steppingMin]~~              'so that the clock reads 12:00
        waitcnt(clkfreq/1000+cnt) 
        outa[steppingMin]~        
        waitcnt(clkfreq/1000+cnt)
      repeat i from 0 to 17380 '440*39.5              'This number needs to be calibrated!
        outa[steppingMin]~~      
        waitcnt(clkfreq/1000+cnt)
        outa[steppingMin]~       
        waitcnt(clkfreq/1000+cnt)
      outa[sleepMin]~
        
      {outa[sleepHour]~~  
      repeat until ina[hallHour]==0
        outa[steppingHour]~~       
        waitcnt(clkfreq/1000+cnt) 
        outa[steppingHour]~           
        waitcnt(clkfreq/1000+cnt)
      repeat i from 0 to 9000              'This number needs to be calibrated!
        outa[steppingHour]~~       
        waitcnt(clkfreq/1000+cnt) 
        outa[steppingHour]~           
        waitcnt(clkfreq/1000+cnt)
      outa[sleepHour]~ }

  waitcnt(clkfreq*1000+cnt)


PUB MinuteRevolution | i, steps  
  repeat i from 0 to 59                     'calibrated with grid lights on
    steps:= 440                    '16*27.5 = 440
    if i==21 AND ina[hallMin]==1
      outa[sleepMin]~~
      repeat until ina[hallMin]==0
        outa[steppingMin]~~     
        waitcnt(clkfreq/1000+cnt)
        outa[steppingMin]~      
        waitcnt(clkfreq/1000+cnt)
      Microstep(16,200,steppingMin,sleepMin)
      outa[sleepMin]~
    else
      Microstep(16,steps,steppingMin,sleepMin)
    waitcnt(clkfreq/2+cnt) 

PUB HourRevolution | i, steps, j  
  repeat j from 3 to 15          ' gear is slow between 10 and 2, gear is fast between 9 and 4          'calibrated with grid lights on
    '12-2,3-5,6-8,9-11
    i:= j//12
    if i==0
      i:=12
    if i==12 
      steps:=16*69              
    if i==3 OR i==4 OR i==5     '3-5
      steps:=1096               '16*68.5=1096
    if i==6 OR i==7 OR i==8     '6-8
      steps:=16*69
    if i==9 OR i==10 OR i==11   '9-11
      steps:=16*70
    {if i==1
      steps:=?
    if i==2   
      steps:=?
    if i==3   
      steps:=?
    if i==4   
      steps:=?
    if i==5   
      steps:=?
    if i==6   
      steps:=?
    if i==7   
      steps:=?
    if i==8   
      steps:=?
    if i==9   
      steps:=?
    if i==10   
      steps:=?
    if i==11   
      steps:=?
    }

      if i==4 AND ina[hallHour]==1
      outa[sleepHour]~~
      repeat until ina[hallHour]==0            'step until we see the hall effect sensor
        outa[steppingHour]~~     
        waitcnt(clkfreq/1000+cnt)
        outa[steppingHour]~      
        waitcnt(clkfreq/1000+cnt)          
      repeat until ina[hallHour]==1            'step until we don't see the hall effect sensor
        outa[steppingHour]~~     
        waitcnt(clkfreq/1000+cnt)
        outa[steppingHour]~      
        waitcnt(clkfreq/1000+cnt)
      Microstep(16,100,steppingHour,sleepHour)
      outa[sleepHour]~
    else          
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
     
  repeat i from 0 to steps
    'if ina[hallHour] == 0
      'i:=985
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
       