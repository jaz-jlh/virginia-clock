CON
_xinfreq=6_250_000
_clkmode=xtal1+pll16x
  'RTC Constants
  'Read Addresses   'Each bytes's 8-bits are assigned in the following way (#=bit number, X=not used)...
                  ' *10s  __s                              '12:09:00AM 11/3/15
  _seconds=$00       'X_654_3210                             time[0]:=0<<4 + 0
                  ' *10m  __m
  _minutes=$01       'X_654_3210                             time[1]:=0<<4 + 9                    
                  '   1/0   1/0  *10hr  hr
  _hour=$02          'X_12/24_PM/AM_4____3210                time[2]:=1<<6 + 0<<5 + 1<<4 + 2      
                  '      day
  _day=$03           'XXXXX_210                              time[3]:=2
                  '   *10  date
  _date=$04          'XX_54___3210                           time[4]:=0<<4 + 3
                  'century   *10month month
  _month=$05         '7______XX_4________3210                time[5]:=0<<7 + 1<<4 + 1
                  '*10yr __yr
  _year=$06          '7654__3210                             time[6]:=1<<4 + 5


  
  'PIN ASSIGNMENTS        ------------------------
  'RTC Pins
  CS = 0
  SO = 1
  SI = 2
  CLK = 3
  'Grid LEDs
  rightGridLightPin = 4     'TODO rectify pin conflict
  leftGridLightPin = 5
  'Stepper control pins
  MS1 = 6
  MS2 = 7
  directionMin = 8
  steppingMin =  9 
  sleepMin   =   10
  directionHour = 11 
  steppingHour =  12
  sleepHour =  13
  'Hall effect sensor pins
  hallHour = 14
  hallMin = 15 
  outerLightStrip = 16
  innerLightStrip = 17
  'Set clock to noon button
  setNoonButton = 18
  'LED Strip Constants
  innerLEDs = 126
  maxInnerAddress = 125
  outerLEDs = 127
  maxOuterAddress = 126

  'Microstepping constant (sets both motors)
  microstep = 16

VAR
long desired, Stack1[100], Stack2[100], Stack3[100], Stack4[100], Stack5[100], Stack6[100], Stack7[100]
byte time[7], endTime
long t[7]
long color[2]
long leftGridColor, rightGridColor, InnerStripColor, OuterStripColor
long lastSecond, lastMinute, lastHour, lastDay, stepMinAmount, stepHourAmount


OBJ
  'LED Grid Drivers
  rgbLeftGrid : "RGB_LED_Strip_Driver"
  rgbRightGrid : "RGB_LED_Strip_Driver"
  
  'LED Strip Drivers
  'rgbStrip : "RGB_LED_Strip_Driver"
  rgbInner : "WS2812B_RGB_LED_Driver_v2"
  rgbOuter : "WS2812B_RGB_LED_Driver_v2"
  
  'PST should only be used when connected to a computer
  pst : "PST_Driver"
  
