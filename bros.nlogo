globals [hunger_rate ]

breed [warm-peeps warm-peep]
breed [cold-peeps cold-peep]
breed [snacks snack]

warm-peeps-own [
  vision-points
  peep-heat
  peep-life
  peep-birth  
  insulation
  last-patch
  
  ; peep genome
  vision
  metabolism
  search-tolerance
  rep-energy-constant  
  
]

cold-peeps-own [
  vision-points
  speed
  peep-heat
  eat-rate  
  peep-life
  peep-birth  
  insulation
  last-patch
  
  ; peep genome
  vision
  metabolism
  search-tolerance
  rep-energy-constant
]

snacks-own [
  snack-heat
  snack-life
  snack-birth
  snack-sprout-locs
  snack-sprout-time
  snack-last-sprout
]

patches-own [
  patch-heat
]

;; ===========================================================================
;; Setup Procedures                                                          =
;; ===========================================================================

to record-setup
  
  let movie_name word movie-name ".mov"
  movie-start movie_name
  movie-set-frame-rate 30
  setup
end

to setup
  clear-all
  reset-ticks
  set hunger_rate 0.02
  
  create-warm-peeps (num-warm-peeps) [ peep-setup true ]
  create-cold-peeps (num-cold-peeps) [ peep-setup true ]
  create-snacks (num-warm-snacks) [ warm-snack-setup true] 
  create-snacks (num-cold-snacks) [ cold-snack-setup true] 
  setup-patches
end

to peep-setup [rand_flag] ;; sets up both warm- and cold-peeps
  rt 5
  set vision random-in-range 15 25 ; L^infty radius
  set vision-points [] ; list of points (relative to the peep) for vision checks

  foreach n-values vision [?] [
     let x1 (? + 1)
     set vision-points sentence vision-points (list (list 0 x1) (list x1 0) (list 0 (- x1)) (list (- x1) 0))
     foreach n-values vision [? + 1] [
       set vision-points sentence vision-points (list (list x1 ?) (list ? x1) (list x1 (- ?)) (list (- ?) x1) (list (- x1) ?) (list ? (- x1)) (list (- x1) (- ?)) (list (- ?) (- x1)))
     ]
   ]

  ifelse is-warm-peep? self
  [ 
    set peep-heat ((random-float 1) * max-init-peep-heat)
    ]  
  [ 
    set peep-heat (- (random-float 1) * max-init-peep-heat)
    ]
  set color white
  set shape "circle"
  
  set metabolism 1 * (0.2 + random-float 0.8)
  
  if rand_flag[
    move-to one-of patches with [(not any? other warm-peeps-here) and (not any? cold-peeps-here) and (not any? snacks-here)] ]
  
  set peep-life random-normal peep-life-mean peep-life-sd
  set peep-birth 0
  
  set insulation random-gamma 4 40
  
  set search-tolerance 0.15 + random-float 0.1
  set rep-energy-constant 5 + random-float 5
  set last-patch patch-here
  hide-turtle
end


to warm-snack-setup [rand_flag] ;; snack procedure
  let tval (max (list (- 0.08) ( 1.8 * atanh ( (ticks / num-frames) - 0.2 ) ) ))
  set snack-heat (random-exponential ((1 + 8 * tval) * snack-heat-mean))
  if random-float 1 < (0.025 + 0.025 * ticks / num-frames)
  [
    set snack-heat ((1 + (12 * ticks / num-frames )) * snack-heat)
  ]
    
  set snack-life random-poisson snack-life-mean
  set snack-birth ticks
  set snack-sprout-time (random-exponential snack-sprout-interval-mean)
  set snack-last-sprout ticks
  
  set snack-sprout-locs []
  foreach n-values snack-sprout-radius [?] [
     let x1 (? + 1)
     set snack-sprout-locs sentence snack-sprout-locs (list (list 0 x1) (list x1 0) (list 0 (- x1)) (list (- x1) 0))
     foreach n-values snack-sprout-radius [?] [
       let y1 (? + 1)
       set snack-sprout-locs sentence snack-sprout-locs (list (list x1 y1) (list x1 (- y1)) (list (- x1) y1) (list (- x1) (- y1)))
     ]
   ]
  
  hide-turtle
  ;set color red
  ;set shape "star"
  
  if rand_flag [
    move-to one-of patches with [ (not any? other snacks-here) and (not any? warm-peeps-here) and (not any? cold-peeps-here) ]]
