CON
_xinfreq=6_250_000
_clkmode=xtal1+pll16x
  pauseLights = 4
  CLK = 3
  SI = 2
  SO = 1
  CS = 0

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

  sleepMin   =   10
  steppingMin =  9
  directionMin = 8

  sleepHour =  13
  steppingHour =  12
  directionHour = 11
  hallHour = 14
  hallMin = 15 

  gridLightData = 17

  TotalLEDs=60
  stripLightData = 16
  maxAddress = 59
VAR
long desired, Stack1[100], Stack2[100], Stack3[100]
byte time[7], minOnce, hourOnce, endTime
long t[7]
long color[2]


OBJ
  rgbGrid : "RGB_LED_Strip_Driver"
  rgbStrip : "RGB_LED_Strip_Driver"
  pst : "PST_Driver"
  
PUB Main
' Set Directions
  dira[steppingMin]~~    
  dira[directionMin]~~   
  dira[sleepMin]~~
  dira[steppingHour]~~    
  dira[directionHour]~~   
  dira[sleepHour]~~
  dira[CS]~~
  dira[SI]~
  dira[SO]~~
  dira[CLK]~~  
  outa[CS]~~
  dira[stripLightData]~~
  dira[gridLightData]~~
  dira[pauseLights]~
  'dira[