PUB Main | i, j, w
  'Pin Directions   -------------------
  'Stepper Pins (3/motor)
  dira[steppingMin]~~    
  dira[directionMin]~~   
  dira[sleepMin]~~
  dira[steppingHour]~~    
  dira[directionHour]~~   
  dira[sleepHour]~~
  dira[MS1]~~
  dira[MS2]~~
  'RTC Communication
  dira[CS]~~
  dira[SI]~
  dira[SO]~~
  dira[CLK]~~  
  outa[CS]~~
  'Light Strips & Grids
  dira[outerLightStrip]~~
  dira[innerLightStrip]~~
  dira[rightGridLightPin]~~
  dira[leftGridLightPin]~~
  'Hall Effect Sensors
  dira[hallMin]~
  dira[hallHour]~
  'Set the clock to 12 button
  dira[setNoonButton]~
  'Pin Directions   -------------------


  'pst.start
  
  'Used to manually program RTC time -------------------------
  '7:52:45PM 4/19/16                                                  ' *10m  __m                            
  {time[0]:=4<<4 + 5                                  '_minutes=$01       'X_654_3210                                       
  time[1]:=5<<4 + 2                                                    '   1/0   1/0  *10hr  hr                              
  time[2]:=0<<6 + 0<<5 + 1<<4 + 9                    '_hour=$02          'X_12/24_PM/AM_4____3210                                          
  time[3]:=2                                                           '      day                                      
  time[4]:=1<<4 + 9                                  '_day=$03           'XXXXX_210                                         
  time[5]:=0<<7 + 0<<4 + 4                                             '   *10  date                                                 
  time[6]:=1<<4 + 6                                  '_date=$04          'XX_54___3210
  }
  '19:18:00 3/17/17 
  {time[0]:=0                                 '_minutes=$01       'X_654_3210                                       
  time[1]:=5<<4 + 3                                                    '   1/0   1/0  *10hr  hr                              
  time[2]:=1<<4 + 5                    '_hour=$02          'X_12/24_PM/AM_4____3210                                          
  time[3]:=3                                                           '      day                                      
  time[4]:=0<<4 + 3                                  '_day=$03           'XXXXX_210                                         
  time[5]:=0<<7 + 0<<4 + 5                                             '   *10  date                                                 
  time[6]:=1<<4 + 7                                  '_date=$04          'XX_54___3210                    
                                                                       'century   *10month month              
  SetTime                                         '_month=$05         '7______XX_4________3210            
  waitcnt(100*clkfreq +cnt)}                                                                     '*10yr __yr                    
                                                     '_year=$06          '7654__3210
                       '                          day      1/0   1/0  10  hr     10m ___m     _seconds
                                        '  XXXXX_210___X_12/24_PM/AM_4_3210___X_654_3210___X_654_3210
  '                                        time[3]     time[2]                time[1]      time[0]
  'comment out the above time setting code for normal use----------------
  'Used to manually program RTC time -------------------------

  'Set the microstepping pins once (microstep is set once in the CON section)
  if microstep == 4
    outa[MS1]~~ 
    outa[MS2]~
  if microstep == 16
    outa[MS1]~ 
    outa[MS2]~~
  if microstep == 32
    outa[MS1]~~ 
    outa[MS2]~~

  'Initial startup - keep sending LED off commands while plugging LEDs in to prevent spikes
  repeat w from 0 to 5
    rgbLeftGrid.AllOff
    rgbRightGrid.AllOff
    rgbInner.AllOff
    rgbOuter.AllOff
    waitcnt(clkfreq+cnt)  

  'Call the Grid Light methods once upon initialization
  leftGridColor:=rgbInner#orange
  rightGridColor:=rgbInner#blue  
  leftGridLight
  rightGridLight

  'Initialize cog for the LED drivers
  InnerStripColor:=rgbInner#orange
  OuterStripColor:=rgbInner#blue
  rgbInner.start(innerLightStrip,innerLEDs)
  rgbOuter.start(outerLightStrip,outerLEDs)
  rgbInner.AllOff          
  rgbOuter.AllOff

  AutoCalibrateHour
  AutoCalibrateMin

  GetTime                          'read from RTC and populate the t[] array
  lastSecond:=t[0]
  lastMinute:=t[1]
  lastHour:=t[2]

  'Main Repeat Loop
  repeat
     'Reset to noon
     if ina[setNoonButton] == 1           'When the reset button is pushed, this code will rotate the two rings until it finds
       '12:00:00 noon    
       time[0]:=0                                 '_minutes=$01       'X_654_3210                                       
       time[1]:=0<<4 + 0                                                    '   1/0   1/0  *10hr  hr                              
       time[2]:=1<<4 + 2                    '_hour=$02          'X_12/24_PM/AM_4____3210                                          
                                                                                                       
       SetTime
       rgbInner.AllOff          
       rgbOuter.AllOff
       AutoCalibrateHour
       AutoCalibrateMin
       GetTime                          'read from RTC and populate the t[] array
       lastSecond:=t[0]
       lastMinute:=t[1]
       lastHour:=t[2]

    'Normal Operation ------------------          
    GetTime                          'read from RTC and populate the t[] array
    'DisplayTime 
    if lastSecond <> t[0]            'lastX flags are used to check if time has changed                                  '
      'DisplayTime
      lastSecond:= t[0]
    'Motor Control:
    if lastMinute <> t[1]      
      StepMin
      cogstop(6)
      coginit(6,OuterStripLights,@Stack6)
      cogstop(7)
      coginit(7,InnerStripLights,@Stack7)
      lastMinute:= t[1]
    if lastHour <> t[2] 
      StepHour
      lastHour:= t[2]
    if lastDay <> t[4]
      lastDay:=t[4]
      'Holidays:
      if t[4]==17 and t[5]==3                 'St. Patricks Day
        leftGridColor:=rgbInner#green
        rightGridColor:=rgbInner#yellow
        InnerStripColor:=rgbInner#green
        OuterStripColor:=rgbInner#yellow
        leftGridLight
        rightGridLight
      else
        if t[4]==14 and t[5]==2                'Valentines Day
          leftGridColor:=rgbInner#red
          rightGridColor:=rgbInner#magenta
          InnerStripColor:=rgbInner#red
          OuterStripColor:=rgbInner#magenta
          leftGridLight
          rightGridLight
        else
          if t[4]==4 and t[5]==7               'Fourth of July
            leftGridColor:=rgbInner#blue
            rightGridColor:=rgbInner#blue
            InnerStripColor:=rgbInner#red
            OuterStripColor:=rgbInner#white
            leftGridLight
            rightGridLight
          else
            if t[4]==31 and t[5]==10           'Halloween
              leftGridColor:=rgbInner#orange
              rightGridColor:=rgbInner#violet
              InnerStripColor:=rgbInner#orange
              OuterStripColor:=rgbInner#violet
              leftGridLight
              rightGridLight
            else                               'Every other day
              leftGridColor:=rgbInner#orange
              rightGridColor:=rgbInner#blue
              InnerStripColor:=rgbInner#orange
              OuterStripColor:=rgbInner#blue
              leftGridLight
              rightGridLight
                                               
    'if (t[2]==12 or t[2]==24) and ina[hallHour]==1           'I'm starting to think this hall effect sensor will be ineffective.. I may comment this out later
      'repeat until ina[hallHour]==0
        'outa[steppingHour]~~
        'waitcnt(clkfreq/1000+cnt)
        'outa[steppingHour]~                                                                 
        'waitcnt(clkfreq/1000+cnt)
       

    'Fancy Patterns for class endings
    {
    'Check to see if the minute is 0 then if it is Monday, Wednesday, or Friday
    if t[1]==50 and (t[3]==1 or t[3]==3 or t[3]==5)
      FancyPattern
      waitcnt(clkfreq/50+cnt)
      rgbStrip.AllOff
    'Check to see if its Tuesday or Thursday, then that the seconds are 0, then that the minute is 15, then that the hour is either 9, 12, or 15
    if (t[3]==2 or t[3]==4) and t[0]==00 and (t[1]==15 and (t[2]==9 or t[2]==12 or t[2]==15)) 
      FancyPattern
      waitcnt(clkfreq/50+cnt)
      rgbStrip.AllOff
      rgbStrip.LED(0,0)
    'Check to see if its Tuesday or Thursday, then that the seconds are 0, then that the minute is 45, then that the hour is either 10, 13, or 16
    if (t[3]==2 or t[3]==4) and t[0]==00 and (t[1]==45 and (t[2]==10 or t[2]==13 or t[2]==14))
      FancyPattern
      waitcnt(clkfreq/50+cnt)
      rgbStrip.AllOff
      rgbStrip.LED(0,0)
    }
      
    