end

to cold-snack-setup [rand_flag] ;; snack procedure
  let tval (max (list (- 0.08) ( 1.8 * atanh ( (ticks / num-frames) - 0.2 ) ) ))
  set snack-heat (- random-exponential ((1 + 8 * tval) * snack-heat-mean))
  if random-float 1 < (0.025 + 0.025 * ticks / num-frames)
  [
    set snack-heat ((1 + (12 * ticks / num-frames )) * snack-heat)
  ] 
    
  set snack-life random-poisson snack-life-mean
  set snack-birth ticks
  set snack-sprout-time (random-exponential snack-sprout-interval-mean)
  set snack-last-sprout ticks
  
  set snack-sprout-locs []
  foreach n-values snack-sprout-radius [?] [
     let x1 (? + 1)
     set snack-sprout-locs sentence snack-sprout-locs (list (list 0 x1) (list x1 0) (list 0 (- x1)) (list (- x1) 0))
     foreach n-values snack-sprout-radius [?] [
       let y1 (? + 1)
       set snack-sprout-locs sentence snack-sprout-locs (list (list x1 y1) (list x1 (- y1)) (list (- x1) y1) (list (- x1) (- y1)))
     ]
   ]
  
  hide-turtle
  ;set color red
  ;set shape "star"
  if rand_flag [
    move-to one-of patches with [ (not any? other snacks-here) and (not any? warm-peeps-here) and (not any? cold-peeps-here) ]
  ]
  
end

to setup-patches ;; patch setup
  foreach sort patches [
    ask ? [
      set patch-heat 0
      set pcolor heat-to-color patch-heat
    ]
  ]
end
  
;; =============================================================================
;; Runtime Procedures                                                          =
;; =============================================================================

