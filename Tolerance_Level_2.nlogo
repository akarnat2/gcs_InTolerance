; Tolerance and intolerance on a bounded, one-dimensional community.
; Sliders control population, neighborhood radius, thresholds and residential preference.
globals [ histogram-counts initialized? ]
turtles-own [ religion location tolerance next-tolerance initial-tolerance ]

to setup
  clear-all
  set initialized? true
  ask patches [ set pcolor white ]
  draw-number-line
  create-turtles initial-population [ initialize-agent ]
  reset-ticks
  refresh-histogram
  record-proportions
end

to go
  if not initialized? [ setup stop ]
  ; Capture incumbents BEFORE adding newcomers.
  let incumbents (turtle-set turtles)
  create-turtles arrivals-per-move [
    initialize-agent
    if same-religion-preference > 0 and neighborhood-radius > 0 [
      let own-religion religion
      if any? incumbents with [ religion = own-religion ] [
        set location preferred-location location incumbents own-religion
        set xcor (100 * location)
      ]
    ]
  ]
  ; Neighborhoods include newcomers, but only incumbents update this move.
  ask incumbents [ calculate-next-tolerance ]
  ask incumbents [ set tolerance next-tolerance ]
  tick
  refresh-histogram
  record-proportions
end

to initialize-agent
  set religion ifelse-value (random-float 1 < religion-a-probability) [ "A" ] [ "B" ]
  set location random-float 1
  set initial-tolerance random-float 1
  set tolerance initial-tolerance
  set next-tolerance tolerance
  setxy (100 * location) 0
  set shape "circle"
  set size 0.85
  set color ifelse-value (religion = "A") [ blue ] [ orange ]
end

to calculate-next-tolerance
  let focal-location location
  let focal-religion religion
  ; Strict radius matches (x - neighborhood-radius, x + neighborhood-radius). No wraparound; exclude self.
  let local-agents other turtles with [ abs (location - focal-location) < neighborhood-radius ]
  set next-tolerance tolerance
  if any? local-agents [
    let same-count count local-agents with [ religion = focal-religion ]
    let same-fraction same-count / count local-agents
    let change (0.5 - same-fraction) * tolerance
    ; The stated rule can exceed 1; cap to preserve the defined state space.
    set next-tolerance max (list 0 (min (list 1 (tolerance + change))))
  ]
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

to refresh-histogram
  ; Explicit bins ensure tolerance = 1 is included in the last bar.
  ; Bins: [0,.05), [.05,.10), ..., [.95,1].
  set histogram-counts n-values 20 [ 0 ]
  ask turtles [
    let bin-index min (list 19 (floor (tolerance * 20)))
    set histogram-counts replace-item bin-index histogram-counts
      ((item bin-index histogram-counts) + 1)
  ]
  set-current-plot "Tolerance distribution"
  clear-plot
  auto-plot-off
  set-plot-x-range 0 1
  set-plot-y-range 0 histogram-count-limit
  set-current-plot-pen "Agents"
  set-plot-pen-mode 1
  set-plot-pen-interval 0.05
  foreach (range 0 20) [ i ->
    plotxy ((i + 0.5) / 20) (item i histogram-counts)
  ]
end

to-report tallest-bin
  if empty? histogram-counts [ report 0 ]
  report max histogram-counts
end

to-report histogram-overflow?
  report tallest-bin > histogram-count-limit
end

to-report average-tolerance
  if not any? turtles [ report 0 ]
  report mean [ tolerance ] of turtles
end

; Inclusive thresholds classify agents across both religions.
to-report intolerant-proportion
  if not any? turtles [ report 0 ]
  report (count turtles with [ tolerance <= intolerance-threshold ]) / count turtles
end

to-report tolerant-proportion
  if not any? turtles [ report 0 ]
  report (count turtles with [ tolerance >= tolerance-threshold ]) / count turtles
end

to record-proportions
  set-current-plot "Population proportions"
  auto-plot-off
  let combined-proportion (tolerant-proportion + intolerant-proportion)
  if combined-proportion > plot-y-max [ set-plot-y-range 0 2 ]
  if count turtles >= plot-x-max [
    set-plot-x-range 0 (max (list 100 (100 * ceiling ((count turtles + 1) / 100))))
  ]
  set-current-plot-pen "Tolerant"
  plotxy count turtles tolerant-proportion
  set-current-plot-pen "Intolerant"
  plotxy count turtles intolerant-proportion
  set-current-plot-pen "Sum"
  plotxy count turtles combined-proportion
  record-religion-proportions "A"
  record-religion-proportions "B"
end