PUB GetTime  | i      ''Refresh time[0] through time[6] values
  outa[CS]~
  repeat 8        'Set starting address to be $00=seconds
    outa[CLK]~~
    outa[SO]:=0
    outa[CLK]~
  repeat i from 0 to 6
    repeat 8
      outa[CLK]~~ 
      time[i]:=time[i]<<1+ina[SI]
      outa[CLK]~  
  outa[CS]~~
  
  'Populate a readable array of time so we can make decisions based on it
  t[0]:=(time[0]>>4)*10 + (time[0] & $0f)    'seconds
  t[1]:=(time[1]>>4)*10 + (time[1] & %1111)   'minutes
  t[2]:=(time[2] & %10_0000)*20 + ((time[2] & %1_0000)>>4)*10 + (time[2] & %1111)    'hours
  t[3]:=time[3]                                      'day of week
  t[4]:=(time[4]>>4)*10 + (time[4] & $0f)              'date
  t[5]:=(time[5] & $10)*10 + (time[5] & $0f)            'month
  t[6]:=(time[5]>>7)*100 + (time[6]>>4)*10 + (time[6] & $0f)   'year

PUB DisplayTime
  {if (time[2] & %1_0000)==%1_0000
    pst.str(string("1"))       'hours tens place
  else
    pst.str(string(" "))
  pst.dec(time[2] & %1111)     'hours
  pst.str(string(":"))
  pst.dec((time[1] & %111_0000)>>4) 'minutes tens place
  pst.dec(time[1] & %000_1111) 'minutes 
  pst.str(string(":"))            
  pst.dec((time[0] & %111_0000)>>4) 'seconds tens place
  pst.dec(time[0] & %000_1111) 'seconds
  }
  
  pst.dec(t[2])
  pst.str(string(":"))
  pst.dec(t[1])
  pst.str(string(":"))
  pst.dec(t[0])
  pst.str(string("   ")) 
  
  case t[3]
    0:pst.str(string("Sunday"))
    1:pst.str(string("Monday"))
    2:pst.str(string("Tuesday"))
    3:pst.str(string("Wednesday"))
    4:pst.str(string("Thursday"))
    5:pst.str(string("Friday"))
    6:pst.str(string("Saturday"))
  pst.str(string("   "))
  pst.dec(t[5])
  pst.str(string("/"))
  pst.dec(t[4])
  pst.str(string("/"))
  pst.dec(t[6])
  pst.NewLine          
  
