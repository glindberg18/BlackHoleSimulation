;; LindbergParlanHW10.nlogo, Greeley Lindberg and William Parlan
;; HW10 5/8/19
;; This model simulates a black hole eating a nearby star. This model also serves
;; as a demonstration and application of links, for they are a pivotal part
;; of the spiral motion.

breed [star-fragments star-fragment]
breed [stars star]
breed [black-holes black-hole]

patches-own [star-trail] ; flaming star trail that gives the star, star-fragments, and black hole a glow

globals [
  star-alive? ; holds whether or not the star has died
  star-size ; holds size of the star
  star-x ; holds xcor of the star
  star-y ; holds ycor of the star
]

;; sets up model
to setup
  clear-all
  ask patches [set pcolor black + 1]
  make-black-hole
  make-star
  make-star-fragments (fragments-released * star-size) / 50
  ask patches [
    set pcolor scale-color orange star-trail 0.1 5
  ]

  reset-ticks
end

;; runs the simulation
to go
  do-star-fragments
  do-star
  do-black-hole
  do-star-trail
  tick
end

;; makes the star
to make-star
  create-stars 1 [
    set star-alive? true
    set size 50
    set star-size 50
    set star-x max-pxcor
    set star-y max-pycor
    setxy star-x star-y
    set color orange
    set shape "circle"
    set heading towardsxy 0 0
    set pen-size 10
  ]
  make-link
end

;; makes the star-fragments that will break off from the star
to make-star-fragments [num-stars]
  create-star-fragments num-stars [
    setxy random-xcor random-ycor
    while [out-of-star?] [setxy random-xcor random-ycor]
    set shape "star"
    set size random-float 3 + 1
    set color orange
  ]
  make-link
end

;; makes the black hole --there are two turtles so the star-fragments will spiral at a faster rate than the star.
;; (see rotate procedure). The third is for the efficiency of the trace-average-spiral procedure.
to make-black-hole
  create-black-holes 3 [ ;;Black Hole
    set size 10
    setxy 0 0
    set color violet - 4
    set shape "circle"
  ]

end

;; creates a link between the black hole and the star-frangments and the star
to make-link
  ask stars [
    ask black-hole 1 [
        create-link-to myself [tie]
      ]
  ]
  ask star-fragments [
    if-else color = lime [
      ask black-hole 2 [
        create-link-to myself [tie]
      ]
    ]
    [
      ask black-hole 0 [
        create-link-to myself [tie]
      ]
    ]
  ]
  ask links [
    set tie-mode "fixed"
    hide-link
  ]
end

;; moves and creates new star-fragments
to do-star-fragments
  if ticks mod 10 = 0 and star-size > 0 [
    make-star-fragments (fragments-released * (star-size / 50))
  ]
  ask star-fragments [
    if on-eastern-edge? [
      set heading 270
      fd random-float 1
    ]
    set heading towardsxy 0 0
    if-else pen [do-pen]
    [fd ((speed / 1000) / size)]
    if disco-mode and ticks mod 10 = 0 [ set color color + ticks ]
    if not disco-mode [set color orange]
    set star-trail star-trail + 5
    if in-black-hole? [die]
  ]

end

;; moves the star
to do-star
  check-star-death
  ask stars [
    if size >= 0 [
      set size (size - (fragments-released / 1000))
      set star-size size
      set star-x xcor
      set star-y ycor
      if disco-mode and ticks mod 10 = 0 [ set color color + ticks ]
      if not disco-mode [set color orange]
      if-else pen [do-pen]
      [fd ((speed / 1000) / size)]
    ]
  ]
end

;; rotates the black hole and creates event horizon
to do-black-hole
  ask black-hole 0 [
    set star-trail star-trail + 5000
    rotate 1
  ]
  ask black-hole 1 [rotate 0.1]
end

;; colors the plane according the amount of star-trail or "glow"
to do-star-trail
  diffuse star-trail 0.7
  ask patches [
    if in-star? [set star-trail 35]
    set pcolor scale-color orange star-trail 0.1 8
    if disco-mode [set pcolor scale-color (ticks) star-trail 0.1 8]
    set star-trail star-trail * glow-rate / 100
  ]
end