'coginit(3,DisableLights,@Stack3)  

  'pst.start
  
  'This is to set the time--------------------------

  '7:52:45PM 4/19/16                                                  ' *10m  __m                            
  {time[0]:=4<<4 + 5                                  '_minutes=$01       'X_654_3210                                       
  time[1]:=5<<4 + 2                                                    '   1/0   1/0  *10hr  hr                              
  time[2]:=0<<6 + 0<<5 + 1<<4 + 9                    '_hour=$02          'X_12/24_PM/AM_4____3210                                          
  time[3]:=2                                                           '      day                                      
  time[4]:=1<<4 + 9                                  '_day=$03           'XXXXX_210                                         
  time[5]:=0<<7 + 0<<4 + 4                                             '   *10  date                                                 
  time[6]:=1<<4 + 6                                  '_date=$04          'XX_54___3210
  }
  '9:55:00PM 10/17/16 
  {time[0]:=0                                 '_minutes=$01       'X_654_3210                                       
  time[1]:=5<<4 + 5                                                    '   1/0   1/0  *10hr  hr                              
  time[2]:=0<<6 + 0<<5 + 2<<4 + 1                    '_hour=$02          'X_12/24_PM/AM_4____3210                                          
  time[3]:=1                                                           '      day                                      
  time[4]:=1<<4 + 7                                  '_day=$03           'XXXXX_210                                         
  time[5]:=0<<7 + 0<<4 + 10                                             '   *10  date                                                 
  time[6]:=1<<4 + 6                                  '_date=$04          'XX_54___3210                    
                                                                       'century   *10month month              
  SetTime }                                        '_month=$05         '7______XX_4________3210            
                                                                       '*10yr __yr                    
                                                     '_year=$06          '7654__3210
                       '                          day      1/0   1/0  10  hr     10m ___m     _seconds
                                        '  XXXXX_210___X_12/24_PM/AM_4_3210___X_654_3210___X_654_3210
  '                                        time[3]     time[2]                time[1]      time[0]
  'comment out the above time setting code for normal use----------------
   
  'repeat
    'GetTime
    'DisplayTime
    'waitcnt(clkfreq+cnt)
    'pst.ClearHome
    
  GridLights
  rgbStrip.start(stripLightData,TotalLEDs)
  rgbStrip.AllOff
  color[0]:= rgbStrip#orange
  color[1]:= rgbStrip#blue

  repeat
    if ina[pauseLights] == 1 'button pressed
      endTime:= t[1] -1
      rgbStrip.AllOff
      'rgbGrid.AllOff
      repeat until t[1] == endTime
        GetTime
        if t[0]==0 and minOnce==0
          StepMin
          minOnce:=1 
        if t[1]==0 and hourOnce==0 
          StepHour
          hourOnce:=1
        if t[1]==0 and ina[hallMin]==0                            'This code incorporates the hall effect sensors. We purposefully chose to spin
          repeat until ina[hallMin]==1                            'the motors in a way that the clock will be slower than the RTC time. Therefore,
            outa[steppingMin]~~                                   'every hour, the minute hand will be a little behind (59 minutes or so) and the 
            waitcnt(clkfreq/1000+cnt)                             'code will spin the minute hand until the hall effect sensor goes off. The same
            outa[steppingMin]~                                    'thing is done with the hour hand.                             
            waitcnt(clkfreq/1000+cnt)
        if (t[2]==12 or t[2]==24) and ina[hallHour]==0
          repeat until ina[hallHour]==1
            outa[steppingHour]~~
            waitcnt(clkfreq/1000+cnt)
            outa[steppingHour]~                                                                 
            waitcnt(clkfreq/1000+cnt)
        if t[0]==30
          minOnce:=0
        if t[1]==30
          hourOnce:=0
        if ina[pauseLights] == 1
          quit            
    GetTime
    DisplayTime
    'Motor Control:
    if t[0]==0 and minOnce==0
      StepMin
      minOnce:=1 
    if t[1]==0 and hourOnce==0 
      StepHour
      hourOnce:=1
    if t[1]==0 and ina[hallMin]==0                            'This code incorporates the hall effect sensors. We purposefully chose to spin
      repeat until ina[hallMin]==1                            'the motors in a way that the clock will be slower than the RTC time. Therefore,
        outa[steppingMin]~~                                   'every hour, the minute hand will be a little behind (59 minutes or so) and the 
        waitcnt(clkfreq/1000+cnt)                             'code will spin the minute hand until the hall effect sensor goes off. The same
        outa[steppingMin]~                                    'thing is done with the hour hand.                             
        waitcnt(clkfreq/1000+cnt)
    if (t[2]==12 or t[2]==24) and ina[hallHour]==0
      repeat until ina[hallHour]==1
        outa[steppingHour]~~
        waitcnt(clkfreq/1000+cnt)
        outa[steppingHour]~                                                                 
        waitcnt(clkfreq/1000+cnt)
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
    if t[4]==17 and t[5]==3
      StPatDay
    if t[4]==14 and t[5]==2
      Vday
    if t[4]==4 and t[5]==7
      FourthofJuly
    if t[0]==30
      minOnce:=0
    if t[1]==30
      hourOnce:=0
       
    'Tick Tock:
    if(t[0] == 0)
        rgbStrip.AllOff
    rgbStrip.LED(t[0],color[(t[0]//2)])
    rgbStrip.LED(t[0]-1,0)
    waitcnt(clkfreq/100+cnt)
    
  'coginit(2,StepHour,@Stack2)

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
  'StripLights

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
  t[2]:=(time[2]>>5)*20 + (time[2] & $10)*10 + (time[2] & %1111)    'hours
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
      
PUB StepMin | i
  outa[directionMin]~      '13V and 
  'outa[sleepMin]~~

  outa[sleepMin]~~
  'repeat
    repeat i from 1 to 32           '200 steps total for motor. based on gear ratio, 32 steps should spin hour gear 1/60th of its circumference
      outa[steppingMin]~~
      waitcnt(clkfreq/1000+cnt)
      outa[steppingMin]~                                   '126 teeth on big minute gear                                
      waitcnt(clkfreq/1000+cnt)
  'outa[steppingMin]~
    outa[sleepMin]~
  'waitcnt(clkfreq+cnt)  
PUB StepHour  | i
  outa[directionHour]~      '13V and 
  'outa[sleepHour]~~

  outa[sleepHour]~~
  'repeat
    repeat i from 1 to 76           '200 steps total for motor. based on gear ratio, 76 steps should spin hour gear 1/12th of its circumference 
      outa[steppingHour]~~
      waitcnt(clkfreq/1000+cnt)                                   '60 teeth on hour gear
      outa[steppingHour]~                                 
      waitcnt(clkfreq/1000+cnt)
  'outa[steppingHour]~
    outa[sleepHour]~
  'waitcnt(clkfreq+cnt)  

PUB GridLights  | i

  rgbGrid.start(gridLightData, 18)

  rgbGrid.AllOff
  repeat i from 0 to 8
    rgbGrid.LED(i,rgbGrid#orange)
  repeat i from 9 to 17
    rgbGrid.LED(i,rgbGrid#blue)

PUB StripLights   | i
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
  
PUB FancyPattern | x, i, j
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
       
    rgbStrip.LED(58,rgbStrip#green)                   'wait after the minute goes by for the last LED to turn off and reset the loop
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
       
    rgbStrip.LED(58,rgbStrip#red)                   'wait after the minute goes by for the last LED to turn off and reset the loop
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
      lightsOff := 1
      outa[stripLightData]~
      outa[gridLightData]~
      waitcnt(clkfreq*5400+cnt)
      outa[stripLightData]~~
      outa[gridLightData]~~
      
  
   