to go
  diffuse patch-heat 1
  if (paint-type != "none") [paint-now]
  
  if ticks = num-frames [
    ask snacks [die]]
  
  if not (any? warm-peeps or any? cold-peeps) 
  [
    ;print "done"
    ;stop
    set sprout-success-rate 0
  ]
  
  ask (turtle-set warm-peeps cold-peeps)
  [
    if (ticks - peep-birth) > peep-life ; age check
      [ die ]
    
    ifelse is-warm-peep? self
    [ 
      warm-peep-move
      warm-peep-eat  
      ]
    [ 
      cold-peep-move
      cold-peep-eat
      ]
    
    peep-baby-check

    if abs peep-heat < 0.01
      [ die ]
  ]
  
  ask snacks [ 
    if (ticks - snack-birth) > snack-life-mean [die]
    set patch-heat (patch-heat + snack-heat * (1 + 4 * (ticks - snack-birth) / snack-life-mean))
   
    if (ticks - snack-last-sprout) > snack-sprout-time
    [
      ifelse snack-heat > 0 
      [
        if random-float 1 < sprout-success-rate * (0.1 + 80 / (count snacks with [snack-heat > 0]))
        [
          ifelse random-float 1 < rand-sprout-rate
          [ 
            ask (one-of patches with [not any? snacks-here]) [sprout-snacks 1 [warm-snack-setup false]]
          ]
          [
            let true_radius (snack-sprout-radius + min (list max-pxcor (exp (0.05 * snack-heat))))
            let dxx (- true_radius + random (true_radius + 1))
            let dyy (- true_radius + random (true_radius + 1))
            let sprout-patch (patch-at dxx dyy)
            if not any? turtles-on sprout-patch [ask sprout-patch [ sprout-snacks 1 [ warm-snack-setup false ]]]           
            ;let sprout-candidates (patch-set (patches at-points snack-sprout-locs) with [not any? snacks-here])
            ;if any? sprout-candidates [ask (one-of sprout-candidates) [ sprout-snacks 1 [ warm-snack-setup false ]]]
          ]
        ]
      ]
      [
        if random-float 1 < sprout-success-rate * (0.1 + 80 / (count snacks with [snack-heat < 0]))
        [
          ifelse random-float 1 < rand-sprout-rate
          [ 
            ask (one-of patches with [not any? snacks-here]) [sprout-snacks 1 [cold-snack-setup false]]
          ]
          [
            let true_radius (snack-sprout-radius + min (list max-pxcor (exp (0.05 * (- snack-heat)))))
            let dxx (- true_radius + random (true_radius + 1))
            let dyy (- true_radius + random (true_radius + 1))
            let sprout-patch (patch-at dxx dyy)
            if not any? turtles-on sprout-patch [ask sprout-patch [ sprout-snacks 1 [ cold-snack-setup false ]]]  
            ;let sprout-candidates (patch-set (patches at-points snack-sprout-locs) with [not any? snacks-here])
            ;if any? sprout-candidates [ask (one-of sprout-candidates) [ sprout-snacks 1 [ cold-snack-setup false ]]]
          ]
        ]
      ]
      
      set snack-last-sprout ticks
      set snack-sprout-time (random-exponential snack-sprout-interval-mean)
    ]
  ]

  ; The following commented-out code sets the boundary of the display to 0
  ;ask (patch-set patches with [pxcor = min-pxcor or pxcor = max-pxcor or pycor = min-pycor or pycor = max-pycor])
  ;[
  ;  set patch-heat 0
  ;]
  ask patches
  [
    set pcolor heat-to-color patch-heat
  ]

  tick
end

to warm-peep-eat
  ifelse any? snacks-here
  [
    let the_snack (one-of snacks-here)
    set peep-heat (max (list (peep-heat - (hunger_rate * metabolism) + 20 * ([snack-heat] of the_snack)) 0))
    ask the_snack [ die ]
  ]
  [
    let diff (insulation * (([patch-heat] of patch-here) - peep-heat))
    ask patch-here [ set patch-heat (patch-heat - diff) ]
    set peep-heat heat-transfer peep-heat diff
  ]
  
end

to warm-peep-move
  let move-candidates (patch-set (patches at-points vision-points) with [not (any? warm-peeps-here or any? cold-peeps-here)])
  let possible-winner (move-candidates with [any? snacks-here ])
  let possible-hottest (move-candidates with-max [patch-heat])
  
  ifelse any? possible-winner
  [
    let warm-winners possible-winner with [any? snacks-here with [snack-heat > 0] ]
    let winner min-one-of warm-winners [distance myself]
    if any? (patch-set winner)
    [
      face winner
      fd (min (list peep-speed (distance winner)))
    ]

  ]
  [ ifelse any? possible-hottest
  [
    let hottest  min-one-of possible-hottest [distance myself]
    
    ifelse patch-warm-peep-comp ([patch-heat] of patch-here) ([patch-heat] of hottest) peep-heat
    [ 
      face hottest
      fd (min (list peep-speed (distance hottest))) 
      ]
    [ 
      rt random 25 - random 25
      fd peep-speed
      ]

  ]
  [
    print "womp warm"
    rt random 25 - random 25
    fd peep-speed
  ]
  ]
  if last-patch = patch-here [
    rt random 25 - random 25
    fd peep-speed / 4
    ]
  set last-patch patch-here
end