;; traces the path of the star-fragments in cyan and the star in magenta
to do-pen
  let original-color color
  if pen [
    pd
    if-else shape = "star" [set color cyan]
    [set color magenta]
  ]
  fd ((speed / 1000) / size)
  if pen [
    pu
    set color original-color
  ]
end

;; kills the star if the star is either overlapping with the black hole or has a size of 0
to check-star-death
  ask patches [
    if overlap? and star-alive? [
      ask stars [
        set star-alive? false
        set size 0
        set star-size size
        die
      ]
    ]
  ]
  ask stars [
    if size <= 0 [
        die
        set star-alive? false
    ]
  ]
end

;; reports if the star-fragments have reached the black hole
to-report in-black-hole?
  report ([xcor] of turtle who) ^ 2 +
         ([ycor] of turtle who) ^ 2 < 25
end

;; reports if the star-fragments have spawned outside the star
to-report out-of-star?
    report ([xcor] of turtle who - star-x) ^ 2 +
           ([ycor] of turtle who - star-y) ^ 2 > (star-size / 2) ^  2
end

;; reports if the patches are within the star --used for setting star-trail and overlap
to-report in-star?
  report (pxcor - star-x) ^ 2 +
         (pycor - star-y) ^ 2 < (star-size / 2) ^  2
end

;; reports if the patches within the star are overlapping with black hole
to-report overlap?
  report in-star? and (pxcor) ^ 2 + (pycor) ^ 2 < 25
end

;; used to rotate the black hole to create a spiral shape as the star-fragments and star move forward
to rotate [angle]
 set heading heading + angle
end

;; checks if the star-fragments are stuck on the eastern wall
to-report on-eastern-edge?
  report [xcor] of turtle who > max-pxcor - 1
end

;; reports the number of live star-fragments
to-report number-of-fragments
  report count star-fragments
end

;; traces the path of the average spiral the fragments follow.
to trace-average-spiral
   create-star-fragments 1 [
    set color lime
    setxy star-x star-y
    set pen-size 5
    set size 2.5 ; 2.5 is the median size the possible star-fragments sizes
    set heading towardsxy 0 0
    make-link
    pd
    while [not in-black-hole?] [
      ask black-hole 2 [rotate 1]
      fd ((speed / 1000) / size)
    ]
    if in-black-hole? [die]
  ]
end

;; erases all pen markings
to erase-pen
  create-turtles 1 [
    hide-turtle
    set size 100
    setxy min-pxcor 0
    set heading 90
    set pen-size 1000
    pen-erase
    while [xcor != max-pxcor] [
      fd 1
    ]
    die
  ]
end

;; resets sliders and switches to their default setting
to reset-variables
  set glow-rate 80
  set fragments-released 10
  set speed 70
  set pen false
  set disco-mode false
end
@#$#@#$#@
GRAPHICS-WINDOW
372
16
784
429
-1
-1
4.0
1
10
1
1
1
0
0
0
1
-50
50
-50
50
1
1
1
ticks
30.0

BUTTON
114
19
180
52
Setup
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
190
19
253
52
Go
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
0

SWITCH
36
116
126
149
pen
pen
1
1
-1000

SLIDER
190
154
355
187
glow-rate
glow-rate
0
90
80.0
1
1
NIL
HORIZONTAL

SLIDER
189
195
356
228
speed
speed
20
500
70.0
10
1
NIL
HORIZONTAL

SLIDER
16
195
188
228
fragments-released
fragments-released
0
30
10.0
1
1
NIL
HORIZONTAL

BUTTON
89
74
281
107
Set Variables To Default
reset-variables
NIL
1
T
OBSERVER
NIL
R
NIL
NIL
1

SWITCH
17
155
179
188
disco-mode
disco-mode
1
1
-1000

MONITOR
227
239
358
284
NIL
number-of-fragments
17
1
11

PLOT
4
237
221
427
Star Fragments over Time
Ticks
Number of Fragments
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -955883 true "" "plot count star-fragments"

BUTTON
251
115
341
148
Erase Pen
erase-pen
NIL
1
T
OBSERVER
NIL
E
NIL
NIL
1

BUTTON
136
115
240
148
Trace Spiral
trace-average-spiral
NIL
1
T
OBSERVER
NIL
T
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