PUB SetTime  | i,j
  outa[CS]~
  repeat i from 7 to 0      'Set starting address to be $80=seconds
    outa[CLK]~~
    outa[SO]:=$80>>i & 1
    outa[CLK]~
  repeat i from 0 to 6
    repeat j from 7 to 0
      outa[CLK]~~ 
      outa[SO]:=time[i]>>j & 1
      outa[CLK]~  
  outa[CS]~~

PUB ReadAddress(a) : value |i
  outa[CS]~
  repeat i from 7 to 0
    outa[CLK]~~
    outa[SO]:=a>>i & 1
    outa[CLK]~

  repeat 8
    outa[CLK]~~ 
    value:=value<<1+ina[SI]
    outa[CLK]~

  outa[CS]~~
      
PUB StepMin | i, steps
  outa[directionMin]~
  outa[sleepMin]~~
  steps:=stepMinAmount                  '1/16 microstepping gives 16*27.5 = 440        'calibrated with grid lights on
  if t[1]==22 AND ina[hallMin]==1           'if we get to 21 and we haven't seen the hall effect sensor
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
  else
    repeat i from 0 to steps          
      outa[steppingMin]~~
      waitcnt(clkfreq/1000+cnt)
      outa[steppingMin]~                                          
      waitcnt(clkfreq/1000+cnt)

  outa[sleepMin]~
PUB StepHour  | i, steps
  outa[directionHour]~~
  outa[sleepHour]~~                                                                                             
  steps:= stepHourAmount                    '1/16 microstepping gives 16*69.5 = 1112       'calibrated with grid lights on
  if t[2]==4 AND ina[hallHour]==1           'if we get to 4:00 and we haven't seen the hall effect sensor
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
    repeat i from 0 to 127                     'Calibrated 4/19/17   
      outa[steppingHour]~~     
      waitcnt(clkfreq/1000+cnt)
      outa[steppingHour]~      
      waitcnt(clkfreq/1000+cnt)                               
  else
    repeat i from 0 to steps           'Approximately 834 (12*69.5) full steps/rotation of the Hour Gear
      outa[steppingHour]~~
      waitcnt(clkfreq/1000+cnt)                                  
      outa[steppingHour]~                                 
      waitcnt(clkfreq/1000+cnt)

  outa[sleepHour]~