to cold-peep-eat
  ifelse any? snacks-here
  [
    let the_snack (one-of snacks-here)
    set peep-heat (min (list (peep-heat + (hunger_rate * metabolism) + 20 * ([snack-heat] of the_snack)) 0))
    ask the_snack [ die ]
  ]
  [
    let diff (insulation * (([patch-heat] of patch-here) - peep-heat))
    ask patch-here [ set patch-heat (patch-heat - diff) ]
    set peep-heat cold-transfer peep-heat diff
  ]
  
  ;set color heat-to-color peep-heat
end

to cold-peep-move
  let move-candidates (patch-set (patches at-points vision-points) with [not (any? warm-peeps-here or any? cold-peeps-here)])
  let possible-winner move-candidates with [any? snacks-here and patch-heat < 0]
  let possible-coldest move-candidates with-min [patch-heat]
  
  ifelse any? possible-winner
  [
    let cold-winners possible-winner with [any? snacks-here with [snack-heat < 0] ]
    let winner min-one-of cold-winners [distance myself]
    if any? (patch-set winner)
    [
      face winner
      fd (min (list peep-speed (distance winner)))
    ]

  ]
  [ ifelse any? possible-coldest
  [
    let coldest min-one-of possible-coldest [distance myself]
    
    ifelse patch-cold-peep-comp ([patch-heat] of patch-here) ([patch-heat] of coldest) (peep-heat)
    [ 
      face coldest
      fd (min (list peep-speed (distance coldest))) 
      ]
    [ 
      rt random 25 - random 25
      fd peep-speed
      ]

  ]
  [
    print "womp cold"
    rt random 25 - random 25
    fd peep-speed
  ]
  ]
  if last-patch = patch-here [
    rt random 25 - random 25
    fd peep-speed / 4
  ]
  set last-patch patch-here
  
end

to peep-baby-check ;; If a peep is old enough and has enough energy stored up, it reproduces
  let puberty 100 ; number of ticks until reproduction is possible
  if abs(peep-heat) > rep-energy-constant * 100 and ticks - peep-birth >= puberty
  [
    hatch 1 [ hatch-mutations ]
    set peep-heat (peep-heat / 2)
  ]
end

to hatch-mutations
  set vision (vision + random-in-range -1 1)
  set search-tolerance (search-tolerance - 0.025 + random-float 0.05)
  set peep-heat (peep-heat / 4)
  set peep-life random-normal peep-life-mean peep-life-sd
  set peep-birth ticks
end


;; =============================================================================
;; Utilities                                                                   =
;; =============================================================================

to-report random-in-range [low high] ;; pretty basic
  report low + random (high - low + 1)
end

to-report atanh [ x ]
  report 0.5 * ln ( (1 + x) / (1 - x) )
end

to-report heat-to-color [heat] ;; map heat to color!
  let grade 8
  ifelse heat < 0
  [ 
    ;let thresh_constant 10 * ((- (max (list 0 (1 * ((abs heat) - funky-cutoff))) ^ color_scaling_parameter)) mod color_range)
    let thresh_constant 10 * (((abs (- heat - funky-cutoff)) ^ color_scaling_parameter) mod color_range)
    report (10 * (1 + 8) + c_offset_1 mod color_range) + c_sat_1 + (1 / grade) * ((- heat + 0) mod (grade * (c_sat_2 - c_sat_1 + 1))) + color-cutoff(- heat) * thresh_constant
  ]
  [ 
    let thresh_constant 10 * (((abs (heat - funky-cutoff)) ^ color_scaling_parameter) mod color_range)
    report (10 * (1 + 1) + c_offset_1 mod color_range) + c_sat_1 + (1 / grade) * ((heat + 0) mod (grade * (c_sat_2 - c_sat_1 + 1)))  + color-cutoff(heat) * thresh_constant
  ]
  
end

to-report patch-warm-peep-comp [here_heat hottest_heat peep_heat]
  ifelse hottest_heat > 0 [
    ifelse here_heat <= 0 or (hottest_heat - here_heat > search-tolerance * peep_heat and hottest_heat > peep_heat)
        [report true]
        [report false]
    ]
    
  [ ifelse (hottest_heat < 0) and (abs here_heat - abs hottest_heat > search-tolerance * peep_heat)
      [report true]
      [report false]
  ]