to record-religion-proportions [ group-name ]
  let members turtles with [ religion = group-name ]
  let group-size count members
  let tolerant-share 0
  let intolerant-share 0
  ; Follow the population monitors' zero convention for empty groups.
  if group-size > 0 [
    set tolerant-share (count members with [ tolerance >= tolerance-threshold ]) / group-size
    set intolerant-share (count members with [ tolerance <= intolerance-threshold ]) / group-size
  ]
  let combined-share (tolerant-share + intolerant-share)
  set-current-plot (word "Religion " group-name " proportions")
  auto-plot-off
  if combined-share > plot-y-max [ set-plot-y-range 0 2 ]
  if count turtles >= plot-x-max [
    set-plot-x-range 0 (max (list 100 (100 * ceiling ((count turtles + 1) / 100))))
  ]
  set-current-plot-pen "Tolerant"
  plotxy count turtles tolerant-share
  set-current-plot-pen "Intolerant"
  plotxy count turtles intolerant-share
  set-current-plot-pen "Sum"
  plotxy count turtles combined-share
end

; The initial uniform draw is the first of 20 candidate locations.
to-report preferred-location [ uniform-location residents own-religion ]
  let candidates fput uniform-location (n-values 19 [ random-float 1 ])
  let weights map [ candidate ->
    1 + same-religion-preference * (same-religion-share candidate residents own-religion)
  ] candidates
  let draw random-float (sum weights)
  let candidate-index 0
  while [ candidate-index < 19 and draw >= item candidate-index weights ] [
    set draw draw - item candidate-index weights
    set candidate-index candidate-index + 1
  ]
  report item candidate-index candidates
end

to-report same-religion-share [ candidate residents own-religion ]
  let neighbors-near-candidate residents with [ abs (location - candidate) < neighborhood-radius ]
  let neighbor-count count neighbors-near-candidate
  if neighbor-count = 0 [ report 0 ]
  report (count neighbors-near-candidate with [ religion = own-religion ]) / neighbor-count
end
@#$#@#$#@
GRAPHICS-WINDOW
260
75
1156
252
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

TEXTBOX
20
12
1140
52
LEVEL 2  |  Tolerance and residential preference
20
0.0
1

TEXTBOX
260
50
1155
72
Blue = religion A     Orange = religion B     All dots live on the line; position and religion stay fixed.
12
0.0
1

SLIDER
20
75
240
108
neighborhood-radius
neighborhood-radius
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
20
118
240
151
religion-a-probability
religion-a-probability
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
20
161
240
194
initial-population
initial-population
0
1000
100
1
1
NIL
HORIZONTAL

SLIDER
20
204
240
237
arrivals-per-move
arrivals-per-move
0
100
10
1
1
NIL
HORIZONTAL

SLIDER
20
247
240
280
histogram-count-limit
histogram-count-limit
10
10000
200
10
1
NIL
HORIZONTAL

BUTTON
20
300
120
333
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
130
300
240
333
One move
go
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
20
343
240
376
Run / pause
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

BUTTON
20
386
240
419
Refresh histogram
refresh-histogram
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
260
267
395
312
Population
count turtles
3
1
11

MONITOR
405
267
540
312
Religion A
count turtles with [religion = "A"]
3
1
11

MONITOR
550
267
685
312
Religion B
count turtles with [religion = "B"]
3
1
11

MONITOR
695
267
840
312
Mean tolerance
average-tolerance
3
1
11

MONITOR
850
267
985
312
Tallest bin
tallest-bin
3
1
11

MONITOR
995
267
1155
312
Bars clipped?
histogram-overflow?
3
1
11

PLOT
260
330
700
650
Tolerance distribution
Tolerance level
Number of agents
0.0
1.0
0.0
200.0
false
false
"" ""
PENS
"Agents" 0.05 1 -13345367 true "" ""

TEXTBOX
260
663
1150
707
Histogram axes stay fixed. If Bars clipped? is true, raise histogram-count-limit and click Refresh histogram.\nOverlapping dots may conceal agents; the counts and histogram include every agent.
12
0.0
1

SLIDER
20
440
240
473
intolerance-threshold
intolerance-threshold
0
0.5
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
20
483
240
516
tolerance-threshold
tolerance-threshold
0.5
1
0.75
0.01
1
NIL
HORIZONTAL

MONITOR
20
535
240
580
Intolerant proportion
intolerant-proportion
4
1
11

MONITOR
20
590
240
635
Tolerant proportion
tolerant-proportion
4
1
11

PLOT
710
330
1156
650
Population proportions
Current population
Proportion
0.0
100.0
0.0
1.0
false
true
"" ""
PENS
"Tolerant" 1.0 0 -16776961 true "" ""
"Intolerant" 1.0 0 -65536 true "" ""
"Sum" 1.0 0 -10899396 true "" ""