PUB leftGridLight  | i

  rgbLeftGrid.start(leftGridLightPin, 9)

  rgbLeftGrid.AllOff
  repeat i from 0 to 8
    rgbLeftGrid.LED(i,leftGridColor)

PUB rightGridLight  | i

  rgbRightGrid.start(rightGridLightPin, 9)

  rgbRightGrid.AllOff
  repeat i from 0 to 8
    rgbRightGrid.LED(i,rightGridColor)


{PUB StripLights   | i
  rgbStrip.start(stripLightData,TotalLEDs)
  rgbStrip.AllOff
  color[0]:= rgbStrip#orange
  color[1]:= rgbStrip#blue
  {
  repeat                                             
    repeat i from 0 to 56 step 2              'Second ticks
       rgbStrip.LED(i,rgbStrip#orange)
       waitcnt(clkfreq+cnt)
       rgbStrip.LED(i,0)
       rgbStrip.LED(i+1,rgbStrip#blue)
       waitcnt(clkfreq+cnt)
       rgbStrip.LED(i+1,0)
       
    rgbStrip.LED(58,rgbStrip#orange)                   'wait after the minute goes by for the last LED to turn off and reset the loop
    waitcnt(clkfreq+cnt)
    rgbStrip.LED(58,0)
    rgbStrip.LED(59,rgbStrip#blue)
    waitcnt((clkfreq-clkfreq/100)+cnt)
    rgbStrip.LED(59,0)
    'FancyPattern
    waitcnt(clkfreq/100+cnt)
  }
  repeat
    if(t[0] == 0)
        rgbStrip.AllOff
    rgbStrip.LED(t[0],color[(t[0]//2)])
    rgbStrip.LED(t[0]-1,0)
    waitcnt(clkfreq/100+cnt)
}
PUB InnerStripLights | i, currIntensity, addOneIntensity, addTwoIntensity, addThreeIntensity, lessOneIntensity, lessTwoIntensity, count
  rgbInner.AllOff
  count:=0
  'pst.start

  repeat i from -3 to maxInnerAddress+3
    currIntensity:=255
    addOneIntensity:=170
    lessOneIntensity:=170
    addTwoIntensity:=85
    lessTwoIntensity:=84
    addThreeIntensity:=0
    repeat until currIntensity == 170
      rgbInner.LEDint(i,InnerStripColor,currIntensity)
      rgbInner.LEDint(i-1,InnerStripColor,lessOneIntensity)
      rgbInner.LEDint(i-2,InnerStripColor,lessTwoIntensity)
      rgbInner.LEDint(i+1,InnerStripColor,addOneIntensity)
      rgbInner.LEDint(i+2,InnerStripColor,addTwoIntensity)
      rgbInner.LEDint(i+3,InnerStripColor,addThreeIntensity)
      currIntensity:=currIntensity-1
      lessOneIntensity:=lessOneIntensity-1
      lessTwoIntensity:=lessTwoIntensity-1
      addOneIntensity:=addOneIntensity+1
      addTwoIntensity:=addTwoIntensity+1
      addThreeIntensity:=addThreeIntensity+1
      'waitcnt( do lots of math to figure this out
      waitcnt(clkfreq/219+cnt)    'experimentally determined value to last 59s
      'count:=count+1
      'pst.dec(count)
      'pst.newLine

PUB OuterStripLights | i, currIntensity, addOneIntensity, addTwoIntensity, addThreeIntensity, lessOneIntensity, lessTwoIntensity, count
  rgbOuter.AllOff
  count:=0
  'pst.start

  repeat i from -3 to maxOuterAddress+3
    currIntensity:=255
    addOneIntensity:=170
    lessOneIntensity:=170
    addTwoIntensity:=85
    lessTwoIntensity:=84
    addThreeIntensity:=0
    repeat until currIntensity == 170
      rgbOuter.LEDint(i,OuterStripColor,currIntensity)
      rgbOuter.LEDint(i-1,OuterStripColor,lessOneIntensity)
      rgbOuter.LEDint(i-2,OuterStripColor,lessTwoIntensity)
      rgbOuter.LEDint(i+1,OuterStripColor,addOneIntensity)
      rgbOuter.LEDint(i+2,OuterStripColor,addTwoIntensity)
      rgbOuter.LEDint(i+3,OuterStripColor,addThreeIntensity)
      currIntensity:=currIntensity-1
      lessOneIntensity:=lessOneIntensity-1
      lessTwoIntensity:=lessTwoIntensity-1
      addOneIntensity:=addOneIntensity+1
      addTwoIntensity:=addTwoIntensity+1
      addThreeIntensity:=addThreeIntensity+1
      'waitcnt( do lots of math to figure this out
      waitcnt(clkfreq/223+cnt)        'experimentally determined value to last 59s
      'count:=count+1
      'pst.dec(count)
      'pst.newLine
      
PUB AutoCalibrateMin | currentMin, differenceMin, i, count

  outa[sleepMin]~~
  count:=0
  repeat until ina[hallMin] == 0
    outa[steppingMin]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[steppingMin]~      
    waitcnt(clkfreq/1000+cnt)
  repeat until ina[hallMin] == 1
    outa[steppingMin]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[steppingMin]~      
    waitcnt(clkfreq/1000+cnt)
    count:=count+1
  repeat until ina[hallMin] == 0
    outa[steppingMin]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[steppingMin]~      
    waitcnt(clkfreq/1000+cnt)
    count:=count+1

  repeat i from 0 to 200                  'then another 200 steps
    outa[steppingMin]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[steppingMin]~      
    waitcnt(clkfreq/1000+cnt)
  outa[sleepMin]~
  
  stepMinAmount:= count / 60
  'pst.dec(stepMinAmount)
  'pst.NewLine
  GetTime
  repeat until t[0] == 0
    GetTime
    'DisplayTime
    waitcnt(clkfreq/2+cnt)

  currentMin:= t[1]
  differenceMin:= currentMin - 22
  if(differenceMin < 0)
    differenceMin:= currentMin + 38

  outa[sleepMin]~~
  repeat i from 0 to stepMinAmount*differenceMin
    outa[steppingMin]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[steppingMin]~      
    waitcnt(clkfreq/1000+cnt)
  outa[sleepMin]~

PUB AutoCalibrateHour | currentHour, differenceHour, i, count
  outa[directionHour]~~
  outa[sleepHour]~~
  count:=0
  repeat until ina[hallHour] == 0
    outa[steppingHour]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[steppingHour]~      
    waitcnt(clkfreq/1000+cnt)
  repeat until ina[hallHour] == 1
    outa[steppingHour]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[steppingHour]~      
    waitcnt(clkfreq/1000+cnt)
    count:=count+1
  repeat until ina[hallHour] == 0
    outa[steppingHour]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[steppingHour]~      
    waitcnt(clkfreq/1000+cnt)
    count:=count+1

  repeat until ina[hallHour]==1            'step until we don't see the hall effect sensor
    outa[steppingHour]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[steppingHour]~      
    waitcnt(clkfreq/1000+cnt) 
  repeat i from 0 to 127                     'Calibrated 4/19/17   
    outa[steppingHour]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[steppingHour]~      
    waitcnt(clkfreq/1000+cnt)
  outa[sleepHour]~
  
  stepHourAmount:= count / 12
  'pst.dec(stepHourAmount)
  'pst.NewLine
  GetTime
  repeat until t[0] == 0
    GetTime
    'DisplayTime
    waitcnt(clkfreq/2+cnt)

  currentHour:= t[2]
  if(currentHour > 12)
    currentHour:=currentHour - 12
  differenceHour:= currentHour - 4
  if(differenceHour < 0)
    differenceHour:= currentHour + 8

  outa[sleepHour]~~
  repeat i from 0 to stepHourAmount*differenceHour
    outa[steppingHour]~~     
    waitcnt(clkfreq/1000+cnt)
    outa[steppingHour]~      
    waitcnt(clkfreq/1000+cnt)
  outa[sleepHour]~   
{PUB FancyPattern | x, i, j
  desired:=cnt+23*clkfreq
  'maxAddress:=59                               
  x:=2
  repeat j from 100 to 1000 step 100                              
    repeat i from 0 to maxAddress-x
      rgbStrip.SetSection(i,i+2,rgbStrip#red)    
      waitcnt(clkfreq/100+cnt)
      rgbStrip.SetSection(0,maxAddress-x,rgbStrip#off)
    x:=x+2
    repeat i from 0 to maxAddress-x
      rgbStrip.SetSection(i,i+2,rgbStrip#orange)
      waitcnt(clkfreq/100+cnt)
      rgbStrip.SetSection(0,maxAddress-x,rgbStrip#off) 
    x:=x+2  
    repeat i from 0 to maxAddress-x
      if j==1000
        waitcnt(clkfreq/100+cnt)
      rgbStrip.SetSection(i,i+2,rgbStrip#yellow)
      waitcnt(clkfreq/100+cnt)
      rgbStrip.SetSection(0,maxAddress-x,rgbStrip#off) 
    x:=x+2
    
  repeat i from maxAddress-x to maxAddress step 2
    rgbStrip.SetSection(i,i+2,rgbStrip#off)
    waitcnt(clkfreq/10+cnt)

   
  repeat i from maxAddress to 0
    rgbStrip.LED(i,rgbStrip#green)    
    waitcnt(clkfreq/50+cnt)
  repeat i from 0 to maxAddress-1
    rgbStrip.LED(i,rgbStrip#turquoise)    
    waitcnt(clkfreq/50+cnt)
  repeat i from maxAddress to 0
    rgbStrip.LED(i,rgbStrip#magenta)    
    waitcnt(clkfreq/50+cnt)
  repeat i from 0 to maxAddress-1
    rgbStrip.LED(i,rgbStrip#blue)    
    waitcnt(clkfreq/50+cnt)
     
                                  'Flip-flop pattern
  repeat i from 0 to maxAddress/2  
      rgbStrip.LED(maxAddress/2+i,rgbStrip#red)
      rgbStrip.LED(maxAddress/2-i,rgbStrip#red)     
      waitcnt(clkfreq/50+cnt) 
  repeat i from 0 to maxAddress/2
      rgbStrip.LED(i,rgbStrip#off)
      rgbStrip.LED(maxAddress-i,rgbStrip#off)   
      waitcnt(clkfreq/50+cnt)
  repeat i from 0 to maxAddress/2  
      rgbStrip.LED(maxAddress/2+i,rgbStrip#yellow)
      rgbStrip.LED(maxAddress/2-i,rgbStrip#yellow)     
      waitcnt(clkfreq/50+cnt) 
  repeat i from 0 to maxAddress/2
      rgbStrip.LED(i,rgbStrip#off)
      rgbStrip.LED(maxAddress-i,rgbStrip#off)   
      waitcnt(clkfreq/50+cnt)
  repeat i from 0 to maxAddress/2  
      rgbStrip.LED(maxAddress/2+i,rgbStrip#green)
      rgbStrip.LED(maxAddress/2-i,rgbStrip#green)     
      waitcnt(clkfreq/50+cnt) 
  repeat i from 0 to maxAddress/2
      rgbStrip.LED(i,rgbStrip#off)
      rgbStrip.LED(maxAddress-i,rgbStrip#off)   
      waitcnt(clkfreq/50+cnt)

  {
  waitcnt(clkfreq/100+cnt)
  rgbStrip.AllOff
  waitcnt((desired-cnt)+cnt)
  rgbStrip.LED(23,rgbStrip#blue)
  waitcnt(clkfreq+cnt)
  rgbStrip.LED(23,0)
  
  repeat i from 24 to 58 step 2
       rgbStrip.LED(i,rgbStrip#orange)
       waitcnt(clkfreq+cnt)
       rgbStrip.LED(i,0)
       rgbStrip.LED(i+1,rgbStrip#blue)
       waitcnt(clkfreq+cnt)
       rgbStrip.LED(i+1,0)
  }

    
PUB StPatDay | i
  repeat 1440                            'Second ticks
    repeat i from 0 to 56 step 2
       rgbStrip.LED(i,rgbStrip#green)
       waitcnt(clkfreq+cnt)
       rgbStrip.LED(i,0)
       rgbStrip.LED(i+1,rgbStrip#yellow)
       waitcnt(clkfreq+cnt)
       rgbStrip.LED(i+1,0)
       
    rgbStrip.LED(58,rgbStrip#green)                   'wait after the Hourute goes by for the last LED to turn off and reset the loop
    waitcnt(clkfreq+cnt)
    rgbStrip.LED(58,0)
    rgbStrip.LED(59,rgbStrip#yellow)
    waitcnt((clkfreq-clkfreq/100)+cnt)
    rgbStrip.LED(59,0)
    waitcnt(clkfreq/100+cnt)


  
PUB Vday | i
  repeat 1440                            'Second ticks
    repeat i from 0 to 56 step 2
       rgbStrip.LED(i,rgbStrip#red)
       waitcnt(clkfreq+cnt)
       rgbStrip.LED(i,0)
       rgbStrip.LED(i+1,rgbStrip#magenta)
       waitcnt(clkfreq+cnt)
       rgbStrip.LED(i+1,0)
       
    rgbStrip.LED(58,rgbStrip#red)                   'wait after the Hourute goes by for the last LED to turn off and reset the loop
    waitcnt(clkfreq+cnt)
    rgbStrip.LED(58,0)
    rgbStrip.LED(59,rgbStrip#magenta)
    waitcnt((clkfreq-clkfreq/100)+cnt)
    rgbStrip.LED(59,0)
    waitcnt(clkfreq/100+cnt)


  
PUB Halloween   | i
  repeat 1440                            'Second ticks
    repeat i from 0 to 56 step 2
       rgbStrip.LED(i,rgbStrip#orange)
       waitcnt(clkfreq+cnt)
       rgbStrip.LED(i,0)
       rgbStrip.LED(i+1,rgbStrip#violet)
       waitcnt(clkfreq+cnt)
       rgbStrip.LED(i+1,0)
       
    rgbStrip.LED(58,rgbStrip#orange)                   'wait after the minute goes by for the last LED to turn off and reset the loop
    waitcnt(clkfreq+cnt)
    rgbStrip.LED(58,0)
    rgbStrip.LED(59,rgbStrip#violet)
    waitcnt((clkfreq-clkfreq/100)+cnt)
    rgbStrip.LED(59,0)
    waitcnt(clkfreq/100+cnt)


  
PUB  FourthofJuly   | i 
  repeat 1440                            'Second ticks
    repeat i from 0 to 54 step 3
       rgbStrip.LED(i,rgbStrip#red)
       waitcnt(clkfreq+cnt)
       rgbStrip.LED(i,0)
       rgbStrip.LED(i+1,rgbStrip#blue)
       waitcnt(clkfreq+cnt)
       rgbStrip.LED(i+1,0)
       rgbStrip.LED(i+2,rgbStrip#white)
       waitcnt(clkfreq+cnt)
       rgbStrip.LED(i+2,0)
       
    rgbStrip.LED(57,rgbStrip#red)                   'wait after the minute goes by for the last LED to turn off and reset the loop
    waitcnt(clkfreq+cnt)
    rgbStrip.LED(57,0)
    rgbStrip.LED(58,rgbStrip#blue)
    waitcnt((clkfreq-clkfreq/100)+cnt)
    rgbStrip.LED(58,0)
    waitcnt(clkfreq/100+cnt)
     rgbStrip.LED(59,rgbStrip#white)
       waitcnt(clkfreq+cnt)
       rgbStrip.LED(59,0)
      waitcnt(clkfreq/100+cnt)

PUB DisableLights

  if ina[pauseLights] == 1
      outa[stripLightData]~
      outa[gridLightData]~
      waitcnt(clkfreq*5400+cnt)
      outa[stripLightData]~~
      outa[gridLightData]~~
      
}  
   