In light of the recent picture of a black hole, this project roughly simulates the accretion disk of a black hole. The black hole is located in the center of the view, and the large star is located in the top right corner. The star releases smaller star fragments over time, shrinking as it does so. The fragments spiral around the black hole until finally being destroyed in the center. Smaller star fragments move faster and therefore reach the black hole faster.

## HOW IT WORKS

By using links, a spiral motion can be achieved. Upon being created, the star fragments and the star are "tied" to the the black hole. The black hole then rotates, giving a cyclical path. Finally, the star fragments and the star move forward towards the black hole, thus following spiral. As such, the speed of the star and the star fragments will affect the tightness of the respective spiral they follow.

## QUESTIONS THIS MODEL ANSWERS

a) How do black holes eat a star?
b) What does an accretion disk look like?
c) How do links work?
d) How does speed affect the number of cycles a fragment takes?

## HOW TO USE IT

Click the SETUP button to set up the black hole (dark purple in the center) and main star (orange in top right).

Click the GO button to start the simulation.

Click the Set Variables to Default button to reset the sliders to suggested values and toggle the switches to be false.

Toggle the pen switch on to cause all turtles (star-fragments and main star) to begin drawing with a cyan colored pen.

Click the Trace Spiral button to trace the average path star fragments follow on the current speed setting.

Click Erase Pen to erase all pen markings, including the average spiral.

Toggle the disco-mode switch on to have all turtles (star-fragments and main star) to begin rapidly changing colors.

The glow-rate slider changes how fast the glowing effect around the turtles dissipates, higher number means a longer lasting glow.

The speed slider changes how quickly the stars move toward the black hole. Higher values will cause a nearly direct route to the black hole while lower numbers will cause fragments to spiral around longer.

The fragments-released slider modifies the rate of star fragments released. It should be noted that release of fragments is also impacted by the size of the star. The equation is (fragments-released * (star-size / 50)), where 50 fragments-released represemts the user-defined global, star-size represents the current size of the star, and 50 represents the original size of the star. A higher value of fragments-released means the star will release a higher amount of star fragments.

## THINGS TO NOTICE

a) Notice how the speed slider affects the tightness of the spiral.
b) Notice how the different sizes of fragments will move at different speeds and         reach the center faster or slower.
c) Notice how the fragments released over time will decrease as the main star            shrinks.
d) Notice how the main star starts to move and shrink along the path of the              fragments.
e) Notice how the star follows or deviates from the average spiral.

## THINGS TO TRY

a) Modify the sliders to see how  the variables change the path the fragments take.
b) Change the sliders at different times. Ex. start with low speed, but then increase    it while the program is running. Notice how the plot changes when you do this.
c) Try clicking Trace Spiral, changing the speed, and then clicking Trace Spiral again to compare spirals.


## EXTENDING THE MODEL

a) This model does not account for the acceleration due to gravity, meaning all          fragments move at a constant speed. Variance in speed according to fragment size      helped mend this, but it still isn't entirely accurate. Part of the problem is that black holes have supposedly infinite mass, which can't be calculated by a computer. Can you implement a more accurate equation than the one currently used?
b) Can you modify the model so the star starts in a different location?
c) Can you modify the model so the black hole is in a different location?

## NETLOGO FEATURES

This model combines links and turtles, the former to establish the circular loops and the latter to have the loops shrink until the fragments end up in the black hole. To get the best results, tie-mode "fixed" was used so that the movement of the fragments would not affect the black hole. This model also uses diffusion and a patches-own variable to create the glow effect.

## RELATED MODELS

Kicked Rotator has a similar usage of links as a rotational component.

## CREDITS AND REFERENCES

Concept, code, and design by Greeley Lindberg and William Parlan.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

star-piece
true
0
Polygon -7500403 true true 136 231 152 186 169 228 211 232 180 255 188 296 155 268 124 294 128 255 91 236 134 231
Polygon -7500403 true true 131 51 147 6 164 48 206 52 175 75 183 116 150 88 119 114 123 75 86 56 129 51
Polygon -7500403 true true 205 130 221 85 238 127 280 131 249 154 257 195 224 167 193 193 197 154 160 135 203 130
Polygon -7500403 true true 62 121 78 76 95 118 137 122 106 145 114 186 81 158 50 184 54 145 17 126 60 121

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