TEXTBOX
20
715
1150
760
Set thresholds before Setup for a consistent comparison. Monitors show current shares across both religions.\nThe graph records Setup and each move. Blue = tolerant. Red = intolerant. Green = their sum.
12
0.0
1

PLOT
260
780
700
1100
Religion A proportions
Current total population
Proportion within religion A
0.0
100.0
0.0
1.0
false
true
"" ""
PENS
"Tolerant" 1.0 0 -16776961 true "" ""
"Intolerant" 1.0 0 -65536 true "" ""
"Sum" 1.0 0 -10899396 true "" ""

PLOT
710
780
1156
1100
Religion B proportions
Current total population
Proportion within religion B
0.0
100.0
0.0
1.0
false
true
"" ""
PENS
"Tolerant" 1.0 0 -16776961 true "" ""
"Intolerant" 1.0 0 -65536 true "" ""
"Sum" 1.0 0 -10899396 true "" ""

TEXTBOX
260
1110
1156
1155
Each religion graph divides by that religion's population. Both use total community population on the x axis.\nAn absent religion displays zero for all three lines. Colors match the overall population graph.
12
0.0
1

SLIDER
20
650
240
683
same-religion-preference
same-religion-preference
0
10
1
0.1
1
NIL
HORIZONTAL

TEXTBOX
20
689
240
711
0 gives uniform arrival locations
12
0.0
1
@#$#@#$#@
## WHAT IS IT?
A bounded number-line community with two fixed religions (A and B) and evolving tolerance in [0,1]. This implements the proposed local-composition rule; it is a modeling assumption, not an empirically validated law.

## HOW TO USE IT
Open this file in NetLogo Desktop (6.4 or a later version that imports .nlogo files). Set neighborhood-radius, religion-a-probability, initial-population, arrivals-per-move and histogram-count-limit. Click Setup to initialize. Click One move once per update, or Run / pause for repeated moves. Setup resets the simulation. Read the moves counter for completed updates.

neighborhood-radius is the shared neighborhood radius in community units, not screen pixels. religion-a-probability is the probability that each newly created agent has religion A. initial-population is the initial population and arrivals-per-move is the number of arrivals per move. Changing religion-a-probability affects future arrivals only. Changing initial-population takes effect at the next Setup. neighborhood-radius and arrivals-per-move apply on the next move.

## INITIALIZATION
Each initial agent and arrival receives:
- A fixed position x. Initial agents are placed uniformly on [0,1). Newcomer placement uses the preference rule below.
- Religion A with probability religion-a-probability, otherwise B.
- Initial tolerance sampled uniformly from [0,1).
NetLogo random-float excludes its upper endpoint. For these continuous uniform distributions, excluding the single endpoint has no probability effect.
All agents are dots at their actual positions on the same line. A is blue; B is orange. Dot overlap is intentional: there is no artificial relocation. Colors encode religion, not tolerance. Inspect a dot to see its variables.

## ONE MOVE, IN ORDER
1. Record which agents already exist.
2. Add arrivals-per-move agents. Draw each newcomer's religion and tolerance, then choose its position using the placement rule below.
3. For each existing agent, calculate its next tolerance using the expanded population.
4. Apply all existing agents' changes, advance the move counter and redraw the histogram.
Newcomers affect neighborhoods immediately but retain their random initial tolerance until the following move. There is no migration, death or religious conversion.

## NEIGHBORHOOD AND UPDATE
For an agent at x, neighbors are OTHER agents with abs(their-position - x) < neighborhood-radius. This matches the open interval (x - radius, x + radius), where radius is the neighborhood-radius slider. Neighborhoods stop at the community edges; the endpoints are not connected. Self is excluded. If there are no neighbors, tolerance stays unchanged. In particular, neighborhood-radius=0 gives empty neighborhoods.

Let q be the same-religion fraction among the neighbors. The requested rule is:
    change = (0.5 - q) * current-tolerance
    next-tolerance = current-tolerance + change
The implementation bounds the result:
    next-tolerance = max(0, min(1, current-tolerance * (1.5 - q)))
The upper cap is an explicit addition needed to keep tolerance within [0,1]. The raw rule can produce values above 1 (for example, 0.9 with q=0 gives 1.35). The lower cap is defensive; the stated rule cannot produce negative values from a valid state.

