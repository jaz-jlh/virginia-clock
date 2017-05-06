CON
_xinfreq=6_250_000
_clkmode=xtal1+pll16x

innerLEDs = 127
maxInnerAddress = 126
outerLEDs = 129
maxOuterAddress = 128

OBJ
  rgbInner : "WS2812B_RGB_LED_Driver_v2"
  rgbOuter : "WS2812B_RGB_LED_Driver_v2"
  pst : "PST_Driver"

VAR
long Stack5[100]
PUB Main | i
  coginit(5,OuterStripLights,@Stack5)
  InnerStripLights
  

PUB InnerStripLights | i, currIntensity, addOneIntensity, addTwoIntensity, addThreeIntensity, lessOneIntensity, lessTwoIntensity, count
  rgbInner.start(0,innerLEDs)
  rgbInner.AllOff
  waitcnt(clkfreq+cnt)
  count:=0
  'pst.start

'repeat
  repeat i from -3 to maxInnerAddress+3
    currIntensity:=255
    addOneIntensity:=170
    lessOneIntensity:=170
    addTwoIntensity:=85
    lessTwoIntensity:=84
    addThreeIntensity:=0
    repeat until currIntensity == 170
      rgbInner.LEDint(i,rgbInner#orange,currIntensity)
      rgbInner.LEDint(i-1,rgbInner#orange,lessOneIntensity)
      rgbInner.LEDint(i-2,rgbInner#orange,lessTwoIntensity)
      rgbInner.LEDint(i+1,rgbInner#orange,addOneIntensity)
      rgbInner.LEDint(i+2,rgbInner#orange,addTwoIntensity)
      rgbInner.LEDint(i+3,rgbInner#orange,addThreeIntensity)
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
  rgbOuter.start(1,outerLEDs)
  rgbOuter.AllOff
  waitcnt(clkfreq+cnt)
  count:=0
  'pst.start

'repeat
  repeat i from -3 to maxOuterAddress+3
    currIntensity:=255
    addOneIntensity:=170
    lessOneIntensity:=170
    addTwoIntensity:=85
    lessTwoIntensity:=84
    addThreeIntensity:=0
    repeat until currIntensity == 170
      rgbOuter.LEDint(i,rgbInner#blue,currIntensity)
      rgbOuter.LEDint(i-1,rgbInner#blue,lessOneIntensity)
      rgbOuter.LEDint(i-2,rgbInner#blue,lessTwoIntensity)
      rgbOuter.LEDint(i+1,rgbInner#blue,addOneIntensity)
      rgbOuter.LEDint(i+2,rgbInner#blue,addTwoIntensity)
      rgbOuter.LEDint(i+3,rgbInner#blue,addThreeIntensity)
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
      

