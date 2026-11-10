; Level 0: a single A agent and a growing B group.
turtles-own [ religion location tolerance next-tolerance ]

to setup
  clear-all
  ask patches [ set pcolor white ]
  draw-number-line
  create-turtles 1 [ initialize-agent "A" ]
  create-turtles 1 [ initialize-agent "B" ]
  reset-ticks
  plot-tolerance
end

to add-one-b
  if not any? turtles [ setup stop ]
  create-turtles 1 [ initialize-agent "B" ]
  let a-count count turtles with [ religion = "A" ]
  let b-count count turtles with [ religion = "B" ]
  let neighbor-count (a-count + b-count - 1)

  ; The entire community is in range. Subtract the focal agent.
  ask turtles [
    let same-count ifelse-value (religion = "A") [ a-count - 1 ] [ b-count - 1 ]
    let same-fraction same-count / neighbor-count
    let change (0.5 - same-fraction) * tolerance
    set next-tolerance min (list 1 (tolerance + change))
  ]
  ask turtles [ set tolerance next-tolerance ]
  tick
  plot-tolerance
end

to initialize-agent [ group-name ]
  set religion group-name
  set location random-float 1
  set tolerance random-float 1
  set next-tolerance tolerance
  setxy (100 * location) 0
  set shape "circle"
  set size 1.2
  set color ifelse-value (religion = "A") [ red ] [ blue ]
end

to plot-tolerance
  set-current-plot "Tolerance over time"
  if ticks > plot-x-max [
    set-plot-x-range 0 (plot-x-max + 10)
  ]
  set-current-plot-pen "A agent"
  plotxy ticks a-tolerance
  set-current-plot-pen "B average"
  plotxy ticks b-average
end

to-report a-tolerance
  let a-group turtles with [ religion = "A" ]
  if not any? a-group [ report 0 ]
  report [ tolerance ] of one-of a-group
end

to-report b-average
  let b-group turtles with [ religion = "B" ]
  if not any? b-group [ report 0 ]
  report mean [ tolerance ] of b-group
end

to draw-number-line
  ; Pen drawings are visual guides only, never interacting agents.
  create-turtles 1 [
    hide-turtle
    setxy 0 0
    set color gray
    set pen-size 1
    pen-down
    setxy 100 0
    pen-up
    foreach (range 0 11) [ i ->
      setxy (i * 10) -0.8
      pen-down
      setxy (i * 10) 0.8
      pen-up
    ]
    die
  ]
  foreach (range 0 11) [ i ->
    ask patch (i * 10) -3 [
      set plabel precision (i / 10) 1
      set plabel-color black
    ]
  ]
end
@#$#@#$#@
TEXTBOX
20
12
900
43
LEVEL 0  |  Tolerance in a growing community
20
0.0
1

TEXTBOX
20
48
900
70
Everyone sees the whole community (S = 1). Red = religion A. Blue = religion B.
12
0.0
1

GRAPHICS-WINDOW
20
77
916
254
-1
-1
8.0
1
12
1
1
1
0
0
0
1
-5
105
-10
10
1
1
1
moves
30.0

BUTTON
20
265
110
309
Setup
setup
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
120
265
310
309
Add one B agent
add-one-b
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
327
265
488
310
A tolerance
a-tolerance
3
1
11

MONITOR
500
265
667
310
B average tolerance
b-average
3
1
11

MONITOR
680
265
840
310
B population
count turtles with [religion = "B"]
0
1
11

PLOT
20
323
916
632
Tolerance over time
Moves (B arrivals)
Tolerance
0
10
0
1
false
true
"" ""
PENS
"A agent" 1.0 0 -65536 true "" ""
"B average" 1.0 0 -16776961 true "" ""
@#$#@#$#@
## LEVEL 0: TOLERANCE IN A GROWING COMMUNITY

The community is a number line from 0 to 1. Every other agent belongs to each agent's neighborhood, so the shared radius is fixed at S = 1. Locations stay fixed and do not affect the update.

## HOW TO USE IT

- Click **Setup** to create exactly one A agent (red) and one B agent (blue). Each gets a random location and a random initial tolerance, sampled uniformly from [0,1).
- Click **Add one B agent** once per move. One B agent joins with a random location and tolerance. Then every agent, including the newcomer, updates once. The simulation records the initial state at move 0 and the post-update state after each click.
- The red line shows the single A agent's tolerance. The blue line shows the average over all B agents, including the newcomer. The vertical scale stays at 0 to 1, and the horizontal scale expands as needed.

## UPDATE RULE

For an agent with current tolerance T, let q be the fraction of its neighbors who share its religion. Exclude the agent itself from both counts. Then

    change = (0.5 - q) * T
    next tolerance = min(1, T + change)

Tolerance starts nonnegative, and this rule cannot produce a negative value. Calculate every next tolerance before applying any changes.

## WHAT TO EXPECT

The A agent has no same-religion neighbors, so each update multiplies its tolerance by 1.5 until it reaches the cap of 1 (or stays at 0 if initialized there).

With k B agents after the arrival, each B agent has k - 1 B neighbors and one A neighbor. Its multiplier is 0.5 + 1/k. On the first move k = 2, so individual B tolerances stay the same during the update, although adding a B agent can change their average. On later moves the multiplier is below 1, but the B average also depends on the tolerance of each newcomer.
@#$#@#$#@
default
true
0
Circle -7500403 true true 0 0 300

circle
false
0
Circle -7500403 true true 0 0 300
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
setup
repeat 12 [ add-one-b ]
@#$#@#$#@
@#$#@#$#@
<experiments>
</experiments>
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