## HISTOGRAM
The histogram is drawn at Setup and after every move. It shows raw counts of all agents, including arrivals, in 20 bins of width 0.05. The first 19 bins include the lower endpoint and exclude the upper; the last bin includes tolerance exactly 1. Counts always sum to the population.
The x axis stays [0,1]. The y axis stays [0,histogram-count-limit], with automatic scaling disabled. Since population grows without bound when arrivals-per-move>0, no finite fixed y axis can show every possible future count. Tallest bin reports the actual highest count; Bars clipped? flags overflow. To intentionally change the scale, adjust histogram-count-limit and click Refresh histogram; this does not change the agents or advance time. Leave that control unchanged for comparisons on the same scale.

## THINGS TO NOTICE
q=1 halves tolerance. q=0 increases tolerance by 50 percent up to the cap. q=0.5 leaves tolerance unchanged. An agent at exactly zero tolerance remains at zero under this multiplicative rule, even among only other-religion neighbors.
Religious composition and locations do not depend on tolerance. Thus neighbors influence each agent through their religions, but neighbors' tolerance values do not directly spread. This distinction matters when interpreting this model as a model of tolerance diffusion.
The neighborhood calculation scans the population for each incumbent; the work per move grows approximately quadratically with population. Pause long runs as the community becomes large.

## REPRODUCIBLE RUNS
In the Command Center, use `random-seed 42` followed by `setup` and a fixed number of `go` calls. Reapply the same seed before each new Setup to reproduce a run. To export the current histogram, use `export-plot "Tolerance distribution" "tolerance-histogram.csv"`.

## IMPLEMENTATION
The interface intentionally does not impose a population cap or change the proposed formula beyond bounding tolerance. The code calculates all next values before committing updates. No extensions or external files are required.

## TOLERANCE THRESHOLDS AND POPULATION PROPORTIONS

The intolerance-threshold slider ranges from 0 to 0.5 and defaults to 0.25. An agent is classified as intolerant when tolerance <= intolerance-threshold.

The tolerance-threshold slider ranges from 0.5 to 1 and defaults to 0.75. An agent is classified as tolerant when tolerance >= tolerance-threshold.

Each monitor divides the relevant count by the entire current population, including both religions and newcomers. Proportions are between 0 and 1. An empty population displays 0 for both measures by convention.

The Population proportions graph records the initial population at Setup and the population after every move, paired with the tolerant share (blue) and intolerant share (red). The green Sum line records tolerant-proportion + intolerant-proportion. The vertical scale starts from 0 to 1 and expands to 0 to 2 if the sum exceeds 1. The population axis expands as needed. When arrivals-per-move is zero, successive points share the same population coordinate.

Set thresholds before Setup to compare a full run using consistent definitions. If thresholds change during a run, monitors reflect the new definitions immediately and future graph points use the new thresholds. Previously recorded points retain their original classifications.

Agents strictly between the thresholds belong to neither category. If both thresholds equal 0.5, agents at exactly 0.5 count in both categories, following the requested inclusive inequalities. Their contribution is counted twice in the sum, which can therefore exceed 1.

## PROPORTIONS WITHIN EACH RELIGION

The Religion A proportions and Religion B proportions graphs record at Setup and after every move alongside the overall population graph. Both use current total community population on the horizontal axis, so the three graphs can be compared at the same population sizes.

For religion A, the tolerant share equals the number of tolerant A agents divided by all A agents. The intolerant share equals the number of intolerant A agents divided by all A agents. Religion B uses the corresponding counts among B agents. Each graph's green Sum line adds its tolerant and intolerant shares.

Each graph uses blue for tolerant, red for intolerant and green for the sum. The shared sliders provide inclusive thresholds for every graph. An absent religion displays all three shares as zero by convention. A graph's vertical scale expands to 2 if overlapping classifications produce a sum greater than 1.

Changing thresholds during a run affects subsequent points. Earlier points retain the thresholds used when recorded.

## LEVEL 2 PLACEMENT

The same-religion-preference slider sets how strongly new arrivals favor neighborhoods with a larger share of their religion. Its range is 0 to 10, and it defaults to 1. Initial locations are uniform. same-religion-preference = 0 also makes all newcomer locations uniform, matching Level 1.

Each newcomer considers 20 locations sampled uniformly on [0,1). At each candidate, the score is the number of residents of the newcomer's religion divided by the total number of residents within radius neighborhood-radius. An empty neighborhood has score zero. Candidates are selected at random in proportion to 1 + same-religion-preference * score, so all candidates have positive weight. A neighborhood with 3 same-religion residents out of 4 has a higher score than one with 10 out of 20.

Only residents present at the start of the move contribute to these scores. If there are no residents of the newcomer's religion, or if neighborhood-radius = 0, placement is uniform. If all 20 scores are zero, all 20 candidates have equal weight. Changes to same-religion-preference affect future arrivals. Tolerance updates use the expanded population as in Level 1.
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
repeat 10 [ go ]
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