end

to-report patch-cold-peep-comp [here_heat coldest_heat peep_heat]
  ifelse coldest_heat < 0 [
    ifelse here_heat >= 0 or (abs coldest_heat - abs here_heat > search-tolerance * abs peep_heat and coldest_heat < peep_heat)
        [report true]
        [report false]
       
    ]
    
  [ ifelse (coldest_heat > 0) and (abs here_heat) - (abs coldest_heat) > search-tolerance * abs peep_heat
      [report true]
      [report false]
  ]
end

to-report heat-transfer [heat diff]
  report max (list (heat - hunger_rate * metabolism + ((0.15 / (1 + exp(- 1 * (abs diff - 0.1 * heat)))) * diff)) 0)
end

to-report cold-transfer [heat diff]
  report min (list (heat + hunger_rate * metabolism + ((0.15 / (1 + exp(- 1 * (abs diff - 0.1 * abs heat)))) * diff)) 0)
end

to-report color-cutoff [heat]
  report (1 / (1 + exp (- 0.09 * (heat - funky-cutoff))))
;  ifelse heat > funky-cutoff
;  []
;  [report 0]
end

to paint-now
  if mouse-down?
  [
    ifelse paint-type = "heat"[
      foreach (n-values (2 * paint-radius + 1) [mouse-xcor - paint-radius + ?])
      [
        let x1 ?
        foreach (n-values (2 * paint-radius + 1) [mouse-ycor - paint-radius + ?] )
        [
          ask (patch x1 ?) [ set patch-heat paint-heat ]
        ]
      ]
    ]
    [
      ifelse (paint-type = "snacks") and (not any? turtles-on (patch mouse-xcor mouse-ycor)) [ ask (patch mouse-xcor mouse-ycor) [
        ifelse paint-heat > 0 
          [sprout-snacks 1 [ warm-snack-setup false
                             set snack-heat paint-heat ] ]
          [sprout-snacks 1 [ cold-snack-setup false
                             set snack-heat paint-heat ] ]
    ]]
    [ 
      if (paint-type = "peeps") and (not any? turtles-on (patch mouse-xcor mouse-ycor)) [ ask (patch mouse-xcor mouse-ycor) [
        ifelse paint-heat > 0
          [sprout-warm-peeps 1 [ peep-setup false
                                 set peep-heat paint-heat ] ]
          [sprout-cold-peeps 1 [ peep-setup false
                                 set peep-heat paint-heat ] ]
      ]
      ]
    ]
    ]
  ]
           
end
@#$#@#$#@
GRAPHICS-WINDOW
177
10
700
330
256
144
1.0
1
10
1
1
1
0
1
1
1
-256
256
-144
144
0
0
1
ticks
30.0

SLIDER
2
70
174
103
num-warm-peeps
num-warm-peeps
0
50
12
1
1
NIL
HORIZONTAL

SLIDER
2
111
174
144
num-cold-peeps
num-cold-peeps
0
50
12
1
1
NIL
HORIZONTAL

SLIDER
907
92
1079
125
snack-sprout-interval-mean
snack-sprout-interval-mean
1
100
15
1
1
NIL
HORIZONTAL

SLIDER
904
10
1076
43
num-warm-snacks
num-warm-snacks
0
100
30
1
1
NIL
HORIZONTAL

SLIDER
2
154
174
187
max-init-peep-heat
max-init-peep-heat
1
100
12
1
1
NIL
HORIZONTAL

SLIDER
907
132
1079
165
snack-heat-mean
snack-heat-mean
1
200
20
1
1
NIL
HORIZONTAL

SLIDER
907
172
1079
205
snack-life-mean
snack-life-mean
10
1000
610
1
1
NIL
HORIZONTAL

SLIDER
2
199
174
232
peep-life-mean
peep-life-mean
100
2000
342
1
1
NIL
HORIZONTAL

