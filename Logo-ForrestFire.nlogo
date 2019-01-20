globals [
  initial_trees       ;; how many trees (green patches) we started with
  burned_trees        ;; how many have burned so far
  R_max               ;; max fire spread in the whole world
  R_max_pow           ;; R_max^2 is used in every iteration and since it's contant, it can be pre-calculated
  patch_length        ;; Length of the patch used to adjust fire spread if needed
  max_ticks           ;; Special stopping condition for tests
]

;; burn coefficient of individual patch
;; 0: unburned
;; > 0: partially burned
;; 1: burned
patches-own [
  ;; new_burn_coef will be moved to burn_coef
  ;; after all patches are processed
  burn_coef
  new_burn_coef

  ;; rate of fire spread of given cell
  fire_spread
]

;; sets values in height and wind matrices display in the interface to 1
to reset-height-wind
  set height-NW 1
  set height-N 1
  set height-NE 1
  set height-W 1
  set height-C 1
  set height-E 1
  set height-SW 1
  set height-S 1
  set height-SE 1

  set wind-NW 1
  set wind-N 1
  set wind-NE 1
  set wind-W 1
  set wind-C 1
  set wind-E 1
  set wind-SW 1
  set wind-S 1
  set wind-SE 1
end

to setup
  clear-all

  ;; patch length is 10 meters
  set patch_length 10

  ;; max_ticks turned off by default
  set max_ticks -1

  ;; init height matrix
  ;; height matrix contains data adjust accordingly to model (h_i,j = f(H_center - H_i,j))
  ;; height matrix is constant in time
  ;; heights can be in range from 0 to 2 so that max(min) height difference is 2 (-2)
  ;; exp(dh) will then map this height difference to range from 0,3679 (downhill) to 2,7183 (uphill)
  ;;set height_matrix (list
  ;;  exp((height-NW - height-C) / 2.0)
  ;;  exp((height-N - height-C) / 2.0)
  ;;  exp((height-NE - height-C) / 2.0)
  ;;  exp((height-W - height-C) / 2.0)
  ;;  exp((height-C - height-C) / 2.0)
  ;;  exp((height-E - height-C) / 2.0)
  ;;  exp((height-SW - height-C) / 2.0)
  ;;  exp((height-S - height-C) / 2.0)
  ;;  exp((height-SE - height-C) / 2.0)
  ;; )
end

;; Setup the wrold without image
to setup-random
  ;; global setup
  setup

  ;; create forest ground (=dirt)
  ;; set burn coeficient to 0 for all patches
  ;; and color to brown (=dirt)
  ask patches
    [
      set burn_coef 0
      set new_burn_coef 0
      set fire_spread 0
  ]
end

;; Fire spread in forest of width 1.
;; Fire will spread from left to right.

to setup-test-horizontal
  ;; global setup
  setup

  ask patches [
    set pcolor brown
    set fire_spread 0
    set burn_coef 0
  ]

  ask patches with [pycor = 0 and pxcor <= -124] [
    set pcolor green
    set fire_spread (global-fire-spread)
  ]

  ;; set tree counts
  set initial_trees count patches with [pcolor = green]

  ;; start fire at -125 0
  ask patch -125 0 [
    set burn_coef 1
    set fire_spread global-fire-spread
    burn-out
  ]

  ;; set R_max
  set-r-max

  reset-ticks
end

;; Setup world for diagonal fire spread test
;; Fire will spread from NW to SE
to setup-test-diagonal
  ;; global setup
  setup

  ask patches [
    set pcolor brown
    set fire_spread 0
    set burn_coef 0
  ]

  ask patches with [(- pycor) = pxcor and pycor >= 124] [
    set pcolor green
    set fire_spread global-fire-spread
  ]

  ;; set tree counts
  set initial_trees count patches with [pcolor = green]

    ;; start fire at -125 125
  ask patch -125 125 [
    set burn_coef 1
    set fire_spread global-fire-spread
    burn-out
  ]

  ;; set R_max
  set-r-max

  reset-ticks