SLIDER
2
241
174
274
peep-life-sd
peep-life-sd
1
500
36
1
1
NIL
HORIZONTAL

BUTTON
2
33
66
66
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

SLIDER
2
283
174
316
peep-speed
peep-speed
0.1
10
1.4
0.1
1
NIL
HORIZONTAL

BUTTON
80
33
143
66
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
1

SLIDER
1080
10
1250
43
color_scaling_parameter
color_scaling_parameter
0
1.5
0.44
0.01
1
NIL
HORIZONTAL

PLOT
705
315
905
465
Heat plot
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "if any? warm-peeps [plot [peep-heat] of one-of (warm-peeps with-min [who])]"
"pen-1" 1.0 0 -13345367 true "" "if any? cold-peeps [plot [peep-heat] of one-of cold-peeps with-min [who]]"

PLOT
705
15
905
165
Peep count
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot count warm-peeps"
"pen-1" 1.0 0 -13345367 true "" "plot count cold-peeps"

PLOT
705
165
905
315
Snack count
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"pen-1" 1.0 0 -13345367 true "" "plot count (snacks with [ snack-heat < 0 ])"
"pen-2" 1.0 0 -2674135 true "" "plot count (snacks with [ snack-heat > 0 ])"

SLIDER
1079
49
1251
82
c_offset_1
c_offset_1
0
11
0
1
1
NIL
HORIZONTAL

SLIDER
1079
89
1251
122
color_range
color_range
2
13
9
1
1
NIL
HORIZONTAL

SLIDER
1080
128
1252
161
c_sat_1
c_sat_1
0
8
0
1
1
NIL
HORIZONTAL

SLIDER
1082
173
1254
206
c_sat_2
c_sat_2
1
9
7
1
1
NIL
HORIZONTAL

SLIDER
906
51
1078
84
num-cold-snacks
num-cold-snacks
0
100
30
1
1
NIL
HORIZONTAL

MONITOR
1122
357
1185
402
Warm Pop
count warm-peeps
0
1
11

MONITOR
1122
304
1184
349
Cold Pop
count cold-peeps
17
1
11

MONITOR
1122
462
1185
507
Warm Snacks
count snacks with [snack-heat > 0]
0
1
11

MONITOR
1122
252
1184
297
Avg Heat
1 / (count patches) * sum [patch-heat] of patches
3
1
11

PLOT
907
331
1107
481
Average Heat
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot 1 / (count patches) * sum [patch-heat] of patches"

SLIDER
907
252
1079
285
rand-sprout-rate
rand-sprout-rate
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
3
372
174
405
paint-heat
paint-heat
-1000
1000
180
10
1
NIL
HORIZONTAL

SLIDER
3
410
175
443
paint-radius
paint-radius
1
30
15
1
1
NIL
HORIZONTAL

INPUTBOX
394
458
464
518
num-frames
3600
1
0
Number

BUTTON
313
457
384
490
Record
record-setup\nrepeat actual-num-frames [\ngo\nmovie-grab-view\n]\nmovie-close
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
473
459
606
519
movie-name
test1
1
0
String

SLIDER
908
293
1080
326
snack-sprout-radius
snack-sprout-radius
1
100
25
1
1
NIL
HORIZONTAL

SLIDER
1083
212
1255
245
funky-cutoff
funky-cutoff
0
300
180
1
1
NIL
HORIZONTAL

SLIDER
907
212
1079
245
sprout-success-rate
sprout-success-rate
0
1
0
0.01
1
NIL
HORIZONTAL

CHOOSER
15
321
153
366
paint-type
paint-type
"none" "heat" "snacks" "peeps"
2

MONITOR
1122
409
1185
454
Cold Snacks
count snacks with [ snack-heat <= 0 ]
17
1
11

INPUTBOX
205
457
304
517
actual-num-frames
4500
1
0
Number

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 5.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