end

;; Setup homogenous world for tests as described in article
to setup-test-homogeneous
  ;; global setup
  setup

  ;; use patch length 1, same as R
  set patch_length 1

  ask patches [
    set pcolor green
    set fire_spread 1
    set burn_coef 0
  ]

  ;; set tree counts
  set initial_trees count patches with [pcolor = green]

  ;; start fire at points around center
  ask patches with [pxcor <= 0 and pxcor >= -1 and pycor <= 1 and pycor >= 0] [
    set burn_coef 1
    burn-out
    set pcolor white
  ]

  ;; set max_tick condition
  set max_ticks 124

  ;; set R_max
  set-r-max

  reset-ticks
end

;; Setup inhomogeneous world with R distributed accordingly to acrticle
to setup-test-inhomogeneous
  ;; global setup
  setup

  ;; set patch_length to 1 as its' length is not important for this test
  set patch_length 4.5

  ask patches [
    set fire_spread 0
    set burn_coef 0
  ]

  ;; R_i,j for II and I quandrant
  ask patches with [pycor > 0] [
    set pcolor green
    set fire_spread 1
  ]

  ;; R_i,j for III quadrant
  ask patches with [pxcor < 0 and pycor <= 0] [
    set pcolor green - 1
    set fire_spread 3
  ]

  ;; R_i,j for IV quadrant
  ask patches with [pxcor >= 0 and  pycor <= 0] [
    set pcolor green - 2
    set fire_spread 4.5
  ]

  ;; set tree counts
  set initial_trees count patches with [pcolor = green]

    ;; start fire at points around center
  ask patches with [pxcor <= 0 and pxcor >= -1 and pycor <= 1 and pycor >= 0] [
    set burn_coef 1
    burn-out
    set pcolor white
  ]

  ;; set max_tick condition
  set max_ticks 124

  ;; set R_max
  set-r-max

  reset-ticks
end

;; Load the world from image
;; following colors are used
;; paths, roads, buildings = white (255,255,255)
;; grass lands = green (89,176,60)
;; trees, woods = 63 (26,129,36)
;; water = sky (45,151,190)
;; dirt = brown
to setup-image
  ;; global setup
  setup

  ;; load image
  import-pcolors "img/source.bmp"

  ;; common values for all patches
  ask patches
  [
    set burn_coef 0
    set new_burn_coef 0
    set fire_spread 0
  ]

  ;; find paths
  ;; fire cannot spread through paths
  ask patches with [pcolor = white]
  [
    ;; currently 0 value is used for fire spread
    ;; might change later
    set fire_spread 0
  ]

  ;; find grass lands
  ;; fire spreads with different speed on grass than in the woods
  ask patches with [pcolor = green]
  [
    set fire_spread (global-fire-spread * 2)
  ]

  ;; find woods and add dirt accordingly to density
  ask patches with [pcolor = 63]
  [
    ifelse ((random-float 100) < density)
    [
      ;; patch is a tree
      set fire_spread global-fire-spread
    ]
    [
      ;; patch is a dirt
      set fire_spread 0
      set pcolor brown
    ]
  ]

  ;; find water
  ;; fire cannot spread through water
  ;; this piece of code is redundant but I'll keep it
  ;; here in case I'm going to try to set water on fire later
  ask patches with [pcolor = sky]
  [
    set fire_spread 0
  ]

  ;; set tree counts
  set initial_trees count patches with [pcolor = 63]

  ;; start a fire
  start-fire

  ;; set R_max
  set-r-max

  reset-ticks
end

;; starts fire on coordinates given by global variables
to start-fire
  set burned_trees 0
  ask patches with [pxcor = fire_start_x and pycor = fire_start_y]
    [
      set fire_spread global-fire-spread
      set burn_coef 1
      burn-out
  ]
end

;; Performs one step of fire spread (one iteration of whole cellular automata)
to fire-spread-step
  ;; select unburned or partially burned cells
  ask patches with [(burn_coef >= 0) and (burn_coef < 1) and (fire_spread > 0)]
  ;;ask patch 0 1
  [
    ;; see formula in the article at the end of section 3.1.
    let adj_burn 0
    let diag_burn 0

    ;; calculate burn area of neighbour cells
    ;; for evety ask patch-at, height matrix needs to be centerd on the asked patch (so that it's applied correctly)

    ;; burn area adjacent cells
    ;; height matrix      indexes
    ;;    NW N  NE         0 1 2
    ;;    W  C  E          3 4 5
    ;;    SW S  SE         6 7 8
    if patch-at 0 1 != nobody [ask patch-at 0 1 [set adj_burn (adj_burn + wind-N * height-N * burn_coef * fire_spread)]]                      ;; N
    if patch-at -1 0  != nobody [ask patch-at -1 0 [set adj_burn (adj_burn + wind-W * height-W * burn_coef * fire_spread)]]                   ;; W
    if patch-at 1 0 != nobody [ ask patch-at 1 0 [set adj_burn (adj_burn + wind-E * height-E * burn_coef * fire_spread)]]                     ;; W
    if patch-at 0 -1 != nobody [ask patch-at 0 -1 [set adj_burn (adj_burn + wind-S * height-S * burn_coef * fire_spread)]]                    ;; S

    ;; burn area of diagonal cells
    if patch-at -1 1 != nobody [ask patch-at -1 1 [set diag_burn diag_burn + wind-NW * height-NW * burn_coef * fire_spread * fire_spread]]    ;; NW
    if patch-at 1 1 != nobody [ask patch-at 1 1 [set diag_burn diag_burn + wind-NE * height-NE * burn_coef * fire_spread * fire_spread]]      ;; NE
    if patch-at -1 -1 != nobody [ask patch-at -1 -1 [set diag_burn diag_burn + wind-SW * height-SW * burn_coef * fire_spread * fire_spread]]  ;; SW
    if patch-at 1 -1 != nobody [ask patch-at 1 -1 [set diag_burn diag_burn + wind-SE * height-SE * burn_coef * fire_spread * fire_spread]]    ;; SE

    ;; total burned area
    let burned_area (((adj_burn / R_max) + (0.785 * diag_burn / R_max_pow)) * (R_max / patch_length))

    ;; burn_coef * R_ij/R + total burned area
    set new_burn_coef ((burn_coef * fire_spread / R_max) + burned_area)

    if (new_burn_coef < 0) [
      set new_burn_coef 0
    ]

    ;; assign color to patch
    color-burning-patch

    ;; burned out tree
    if (new_burn_coef >= 1) [
      burn-out
    ]
  ]

  ;; all patches processed => move new_burn_coef to burn_coef
  ask patches with [new_burn_coef > 0] [
    set burn_coef new_burn_coef
    set new_burn_coef 0
  ]
end

;; Performs one step and ticks
to do-one-step
  fire-spread-step

  tick
end

;; Main procecure
to go
  ;; variable used later for stop condition check
  let curr_burn_trees burned_trees

  ;; one iteration of cellular automata
  fire-spread-step

  ;; if no new trees were burned and no patches are burning (burn_coeficient > 0 but < 1), stop
  ;; also stop if max_ticks is set to > 0 and is equal to current tick count
  let burning_patches_count count patches with [burn_coef > 0 and burn_coef < 1]
  ifelse ((curr_burn_trees = burned_trees and  burning_patches_count = 0) or
    (max_ticks > 0 and max_ticks = ticks)) [
    stop
  ] [
    tick
  ]
end

;; Assigns color to the patch based on its' new_burn_coef
to color-burning-patch
  if (fire-multicolor) [
    ;; new tree has caught fire
    if (new_burn_coef > 0 and burn_coef = 0) [
      set pcolor yellow
    ]

    ;; set color accordingly to burn_coef
    if (new_burn_coef > 0.1 and new_burn_coef <= 0.6) [
      set pcolor orange
    ]
    if (new_burn_coef > 0.6 and new_burn_coef < 1) [
      set pcolor red
    ]
  ]
end

;; Burns the cell out and increments # of burned trees
;; sets its' color to black
;; and burn coef to 1
to burn-out
  set burned_trees burned_trees + 1
  set pcolor black
  set new_burn_coef 1
end

;; sets R_max and R_max_pow globals
to set-r-max
  ask max-one-of patches [fire_spread] [set R_max fire_spread]
  if (R_max = 0) [
    set R_max 1
  ]
  set R_max_pow R_max * R_max
end

; Copyright 1997 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
271
10
781
521
-1
-1
2.0
1
10
1
1
1
0
0
0
1
-125
125
-125
125
1
1
1
ticks
30.0

MONITOR
991
28
1106
73
percent burned
(burned_trees / initial_trees)\n* 100
1
1
11

SLIDER
7
12
192
45
density
density
0.0
99.0
77.0
1.0
1
%
HORIZONTAL

BUTTON
988
108
1057
144
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
795
108
907
144
Setup from file
setup-image
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
793
27
868
72
Initial trees
initial_trees
17
1
11

MONITOR
886
27
971
72
Burned trees
burned_trees
17
1
11

SLIDER
8
58
196
91
global-fire-spread
global-fire-spread
0
10
6.1
0.1
1
m/min
HORIZONTAL

INPUTBOX
11
176
70
236
height-NW
1.0
1
0
Number

INPUTBOX
79
176
133
236
height-N
1.0
1
0
Number

INPUTBOX
146
177
205
237
height-NE
1.0
1
0
Number

INPUTBOX
15
239
71
299
height-W
1.0
1
0
Number

INPUTBOX
146
240
201
300
height-E
1.0
1
0
Number

INPUTBOX
11
308
75
368
height-SW
1.0
1
0
Number

INPUTBOX
80
306
137
366
height-S
1.0
1
0
Number

INPUTBOX
143
305
204
365
height-SE
1.0
1
0
Number

INPUTBOX
80
242
133
302
height-C
1.0
1
0
Number

INPUTBOX
10
602
77
662
fire_start_x
-60.0
1
0
Number

INPUTBOX
91
602
157
662
fire_start_y
0.0
1
0
Number

BUTTON
795
151
907
187
Setup random
setup-random
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
15
388
70
448
wind-NW
1.0
1
0
Number

INPUTBOX
76
387
126
447
wind-N
1.0
1
0
Number

INPUTBOX
132
387
186
447
wind-NE
1.0
1
0
Number

INPUTBOX
17
455
67
515
wind-W
1.0
1
0
Number

INPUTBOX
77
454
127
514
wind-C
1.0
1
0
Number

INPUTBOX
134
456
184
516
wind-E
1.0
1
0
Number

INPUTBOX
18
526
76
586
wind-SW
1.0
1
0
Number

INPUTBOX
80
526
130
586
wind-S
1.0
1
0
Number

INPUTBOX
136
525
186
585
wind-SE
1.0
1
0
Number

BUTTON
794
200
960
233
Setup for horizontal test
setup-test-horizontal
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
794
245
952
278
Setup for diagonal test
setup-test-diagonal
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1073
111
1155
144
One step
do-one-step
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
990
160
1121
193
fire-multicolor
fire-multicolor
0
1
-1000

BUTTON
796
334
994
367
Setup for inhomogeneous test
setup-test-inhomogeneous
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
650
547
762
580
Save to image
export-view \"view.png\"
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
35
114
190
147
Reset height and wind
reset-height-wind
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
795
289
977
322
Setup for homogenous test
setup-test-homogeneous
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This project simulates the spread of a fire through a forest.  It shows that the fire's chance of reaching the right edge of the forest depends critically on the density of trees. This is an example of a common feature of complex systems, the presence of a non-linear threshold or critical parameter.

## HOW IT WORKS

The fire starts on the left edge of the forest, and spreads to neighboring trees. The fire spreads in four directions: north, east, south, and west.

The model assumes there is no wind.  So, the fire must have trees along its path in order to advance.  That is, the fire cannot skip over an unwooded area (patch), so such a patch blocks the fire's motion in that direction.

## HOW TO USE IT

Click the SETUP button to set up the trees (green) and fire (red on the left-hand side).

Click the GO button to start the simulation.

The DENSITY slider controls the density of trees in the forest. (Note: Changes in the DENSITY slider do not take effect until the next SETUP.)

## THINGS TO NOTICE

When you run the model, how much of the forest burns. If you run it again with the same settings, do the same trees burn? How similar is the burn from run to run?

Each turtle that represents a piece of the fire is born and then dies without ever moving. If the fire is made of turtles but no turtles are moving, what does it mean to say that the fire moves? This is an example of different levels in a system: at the level of the individual turtles, there is no motion, but at the level of the turtles collectively over time, the fire moves.

## THINGS TO TRY

Set the density of trees to 55%. At this setting, there is virtually no chance that the fire will reach the right edge of the forest. Set the density of trees to 70%. At this setting, it is almost certain that the fire will reach the right edge. There is a sharp transition around 59% density. At 59% density, the fire has a 50/50 chance of reaching the right edge.

Try setting up and running a BehaviorSpace experiment (see Tools menu) to analyze the percent burned at different tree density levels. Plot the burn-percentage against the density. What kind of curve do you get?

Try changing the size of the lattice (`max-pxcor` and `max-pycor` in the Model Settings). Does it change the burn behavior of the fire?

## EXTENDING THE MODEL

What if the fire could spread in eight directions (including diagonals)? To do that, use `neighbors` instead of `neighbors4`. How would that change the fire's chances of reaching the right edge? In this model, what "critical density" of trees is needed for the fire to propagate?

Add wind to the model so that the fire can "jump" greater distances in certain directions.

Add the ability to plant trees where you want them. What configurations of trees allow the fire to cross the forest? Which don't? Why is over 59% density likely to result in a tree configuration that works? Why does the likelihood of such a configuration increase so rapidly at the 59% density?

## NETLOGO FEATURES

Unburned trees are represented by green patches; burning trees are represented by turtles.  Two breeds of turtles are used, "fires" and "embers".  When a tree catches fire, a new fire turtle is created; a fire turns into an ember on the next turn.  Notice how the program gradually darkens the color of embers to achieve the visual effect of burning out.

The `neighbors4` primitive is used to spread the fire.

You could also write the model without turtles by just having the patches spread the fire, and doing it that way makes the code a little simpler.   Written that way, the model would run much slower, since all of the patches would always be active.  By using turtles, it's much easier to restrict the model's activity to just the area around the leading edge of the fire.

See the "CA 1D Rule 30" and "CA 1D Rule 30 Turtle" for an example of a model written both with and without turtles.

## RELATED MODELS

* Percolation
* Rumor Mill

## CREDITS AND REFERENCES

https://en.wikipedia.org/wiki/Forest-fire_model

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1997).  NetLogo Fire model.  http://ccl.northwestern.edu/netlogo/models/Fire.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was developed at the MIT Media Lab using CM StarLogo.  See Resnick, M. (1994) "Turtles, Termites and Traffic Jams: Explorations in Massively Parallel Microworlds."  Cambridge, MA: MIT Press.  Adapted to StarLogoT, 1997, as part of the Connected Mathematics Project.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.

<!-- 1997 2001 MIT -->
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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
set density 60.0
setup
repeat 180 [ go ]
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
