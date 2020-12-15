extensions [time table Csv rngs]

breed [cashiers cashier]
breed [servers server]
breed [sco-servers sco-server]
breed [customers customer]

patches-own [
  contamination      ;; virus spreeded n scale 1 - 100 ?
  floor?             ;; floor TRUE>/FALSE
]


servers-own [
  customer-being-served
  cashier-working-on
  next-completion-time
  server-queue
  expected-waiting-time
  open?
  time-start
  time-end
  time-break-start
  time-break-end
  break-count
  break-length
]

sco-servers-own [
  customer-being-served
  next-completion-time
  expected-waiting-time
  open?
  time-start
  time-end
  time-break-start
  time-break-end
  break-count
  break-length
]

cashiers-own [
  server-working-on
  working?
  backoffice?
  time-start
  time-end
  time-break-start
  time-break-end
  time-work-start
  time-work-end
  work-count
  work-length
  break-count
  break-length
]

customers-own [
  basket-size

  ;parameter drawn
  payment-method
  sco-will?
  picking-queue-strategy
  jockeying-strategy
  jockeying-distance
  jockeying-threshold
  server-service-time
  sco-server-service-time

  ;decision of picking
  sco-zone-queue-picked?
  server-zone-queue-picked?
  server-picked

  ;information which
  sco?
  server-queued-on
  server-served-on


  ;statistics
  time-entered-model
  time-entered-store
  time-entered-queue
  time-entered-service
  time-leaving-model

  num-of-servers
  num-of-sco
  num-of-customers
  num-of-articles

  jockeying-count
]

globals [

  ticks-hour
  ticks-minute
  max-run-time
  start-time
  end-time
  current-time

  ;POS input files names
  ;customer-arrival-input-file
  ;customer-basket-payment-input-file
  ;cashier-arrival-input-file

  ;POS input time series
  customer-arrival-input
  customer-basket-payment-input
  cashier-arrival-input

  customer-arrival-max-rate
  customer-basket-payment-values


  ; customer statistic variables
  customer-arrival-count
  customer-arrival-count-minute
  customer-arrival-count-hour
  customer-checkout-queue-time
  customer-checkout-queue-time-hour
  customer-service-time
  customer-service-time-hour

  customer-checkout-queue-mean-time
  customer-leaving-count
  customer-leaving-count-hour
  customer-leaving-count-sco
  customer-leaving-count-sco-hour
  customer-leaving-count-server
  customer-leaving-count-server-hour
  customer-leaving-waiting-count
  customer-leaving-waiting-count-hour
  customer-leaving-waiting-count-sco
  customer-leaving-waiting-count-sco-hour
  customer-leaving-waiting-count-server
  customer-leaving-waiting-count-server-hour
  customer-leaving-waiting5-count
  customer-leaving-waiting5-count-hour
  customer-leaving-waiting5-count-sco
  customer-leaving-waiting5-count-sco-hour
  customer-leaving-waiting5-count-server
  customer-leaving-waiting5-count-server-hour
  customer-leaving-queue-time-sco
  customer-leaving-queue-time-sco-hour
  customer-leaving-queue-time-server
  customer-leaving-queue-time-server-hour
  customer-leaving-count-not-infected
  customer-leaving-count-not-infected-hour
  customer-leaving-queue-time-not-infected
  customer-leaving-queue-time-not-infected-hour
  customer-leaving-queue-mean-time-not-infected
  customer-leaving-exposed-count
  customer-leaving-exposed-count-hour
  customer-leaving-exposure-time
  customer-leaving-exposure-time-hour
  customer-leaving-exposure-count
  customer-leaving-exposure-count-hour

  ;cashier statistic variables
  cashier-working-length
  cashier-working-length-hour
  cashier-effective-working-length
  cashier-effective-working-length-hour
  cashier-break-count
  cashier-break-count-hour



  ;*store visulaisation variables
  server-zone-xcor
  server-zone-ycor
  sco-zone-xcor
  sco-zone-ycor
  backoffice-width

  ;*queue variables SCO queue + single queue for all servers (optional)
  server-zone-queue
  sco-zone-queue

  ;*backoffice list
  cashiers-backoffice

  ;varaiable for simulation of events done discret
  customer-arrival-next-time
  cashier-arrival-next-time
  cashier-server-enter-next-time
  next-server-to-complete
  next-sco-server-to-complete
  next-hour
  next-minute
  next-day

  ;output file list
  customers-output-file-list
  cashier-output-file-list

]

to setup-customer-arrival-input-file
  let icustomer-arrival-input-file user-file
   if (is-string? icustomer-arrival-input-file ) [set customer-arrival-input-file  icustomer-arrival-input-file]
end

to setup-customer-basket-payment-file
  let icustomer-basket-payment-input-file user-file
  if (is-string? icustomer-basket-payment-input-file ) [set customer-basket-payment-input-file  icustomer-basket-payment-input-file]
end

to setup-cashier-arrival-input-file
  let icashier-arrival-input-file  user-file
  if (is-string? icashier-arrival-input-file ) [set cashier-arrival-input-file icashier-arrival-input-file]
end

to setup-customer-output-directory
  let icustomer-output-directory user-directory
  if (is-string? icustomer-output-directory ) [set customer-output-directory icustomer-output-directory]
end

to setup-cashier-output-directory
  let icashier-output-directory user-directory
  if (is-string? icashier-output-directory) [set cashier-output-directory icashier-output-directory]
end


to setup-customer-arrival-data-read
; this procedure set initial values necessary to further proces POS data for arrival process calibration

  ; set POS input data files
  ;set customer-arrival-input-file "customer-arrival-input-file-store1.csv"

  ; read customer-arrival-max-rate, a value necessery for calculation arrival rate with NHPP process
  file-open customer-arrival-input-file
  let row csv:from-row file-read-line
  set customer-arrival-max-rate 0
  while [ not file-at-end? ] [
    set row csv:from-row file-read-line
    if item 1 row > customer-arrival-max-rate  [  set customer-arrival-max-rate item 1 row ]
  ]
  file-close
  set customer-arrival-max-rate precision ( customer-arrival-max-rate / 60 ) 2

  ;set customer-arrival-input as time series variable from  customer-arrival-input-file
  set customer-arrival-input time:ts-load  customer-arrival-input-file

end

to setup-customer-basket-payment-data-read
;this procedure read initial values necessary to further proces POS data for basket size and method of payment draw

 ;set customer-basket-payment-input-file "customer-basket-payment-input-file-store1.csv"
  ; read posiible values of basket size / payment method
  file-open customer-basket-payment-input-file
    set customer-basket-payment-values csv:from-row file-read-line
  file-close

  ;time series vairable with basket size and mehod of paymant
  set customer-basket-payment-input time:ts-load  customer-basket-payment-input-file

end

to setup-customer-data-write
  set customers-output-file-list []
  set cashier-output-file-list []
end

to setup-cashier-arrival
  set cashiers-backoffice []
  cashiers-create number-of-cashiers 999999999999999

  if (cashier-arrival = "workschedule (POS)") [
   ; set cashier-arrival-input-file "cashier-arrival-input-file-store1.csv"
    set cashier-arrival-input time:ts-load cashier-arrival-input-file
  ]

end

to setup-times
; this procedures set necessary time variables

  set start-time time:create "0001-01-01 00:01:00"
  let start-time1 time:create "0001-01-01 00:01:00"
  set end-time time:create "9999-12-31 00:00:00"
  let end-time1 time:create "9999-12-31 00:00:00"

  if customer-arrival-proces = "NHPP (POS)" [
    set start-time first time:ts-get customer-arrival-input start-time  "all"
    set end-time first time:ts-get customer-arrival-input end-time  "all"]
  if (cashier-arrival = "workschedule (POS)") [
    set start-time1 first time:ts-get cashier-arrival-input start-time1  "all"
    set end-time1 first time:ts-get cashier-arrival-input end-time1  "all"
    set end-time1 time:plus end-time1 cashier-work-time  "minutes"
  ]


  if  ( time:is-before start-time1 start-time and (not time:is-equal start-time1 time:create "0001-01-01 00:01:00")) or (time:is-equal start-time  time:create "0001-01-01 00:01:00")[

    set start-time start-time1
  ]
  if  ( time:is-after end-time1 end-time  and (not time:is-equal end-time1 time:create "9999-12-31 00:00:00")) or (time:is-equal end-time  time:create "9999-12-31 00:00:00") [set end-time end-time1 ]

  set start-time time:plus start-time -1.0 "minutes"
  set start-time1 time:plus start-time1 -1.0 "minutes"

  if time:is-after (time:plus start-time simulation-start-day "days")  start-time [set start-time (time:plus start-time simulation-start-day "days") ]
  if time:is-before (time:plus start-time simulation-end-day "days")  end-time [set end-time (time:plus start-time simulation-end-day "days") ]

  ;set max-run-time
  set max-run-time time:difference-between start-time end-time  "minute"
  set current-time time:anchor-to-ticks start-time 1 "minute"

End


to setup-store
 import-drawing "model-images/store_2.png"
  ask patches [
    set floor? FALSE
  ]
  ask patches with [ pycor  >= ( (min-pycor ) + 1) ] [
    set floor? TRUE
  ]
  ask patches [recolor-patch]
end

to setup-backoffice
  set backoffice-width abs ( min-pxcor / 4)
end

 to setup-servers
  let server-ycor ( (min-pycor  ) + 1)
  set-default-shape servers "checkout-service"
  set server-zone-queue []
  if number-of-servers > 0 [
    let max-in-row floor ( abs max-pxcor ) / distance-server-server
    create-servers number-of-servers [
      ifelse number-of-servers <= max-in-row [
        setxy (backoffice-width - ( who * distance-server-server ) ) server-ycor
      ][
        ifelse (



          ( who mod 2) != 0 )[
        setxy (backoffice-width - ( who * distance-server-server / 2 ) ) server-ycor][
        setxy (backoffice-width - ( who * distance-server-server / 2 ) ) ( server-ycor + distance-server-server )]
      ]





;      ifelse ( who < max-in-row) [
;        setxy (backoffice-width - ( who * distance-server-server ) ) server-ycor
;      ][
;        setxy (backoffice-width - (( who - max-in-row) * distance-server-server ) - 1 )
;      ]

      set label ""
      set customer-being-served nobody
      set cashier-working-on nobody
      set next-completion-time 0
      set server-queue []
      set open? false
      set time-start ticks
      set time-end max-run-time
      set time-break-start ticks
      set time-break-end 0
      recolor-server
    ]
    set server-zone-xcor ([xcor] of (min-one-of servers [xcor])) + (([xcor] of (max-one-of servers [xcor]))-([xcor] of (min-one-of servers [xcor]))) / 2
    set server-zone-ycor [ycor] of max-one-of servers [ycor]
  ]

end

to setup-sco-servers
  let horizontal-interval distance-sco-sco-h
  let vertical-interval distance-sco-sco-v
  set-default-shape sco-servers "checkout-sco"
  set sco-zone-queue []
  if number-of-sco-servers > 0 [
    create-sco-servers number-of-sco-servers [
      let sco-server-ycor ((min-pycor + 1) + vertical-interval * ( int ((who - (count servers)) / 2)))
      let sco-server-xcor  backoffice-width + distance-server-server + horizontal-interval * ((who - (count servers)) mod 2)
      setxy sco-server-xcor  sco-server-ycor
      set label ""
      set customer-being-served nobody
      set next-completion-time 0
      set open? true
      set time-start ticks
      set time-end max-run-time
      set time-break-start ticks
      set time-break-end 0
      recolor-sco-server
    ]
    set sco-zone-xcor ([xcor] of (min-one-of sco-servers [xcor])) + (([xcor] of (max-one-of sco-servers [xcor]))-([xcor] of (min-one-of sco-servers [xcor]))) / 2
    set sco-zone-ycor [ycor] of max-one-of sco-servers [ycor]
 ]
end


to setup-randomes
   rngs:set-seed 1 (experiment * 2) ;customer-arrival-time-schedule-nhpp 1
   rngs:set-seed 2 (experiment * 4)  ;customer-arrival-time-schedule-nhpp 2
   rngs:set-seed 3 (experiment * 6)
   rngs:set-seed 4 (experiment * 8)  ;customer-server-service-time-draw
   rngs:set-seed 5 (experiment * 10)  ;customer-sco-server-service-time-draw
   rngs:set-seed 6 (experiment * 12)  ;customer-picking-queue-strategy-draw
   rngs:set-seed 7 (experiment * 13)
   rngs:set-seed 8 (experiment * 14)
   rngs:set-seed 9 (experiment * 15)


end

to setup
  clear-all
  reset-ticks
  random-seed 100
  setup-store
  setup-backoffice
  setup-servers
  setup-sco-servers
  setup-customer-arrival-data-read
  setup-customer-basket-payment-data-read
  setup-cashier-arrival
  setup-times
  setup-customer-data-write
  setup-randomes
  ;print customer-arrival-max-rate
end


to recolor-patch  ;; patch procedure

  set pcolor grey + 0.5
  if (floor?)  [ set pcolor grey ]
  if (contamination  > 1)  [ set pcolor blue]
  ;if (contamination  > 1)  [ set pcolor scale-color blue contamination 0.1 25 ]
end

to recolor-server  ;; server procedure
  if (not open?) [ set color red]
  if (open?)  [ set color green]
  ;if (customer-being-served != nobody)  [ set color yellow]
end

to recolor-sco-server  ;; sco-server procedure
  if (not open?) [ set color red]
  if (open?)  [ set color green]
  if (customer-being-served != nobody)  [ set color yellow]
end

to recolor-cashier  ;; sco-server procedure
  if (not working?) [ set color red]
  if (working?)  [ set color green]
end


to-report customers-output-file
   report (word customer-output-directory "customers-output-file_" customer-picking-queue-strategy "_" customer-jockeying-strategy "_" experiment "_" (remove "." remove ":" remove " " date-and-time) ".csv")
end

to-report cashiers-output-file
   report (word cashier-output-directory "cashiers-output-file_" customer-picking-queue-strategy "_" customer-jockeying-strategy "_" experiment "_" (remove "." remove ":" remove " " date-and-time) ".csv")
end

;substring


to move-cashiers-backoffice
;move all cashiers in backoffice to theier positions
foreach cashiers-backoffice [
    x ->  ask x
    [ ask x [

      setxy ( min-pxcor + ((position x cashiers-backoffice) mod backoffice-width))  (min-pycor +  1  +  floor ((position x cashiers-backoffice) / backoffice-width )  )
      ]
    ]
  ]
end

to move-queue-forward   [moved-queue queue-xcor queue-ycor min-position]
;move all customers in queue start from position
foreach moved-queue [
    x ->  ask x
    [ if position x moved-queue >= min-position [customer-move-in-queue (position x moved-queue) queue-xcor queue-ycor]]]
end


to customer-move-in-queue [queue-position queue-xcor queue-ycor] ;customer procedure
;movment of custmers in queue
  let new-xcor queue-xcor
  let new-ycor (queue-ycor + distance-queue-server + (distance-in-queue * queue-position))
  ;customer-decontamine
  ifelse (new-ycor > max-pycor) [
    hide-turtle
  ][
    setxy new-xcor new-ycor
    if (hidden?) [show-turtle]]
  ;customer-contamine
  ;customer-exposure-check
end

to customer-move-to-server [to-server]
  ;customer-decontamine
  move-to to-server
  ;customer-exposure-check
end


to-report customer-arrival-time-schedule
  ifelse customer-arrival-proces = "NHPP (POS)" [
    report customer-arrival-time-schedule-nhpp
  ][report customer-arrival-time-schedule-hpp
  ]
end

to-report customer-arrival-time-schedule-hpp
; this reported return next custommer arrival time according to homogenous poison process (theoretical distribution)
let i_ticks ticks
  report (i_ticks + rngs:rnd-exponential 1 (customer-arrival-mean-rate))
end

to-report customer-arrival-time-schedule-nhpp
; this reporter return next custommer arrival time according to non homogenous poison process (POS data are used for lamda values

  let customer-arrival-inter-rate 0
  let u 1
  let t* 0
  let i_clock current-time
  let i_ticks ticks
  let arrival-next-time ticks
  while [ abs (( time:difference-between i_clock (item 0 time:ts-get customer-arrival-input i_clock "all") "minutes" )) > 30 and (time:difference-between i_clock  end-time  "minutes") > 0  ][
    set i_clock time:plus i_clock 1 "minutes"
    set i_ticks i_ticks + 1
  ]
  let customer-arrival-min-time i_clock
  ifelse (time:difference-between i_clock  end-time  "minutes") > 0 [
    while [ (customer-arrival-inter-rate / customer-arrival-max-rate) < u and (time:difference-between customer-arrival-min-time  end-time  "minutes") > 0  ][
    ;;;;;print word "customer-arrival-inter-rate: " customer-arrival-inter-rate
    ;;;;;print word "customer-arrival-max-rate:  "  customer-arrival-max-rate
      ;set t* (t* + random-exponential  (1 / customer-arrival-max-rate))
      set t* (t* + rngs:rnd-exponential 1  (customer-arrival-max-rate))

      ;;;;;;;print word "t*: " t*
      set customer-arrival-min-time time:plus i_clock t* "minutes"
    ;;;;;;;print word "customer-arrival-min-time: " customer-arrival-min-time
      set u rngs:rnd-uniform 2 0 1
      ;set u random-float 1
    ;;;;;;;print word "u: " u
      set customer-arrival-inter-rate ( customer-arrival-inter-rate-read customer-arrival-min-time )]
      ;;;;;;;;print word "customer-arrival-inter-rate "  customer-arrival-inter-rate
  ;;;;;;;print word "t* chosen: " t*
    report (i_ticks + t*)
  ][
    report 0
  ]
end

to-report customer-arrival-inter-rate-read [time]
; this read read interpleted value out transaction count out of POS data file and return it as arrival rate (lambda function value )  for Non-Homogeneous Poisson Process
  let value 0
  carefully
      [set value  precision ( (time:ts-get-exact customer-arrival-input time "\"customer-transaction-count\"") / 60 ) 2 ]
      [set value  precision ( (time:ts-get-interp customer-arrival-input time "\"customer-transaction-count\"") / 60 ) 2 ]
  report value
end



to customer-store-arrive
  if (count customers < max-customers )[
    create-customers 1[
      customer-basket-payment-draw
      customer-sco-will-draw
      customer-picking-queue-strategy-draw
      customer-jockeying-strategy-draw
      customer-jockeying-distance-draw
      customer-jockeying-threshold-draw
      customer-server-service-time-draw
      customer-sco-server-service-time-draw
      customer-update-satistic "arrival"
      setxy 0 max-pycor
      set time-entered-model ticks
      set sco-zone-queue-picked? FALSE
      set server-zone-queue-picked? FALSE
      set server-picked nobody
      set server-queued-on nobody
      set server-served-on nobody
      set jockeying-count 0

      set num-of-customers  count customers
      set num-of-articles  sum [basket-size] of customers
      set num-of-servers count (servers with [open?])
      set num-of-sco number-of-sco-servers

      let color-index (customer-arrival-count mod 70)
      let main-color (floor (color-index / 5))
      let shade-offset (color-index mod 5)

      set color (3 + shade-offset + main-color * 10)
      set label precision basket-size 2
      if (payment-method = 1)  [set shape "customer-cash"]
      if (payment-method = 2)  [set shape "customer-card"]
      customer-checkout-queue-pick
    ]
    if cashier-server-enter-check? [cashier-server-enter-time-schedule]
  ]

end

to-report basket-payment-ECDF
;this reported read ECDF for basket size and payment method  for current time
;ECDF is taken out POS data
  let iDensity (but-first time:ts-get customer-basket-payment-input  current-time "all" )
  let iSum (sum  but-first time:ts-get customer-basket-payment-input current-time "all")
  if iSum > 0 [ set iDensity  map  [ x ->  x / iSum ] iDensity]
  Set iSum 0
  let iECDF []
  foreach iDensity [ x ->
   set iSum (iSum + x )
   set iECDF lput iSum iECDF
  ]
  report iECDF
end

to customer-basket-payment-draw-ECDF  ;;customer procedure
  let x rngs:rnd-uniform 3 0 1
  let y 1 + length filter [x1 -> x1 < x] basket-payment-ECDF
  let iValue item y customer-basket-payment-values
  ifelse iValue < 1000
    [set basket-size iValue
     set payment-method 1
    ][
     set basket-size (iValue - 1000)
     set payment-method 2
    ]
end

to customer-basket-payment-draw-poisson-binomial ;customer procedure

  set basket-size rngs:rnd-poisson 3 ( customer-basket-mean-size )
  ifelse ( (rngs:rnd-uniform 3 0 1) < customer-cash-payment-rate )
    [set payment-method 1]
    [set payment-method 2]

end

to customer-basket-payment-draw ;;customer procedure
  ifelse customer-basket-payment = "ECDF (POS)" [
    customer-basket-payment-draw-ECDF
  ][
    customer-basket-payment-draw-poisson-binomial
  ]

end

to customer-sco-will-draw ; customer procedure
 ; this procedure decide if customer will consdider to picik sco queue
 ; some of them could not use sco in any case or there could general rule
 ; gneral rule of "expres line" threshold  is now implemented
  ifelse (basket-size <= customer-sco-item-thershold)
  [set sco-will? true]
  [set sco-will? false]
end

to customer-server-service-time-draw ;customer proccedure
;this procedure decide how service time for each customer is drawn
  if server-service-time-model = "EXPONENTIAL" [customer-server-service-time-draw-exponetial]
  if server-service-time-model = "Reg. model (POS)" [customer-server-service-time-draw-regression]

end

to customer-sco-server-service-time-draw ;customer proccedure
;this procedure decide how  service time on sco server for each customer is drawn
  if sco-server-service-time-model = "EXPONENTIAL" [customer-sco-server-service-time-draw-exponetial]
  if sco-server-service-time-model = "Reg. model (POS)" [customer-sco-server-service-time-draw-regression]
end

to customer-server-service-time-draw-regression ;;customer procedure
  ;set server-service-time according to power regression model with parameters  estimated according to POS data
  let transaction-time (e ^ ( 2.121935 + 0.698402 * ln basket-size + rngs:rnd-norm 4 0 0.4379083) ) / 60
  let break-time (rngs:rnd-gamma 4  3.074209 (1 / 4.830613)) / 60
  set server-service-time transaction-time + break-time
end

to customer-sco-server-service-time-draw-regression ; customer procedure
  ;set sco-server-service-time according to power regression model with parameters  estimated according to POS data
  let transaction-time (e ^ ( 3.122328 + 0.672461 * ln basket-size + rngs:rnd-norm 5 0 0.4907405) ) / 60
  let break-time (e ^ ( 3.51669 + 0.22300 * ln basket-size + rngs:rnd-norm 5 0 0.4820532) ) / 60
  set sco-server-service-time transaction-time + break-time
end

to customer-server-service-time-draw-exponetial ;;customer procedure
  ;set server-service-time according exponerial distribution with parameter  'server-service-time-expected'
  set server-service-time rngs:rnd-exponential 4 ( 1 / server-service-time-expected )
end

to customer-sco-server-service-time-draw-exponetial
   ;set 'sco-server-service-time' according exponerial distribution with parameter  'server-service-time-expected'
  set sco-server-service-time rngs:rnd-exponential 5 ( 1 / sco-server-service-time-expected )
end

to customer-picking-queue-strategy-draw ;customer procedure
  ; In this  procedure individual picking strategy couuld be assign to each customer. However in our model it's assumed that each customer select the same strategy. Nothing is drawn.
  ; Strategy is assign to all customers according to chosen parameter
  ifelse customer-picking-queue-strategy = 99 [
  let idraw rngs:rnd-uniform 6 0 1
    if (idraw <= 0.2) [set picking-queue-strategy 0]
    if (idraw > 0.2 and idraw <= 0.4)[set picking-queue-strategy 1]
    if (idraw > 0.4 and idraw <= 0.6)[set picking-queue-strategy 2]
    if (idraw > 0.6 and idraw <= 0.8) [set picking-queue-strategy 3]
   if (idraw > 0.8 and idraw <= 1.0) [set picking-queue-strategy 4]

  ][
    set picking-queue-strategy customer-picking-queue-strategy
  ]
end

to customer-jockeying-strategy-draw ;customer procedure
  ; In this  procedure individual jockeying strategy couuld be assign to each customer. However in our model it's assumed that each customer select the same strategy. Nothing is drawn.
  ; Strategy is assign to all customers according to chosen parameter

  ifelse customer-jockeying-strategy = 99 [
    let idraw rngs:rnd-uniform 7 0 1
    if (idraw <= 0.5)[ set jockeying-strategy 0]
    if (idraw > 0.5)[ set jockeying-strategy 1] ]
  [
    set jockeying-strategy customer-jockeying-strategy
  ]
end


to customer-jockeying-distance-draw ;customer procedure
  ; In this  procedure individual distance between queues for consideration jockeying couuld be assign to each customer. However in our model it's assumed that each customer select the same strategy.
  ; Strategy is assign to all customers according to chosen parameter
  ;set jockeying-strategy picking-queue-strategy
  ifelse customer-jockeying-distance = 99 [
    let idraw rngs:rnd-uniform 7 0 1
    if (idraw <= 0.2) [set jockeying-distance 0]
    if (idraw > 0.2 and idraw <= 0.4) [set jockeying-distance 1]
    if (idraw > 0.4 and idraw <= 0.6) [set jockeying-distance 2]
    if (idraw > 0.6 and idraw <= 0.8) [set jockeying-distance 3]
    if (idraw > 0.8 and idraw <= 1.0) [set jockeying-distance 4]]
  [
    set jockeying-distance customer-jockeying-distance
  ]
end


to customer-jockeying-threshold-draw
  ifelse customer-jockeying-threshold = 99 [
    let idraw rngs:rnd-uniform 8 0 1
    if (idraw <= 0.2) [set jockeying-threshold 1]
    if (idraw > 0.2 and idraw <= 0.4) [set jockeying-threshold 2]
    if (idraw > 0.4 and idraw <= 0.6) [set jockeying-threshold 3]
    if (idraw > 0.6 and idraw <= 0.8) [set jockeying-threshold 4]
    if (idraw > 0.8 and idraw <= 1.0) [set jockeying-threshold 5]]
  [
    set jockeying-threshold customer-jockeying-threshold
  ]

end

to-report server-waiting-time-expected-regression ;;server reporter
  ;report expected waiting time on queue of server
  ifelse is-agent? customer-being-served [
    report (sum ( [ customer-server-service-time-expected-regression ] of  customers with [member? self [server-queue] of myself ])) + (next-completion-time - ticks)
  ][
    report (sum ( [ customer-server-service-time-expected-regression ] of  customers with [member? self [server-queue] of myself ]))
  ]
end

to-report server-waiting-time-expected-mean ;;server reporter
  ;report expected waiting time according to assumed mean service time
  ;reporer use external parameter 'server-service-time-expected'
    ifelse is-agent? customer-being-served [
    report (( count  customers with [member? self [server-queue] of myself ])) * server-service-time-expected
  ][
    report ( count customers with [member? self [server-queue] of myself ]) * server-service-time-expected
  ]
end


to-report sco-zone-waiting-time-expected-regression
;report expected waiting time on sco-zone.  if no SCO checkout is define it return max run time
  let next-sco-server nobody
  ask sco-servers with [not open?] [set expected-waiting-time max-run-time]
  ask sco-servers with [open? and customer-being-served = nobody] [set expected-waiting-time ticks]
  ask sco-servers with [open? and customer-being-served != nobody] [set expected-waiting-time next-completion-time]
  foreach sco-zone-queue [
    x -> ask (min-one-of sco-servers [expected-waiting-time]) [set expected-waiting-time expected-waiting-time + [ customer-sco-server-service-time-expected-regression ] of x]
    ]
  report ([expected-waiting-time] of min-one-of sco-servers [expected-waiting-time]) - ticks

end

to-report sco-zone-waiting-time-expected-mean
;report expected waiting time on sco-zone according to assumed mean service time .  if no SCO checkout is define it return max run time
;reporer use external parameter 'sco-server-service-time-expected'
  ifelse any? sco-servers with [open?] [
    report ((length sco-zone-queue) * sco-server-service-time-expected)  / count sco-servers with [open?]
  ][
    report max-run-time]
end

to-report server-zone-waiting-time-expected-regression
;report expected waiting time on server-zone (single queue)
  let next-server nobody
  ask servers with [not open?] [set expected-waiting-time max-run-time]
  ask servers with [open? and customer-being-served = nobody] [set expected-waiting-time ticks]
  ask servers with [open? and customer-being-served != nobody] [set expected-waiting-time next-completion-time]
  foreach server-zone-queue [
    x -> ask (min-one-of servers [expected-waiting-time]) [set expected-waiting-time expected-waiting-time + [ customer-server-service-time-expected-regression ] of x]
    ]
  report ([expected-waiting-time] of min-one-of servers [expected-waiting-time]) - ticks
end

to-report server-zone-waiting-time-expected-mean
;report expected waiting time on server-zone (single queue) ccording to assumed mean service time
;reporer use external parameter 'server-service-time-expected'

  ifelse any? servers with [open?] [
    report ((length server-zone-queue) * server-service-time-expected)  / count servers with [open?]
  ][
    report  max-run-time
  ]
end


to-report customer-server-service-time-expected-regression ;;customer reporter
   ;report expected service time on server of customer
   let transaction-time-expected (e ^ ( 2.121935 + 0.698402 * ln basket-size) ) / 60
   let break-time-expected (3.074209 * (4.830613)) / 60
   report transaction-time-expected + break-time-expected
End

to-report customer-sco-server-service-time-expected-regression ;;customer reporter
   ;report expected service  time on sco-server of customer
   let transactiom-time-expected (e ^ ( 3.122328 + 0.672461 * ln basket-size) ) / 60
   let break-time-expected  (e ^ ( 3.51669 + 0.22300 * ln basket-size) ) / 60
   report transactiom-time-expected + break-time-expected
end

to customer-checkout-queue-pick  ; customer procedure
  if (picking-queue-strategy  = 0 )  [customer-checkout-queue-pick-strategy0 ]
  if (picking-queue-strategy  = 1 )  [customer-checkout-queue-pick-strategy1 ]
  if (picking-queue-strategy  = 2 )  [customer-checkout-queue-pick-strategy2 ]
  if (picking-queue-strategy  = 3 )  [customer-checkout-queue-pick-strategy3 ]
  if (picking-queue-strategy  = 4 )  [customer-checkout-queue-pick-strategy4 ]
end


;******pick line strategy 0 : the random queue**
to customer-checkout-queue-pick-strategy0    ;customer procedure
  ifelse single-queue? [
    let i random 2
    ifelse (i != 0) or (number-of-sco-servers = 0) or (not sco-will?) [
      set server-zone-queue-picked? TRUE
    ][
      set sco-zone-queue-picked? TRUE
    ]
  ][
    let available-servers (servers with [open?])
    let number-of-queues ( count available-servers )
    let i random number-of-queues
    ifelse (i != 0) or (number-of-sco-servers = 0) or (not sco-will?)
      [set server-picked one-of available-servers]
      [set server-picked nobody]
    if ( server-picked = nobody)[
      set sco-zone-queue-picked? TRUE]
  ]
  customer-checkout-queue-join
end

;******pick line strategy 1 : the minimal number of customers**
to customer-checkout-queue-pick-strategy1  ;customer procedure
  ifelse single-queue? [  ;if single queue for all servers
    if (length(server-zone-queue) <= length(sco-zone-queue)) or (not any? (sco-servers with [open?])) or (not sco-will?)[
      set server-zone-queue-picked? TRUE
      ]
    if ((length(server-zone-queue) > length(sco-zone-queue)) and sco-will?) or (not any? servers with [open?] )[
      set sco-zone-queue-picked? TRUE]
  ][ ;if all servers have sparate queues
    let iserver-picked (min-one-of (servers with [open?]) [length server-queue])
    ifelse iserver-picked != nobody [
      if (length([server-queue] of iserver-picked) <= length(sco-zone-queue)) or (not any? (sco-servers with [open?])) or (not sco-will?) [
        set server-picked iserver-picked
      ]
      if ((length([server-queue] of iserver-picked) > length(sco-zone-queue)) and sco-will?) or (iserver-picked = nobody)[
        set sco-zone-queue-picked? TRUE]
    ][
      set sco-zone-queue-picked? TRUE]
  ]

  customer-checkout-queue-join
end


to customer-checkout-queue-pick-strategy2 ;customer procedure



  let iserver-picked (min-one-of (servers with [open?])  [sum [basket-size] of turtle-set server-queue])

  let server-picked-item-number 0
  let sco-zone-item-number 0
  let server-zone-item-number 0

  if iserver-picked != nobody [set server-picked-item-number sum [basket-size] of turtle-set ( [server-queue] of iserver-picked) ]
  if not empty? sco-zone-queue [set  sco-zone-item-number sum [basket-size] of turtle-set ( sco-zone-queue )]
  if not empty? server-zone-queue [set  server-zone-item-number sum [basket-size] of turtle-set ( server-zone-queue )]

  ifelse single-queue? [  ;if single queue for all servers

    if (server-zone-item-number <= sco-zone-item-number) or (not any? (sco-servers with [open?])) or (not sco-will?)[
      set server-zone-queue-picked? TRUE
      ]
    if ((server-zone-item-number > sco-zone-item-number) and sco-will?) or (iserver-picked = nobody)[
      set sco-zone-queue-picked? TRUE]
  ][ ;if all servers have sparate queues

    if (server-picked-item-number <= sco-zone-item-number) or (not any? (sco-servers with [open?])) or (not sco-will?)[
      set server-picked iserver-picked]
    if ((server-picked-item-number > sco-zone-item-number) and sco-will?) or (iserver-picked = nobody)[
      set sco-zone-queue-picked? TRUE]
  ]

  customer-checkout-queue-join
end




;******pick line strategy  : the minimal expected time according to mean service time  **
to customer-checkout-queue-pick-strategy3
  let iserver-picked (min-one-of (servers with [open?])  [server-waiting-time-expected-mean])
  let server-picked-waiting-time-expected 0

  if iserver-picked != nobody [set server-picked-waiting-time-expected  [server-waiting-time-expected-mean] of iserver-picked ]

  ifelse single-queue? [  ;if single queue for all servers
    if (server-zone-waiting-time-expected-mean <= sco-zone-waiting-time-expected-mean) or (not any? (sco-servers with [open?])) or (not sco-will?)[
      set server-zone-queue-picked? TRUE
      ]
    if ((server-zone-waiting-time-expected-mean > sco-zone-waiting-time-expected-mean) and sco-will?) or (iserver-picked = nobody)[
      set sco-zone-queue-picked? TRUE]
  ]
  [ ;if all servers have sparate queues

    if (server-picked-waiting-time-expected <= sco-zone-waiting-time-expected-mean) or (not any? (sco-servers with [open?])) or (not sco-will?) [
      set server-picked iserver-picked]
    if ((server-picked-waiting-time-expected > sco-zone-waiting-time-expected-mean)and sco-will?) or (iserver-picked = nobody)[
      set sco-zone-queue-picked? TRUE]
  ]
  customer-checkout-queue-join
end



;******pick line strategy  : the minimal expected time according to number of items and expected time of transaction and break **
to customer-checkout-queue-pick-strategy4
  let iserver-picked (min-one-of (servers with [open?])  [server-waiting-time-expected-regression])
  let server-picked-waiting-time-expected 0

  if iserver-picked != nobody [set server-picked-waiting-time-expected  [server-waiting-time-expected-regression] of iserver-picked ]

  ifelse single-queue? [  ;if single queue for all servers
    if (server-zone-waiting-time-expected-regression <= sco-zone-waiting-time-expected-regression) or (not any? (sco-servers with [open?])) or (not sco-will?)[
      set server-zone-queue-picked? TRUE
      ]
    if ((server-zone-waiting-time-expected-regression > sco-zone-waiting-time-expected-regression) and sco-will?) or (iserver-picked = nobody)[
      set sco-zone-queue-picked? TRUE]
  ]
  [ ;if all servers have sparate queues
    if (server-picked-waiting-time-expected <= sco-zone-waiting-time-expected-regression) or (not any? (sco-servers with [open?])) or (not sco-will?) [
      set server-picked iserver-picked]
    if ((server-picked-waiting-time-expected > sco-zone-waiting-time-expected-regression) and sco-will?) or (iserver-picked = nobody)[
      set sco-zone-queue-picked? TRUE]
  ]
  ;print word "SCO zone: " sco-zone-waiting-time-expected-regression
  ;ask servers with [open?] [print word self server-waiting-time-expected-regression]
  ;print word "server-picked: " server-picked
  ;print word "sco-zone-queue-picked? " sco-zone-queue-picked?
  customer-checkout-queue-join
end

to customer-checkout-queue-join ;;customer procedure
  if ( server-picked != nobody)[
    ifelse [open?] of server-picked[
      set sco? false
      set server-queued-on server-picked
      set server-picked nobody
      set sco-zone-queue-picked? FALSE
      set time-entered-queue ticks
      customer-move-in-queue (length ([server-queue] of server-queued-on)) ([xcor] of server-queued-on ) ([ycor] of server-queued-on )
      ask server-queued-on  [
        set server-queue (lput myself server-queue)
        server-service-begin
      ]
    ][
      set sco? false
      set server-picked nobody
      set sco-zone-queue-picked? FALSE
      customer-checkout-queue-pick
    ]
  ]
  if (number-of-sco-servers != 0 and sco-zone-queue-picked? ) [
    set sco? true
    set sco-zone-queue-picked? FALSE
    set server-picked nobody
    set time-entered-queue ticks
    customer-move-in-queue (length sco-zone-queue) sco-zone-xcor sco-zone-ycor
    set sco-zone-queue (lput self sco-zone-queue)
    sco-servers-service-begin
  ]
  if (number-of-servers != 0 and server-zone-queue-picked? ) [
    set sco? false
    set sco-zone-queue-picked? FALSE
    set server-picked nobody
    set server-zone-queue-picked? FALSE
    set time-entered-queue ticks
    customer-move-in-queue (length server-zone-queue) server-zone-xcor server-zone-ycor
    set server-zone-queue (lput self server-zone-queue)
    servers-service-begin
  ]
end

to customer-checkout-queue-leave ;;customer procedure
;precedure removes customer from queue on which it actually queue on
  if ( server-queued-on != nobody)[
    ask server-queued-on [
      set server-queue remove myself server-queue
      move-queue-forward server-queue xcor ycor 0
    ]
    set server-queued-on nobody
    setxy 0 0
  ]
  if member? self sco-zone-queue [
    set sco-zone-queue remove self sco-zone-queue
    setxy 0 0
    move-queue-forward sco-zone-queue sco-zone-xcor sco-zone-ycor 0
  ]
  if member? self server-zone-queue [
    set server-zone-queue remove self server-zone-queue
    setxy 0 0
    move-queue-forward server-zone-queue server-zone-xcor server-zone-ycor 0
  ]
end

to customer-jockey-to-server [iserver]  ;customer procedure

 if (jockeying-strategy = 1) [customer-jockey-to-server-strategy1 iserver]
;  if (jockeying-strategy = 2) [customer-checkout-queue-pick-strategy2]
;  if (jockeying-strategy = 3) [customer-checkout-queue-pick-strategy3]
;  if (jockeying-strategy = 4) [customer-checkout-queue-pick-strategy4]
end




to customer-jockey-to-server-strategy1 [iserver]
   if customer-customers-in-queue >= ( ([length server-queue] of iserver) + jockeying-threshold)  [
    ;print (word "customer" self "jockey from " server-queued-on " to " iserver)
    customer-checkout-queue-leave
    set server-picked iserver
    customer-checkout-queue-join
    set jockeying-count jockeying-count + 1
  ]
end


to customer-jockey-to-sco-zone  ;customer procedure

 if (jockeying-strategy = 1) [customer-jockey-to-sco-zone-strategy1]
;  if (jockeying-strategy = 2) [customer-checkout-queue-pick-strategy2]
;  if (jockeying-strategy = 3) [customer-checkout-queue-pick-strategy3]
;  if (jockeying-strategy = 4) [customer-checkout-queue-pick-strategy4]
end




to customer-jockey-to-sco-zone-strategy1
   if customer-customers-in-queue >= ( (length sco-zone-queue) + jockeying-threshold)  [
    ;print (word "customer" self "jockey from " server-queued-on " to sco")
    customer-checkout-queue-leave
    set sco-zone-queue-picked? TRUE
    customer-checkout-queue-join
    set jockeying-count jockeying-count + 1
  ]
end



;to-report customer-jockey?-strategy2 ;customer procedure
;  let jockey? false
;  let server-min-item-number 99999
;  let sco-zone-item-number 99999
;  let server-zone-item-number 99999
;
;  if not single-queue? [
;    let iservers  [customer-servers-neighbors] of self
;    if any? (iservers with [open?])  [ set server-min-item-number min [sum([basket-size] of turtle-set server-queue)] of (iservers with [open?])]]
;  if sco-will? [set sco-zone-item-number sum([basket-size] of turtle-set sco-zone-queue)]
;  if single-queue? [set server-zone-item-number sum([basket-size] of turtle-set server-zone-queue)]
;
;  if (customer-item-number-in-queue > (min (list sco-zone-item-number  server-zone-item-number server-min-item-number)) + customer-jockeying-threshold * customer-basket-mean-size) [
;      set jockey? true
;    ]
;  report jockey?
;end
;
;
;to-report customer-jockey?-strategy3 ;customer procedure
;  let jockey? false
;  let iserver-zone-waiting-time-expected 99999
;  let isco-zone-waiting-time-expected 99999
;  let iserver-min-waiting-time-expected 99999
;
;  if single-queue? [set iserver-zone-waiting-time-expected server-zone-waiting-time-expected-mean]
;  if sco-will? [set isco-zone-waiting-time-expected sco-zone-waiting-time-expected-mean]
;  if not single-queue? [
;    let iservers  [customer-servers-neighbors] of self
;    if any? (iservers with [open?]) [set iserver-min-waiting-time-expected  min ([server-waiting-time-expected-mean] of iservers with [open?])]
;  ]
;
;  if (customer-waiting-time-expected-mean > ( min(list iserver-min-waiting-time-expected isco-zone-waiting-time-expected iserver-zone-waiting-time-expected)) + customer-jockeying-threshold * server-service-time-expected) [
;      set jockey? true
;  ]
;
;  report jockey?
;end
;
;to-report customer-jockey?-strategy4 ;customer procedure
;  let jockey? false
;
;  let iserver-zone-waiting-time-expected 99999
;  let isco-zone-waiting-time-expected 99999
;  let iserver-min-waiting-time-expected 99999
;
;  if single-queue? [set iserver-zone-waiting-time-expected server-zone-waiting-time-expected-regression]
;  if sco-will? [set isco-zone-waiting-time-expected sco-zone-waiting-time-expected-regression ]
;  if not single-queue? [
;    let iservers  [customer-servers-neighbors] of self
;    if any? (iservers with [open?])   [set iserver-min-waiting-time-expected  min ([server-waiting-time-expected-regression] of iservers with [open?])]
;  ]
;  if (customer-waiting-time-expected-regression > ( min(list iserver-min-waiting-time-expected isco-zone-waiting-time-expected iserver-zone-waiting-time-expected)) + customer-jockeying-threshold * server-service-time-expected) [
;    set jockey? true
;  ]
;  report jockey?
;end






to-report customer-customers-in-queue  ;;customer reporter
;report number of customers before customer in queue
  let icustomers-in-queue 0
  if ( server-queued-on != nobody)[
    ask server-queued-on [ set icustomers-in-queue  length (sublist server-queue 0 (position myself server-queue))]
  ]
  if member? self sco-zone-queue [
   set icustomers-in-queue length (sublist sco-zone-queue 0 (position self sco-zone-queue))
  ]
  if member? self server-zone-queue [
      set icustomers-in-queue  length (sublist server-zone-queue 0 (position self sco-zone-queue))
  ]
  report icustomers-in-queue
end

to-report customer-item-number-in-queue  ;;customer reporter
;report number of items before customer in queue
  let iitem-number-in-queue 0
  if ( server-queued-on != nobody)[
    ask server-queued-on [
      set iitem-number-in-queue sum ( map [i -> [basket-size] of i] (sublist server-queue 0 (position myself server-queue)))
    ]
  ]
  if member? self sco-zone-queue [
    if any? sco-servers with [open?] [
      set iitem-number-in-queue sum ( map [i -> [basket-size] of i] (sublist sco-zone-queue 0 (position self sco-zone-queue)))
    ]
  ]
  if member? self server-zone-queue [
    if any? servers with [open?] [
      set iitem-number-in-queue  sum ( map [i -> [basket-size] of i] (sublist server-zone-queue 0 (position self server-zone-queue)))
    ]
  ]
  report iitem-number-in-queue
end


to-report customer-waiting-time-expected-regression  ;;customer procedure
;precedure calculate expected waiting time of customer in queue
  let iwaiting-time-expected 0
  if ( server-queued-on != nobody)[
    ask server-queued-on [
      ifelse is-agent? customer-being-served [
        set iwaiting-time-expected sum ( map [i -> [customer-server-service-time-expected-regression] of i] (sublist server-queue 0 (position myself server-queue))) ;+ (next-completion-time - ticks)
      ][
        set iwaiting-time-expected sum ( map [i -> [customer-server-service-time-expected-regression] of i] (sublist server-queue 0 (position myself server-queue)))
      ]
    ]
  ]
  if member? self sco-zone-queue [
    if any? sco-servers with [open?] [
      let next-sco-server  min-one-of sco-servers with [next-completion-time > ticks] [next-completion-time]
      ;select sco-server that next finish service
      ifelse next-sco-server != nobody [
        set iwaiting-time-expected sum ( map [i -> [customer-server-service-time-expected-regression] of i] (sublist sco-zone-queue 0 (position self sco-zone-queue))) / count sco-servers with [open?] ;+ ( [next-completion-time] of next-sco-server - ticks )
      ][
        set iwaiting-time-expected sum ( map [i -> [customer-server-service-time-expected-regression] of i] (sublist sco-zone-queue 0 (position self sco-zone-queue))) / count sco-servers with [open?]
      ]
    ]
  ]
  if member? self server-zone-queue [
    let next-server  min-one-of servers with [open? and next-completion-time > ticks] [next-completion-time]
  ;select sco-server that next finish service
    if any? servers with [open?] [
      ifelse next-server != nobody  [
        set iwaiting-time-expected  sum ( map [i -> [customer-server-service-time-expected-regression] of i] (sublist server-zone-queue 0 (position self server-zone-queue))) / count servers with [open?] ;+  ( [next-completion-time] of next-server - ticks )
      ][
        set iwaiting-time-expected  sum ( map [i -> [customer-server-service-time-expected-regression] of i] (sublist server-zone-queue 0 (position self server-zone-queue))) / count servers with [open?]
      ]
    ]
  ]
  report iwaiting-time-expected
end

to-report customer-waiting-time-expected-mean  ;;customer procedure
;precedure calculate expected waiting time of customer in queue
  let iwaiting-time-expected 0
  if ( server-queued-on != nobody)[
    ask server-queued-on [
      ifelse is-agent? customer-being-served [
        set iwaiting-time-expected (position myself server-queue + 1 ) * server-service-time-expected
      ][
        set iwaiting-time-expected (position myself server-queue) * server-service-time-expected
      ]
    ]
  ]
  if member? self sco-zone-queue [
    if any? sco-servers with [open?] [
      set iwaiting-time-expected ((position self sco-zone-queue ) * sco-server-service-time-expected / count sco-servers with [open?])
    ]
  ]
  if member? self server-zone-queue [
    let next-server  min-one-of servers with [open? and next-completion-time > ticks] [next-completion-time]
  ;select sco-server that next finish service
    if any? servers with [open?] [
      set iwaiting-time-expected ((position self server-zone-queue ) * server-service-time-expected / count servers with [open?])
    ]
  ]
  report iwaiting-time-expected
end

to customer-model-leave ;;customer procedure
  set time-leaving-model ticks
  customer-update-output-file
  customer-update-satistic  "model-leave"
  die
end

to customer-update-output-file
  ;procedure update list with customer data to be written
  if empty? customers-output-file-list [
    set customers-output-file-list fput (list "customer-arrival-input-file" "customer-picking-queue-strategy"  "customer-jockeying-strategy" "customer-jockeying-distance" "customer-jockeying-threshold"
      "who" "server-service-time" "sco-server-service-time" "basket-size"  "payment-method" "sco-will?" "picking-queue-strategy" "jockeying-strategy" "jockeying-distance" "jockeying-threshold"
      "time-entered-model" "time-entered-store" "time-entered-queue" "time-entered-service" "time-leaving-model"
      "server-served-on" "sco?" "num-of-servers" "num-of-sco" "num-of-customers" "num-of-articles" "jockeying-count" "experiment") customers-output-file-list
  ]
  set customers-output-file-list lput (list customer-arrival-input-file customer-picking-queue-strategy customer-jockeying-strategy customer-jockeying-distance customer-jockeying-threshold
    who server-service-time sco-server-service-time basket-size payment-method sco-will? picking-queue-strategy jockeying-strategy jockeying-distance jockeying-threshold
    ticks-to-time time-entered-model ticks-to-time time-entered-store ticks-to-time time-entered-queue ticks-to-time time-entered-service ticks-to-time time-leaving-model
    server-served-on sco? num-of-servers num-of-sco num-of-customers num-of-articles jockeying-count experiment) customers-output-file-list
end

to customer-update-satistic [utype]
  if utype = "arrival" [
    set customer-arrival-count (customer-arrival-count + 1)
    set customer-arrival-count-minute (customer-arrival-count-minute + 1)
    set customer-arrival-count-hour (customer-arrival-count-hour + 1)
  ]

  if utype = "model-leave" [
    set customer-leaving-count ( customer-leaving-count + 1 )
    set customer-leaving-count-hour ( customer-leaving-count-hour + 1 )
    set customer-checkout-queue-time ( customer-checkout-queue-time + time-entered-service - time-entered-queue)
    set customer-checkout-queue-time-hour ( customer-checkout-queue-time-hour + time-entered-service - time-entered-queue)
    if time-entered-service > time-entered-queue [
      set customer-leaving-waiting-count customer-leaving-waiting-count + 1
      set customer-leaving-waiting-count-hour customer-leaving-waiting-count-hour + 1
    ]

    if (time-entered-service - time-entered-queue) > 5 [
      set customer-leaving-waiting5-count customer-leaving-waiting5-count + 1
      set customer-leaving-waiting5-count-hour customer-leaving-waiting5-count-hour + 1
    ]


    if sco? [
      set customer-leaving-count-server customer-leaving-count-server + 1
      set customer-leaving-count-server-hour customer-leaving-count-server-hour + 1
      set customer-leaving-queue-time-server customer-leaving-queue-time-server + time-entered-service - time-entered-queue
      set customer-leaving-queue-time-server-hour customer-leaving-queue-time-server-hour + time-entered-service - time-entered-queue

      if time-entered-service > time-entered-queue [
        set customer-leaving-waiting-count-server customer-leaving-waiting-count-server + 1
        set customer-leaving-waiting-count-server-hour customer-leaving-waiting-count-server-hour + 1
      ]
      if (time-entered-service - time-entered-queue) > 5[
        set customer-leaving-waiting5-count-server customer-leaving-waiting5-count-server + 1
        set customer-leaving-waiting5-count-server-hour customer-leaving-waiting5-count-server-hour + 1
      ]
    ]

    if sco? [
      set customer-leaving-count-sco customer-leaving-count-sco + 1
      set customer-leaving-count-sco-hour customer-leaving-count-sco-hour + 1
      set customer-leaving-queue-time-sco customer-leaving-queue-time-sco + time-entered-service - time-entered-queue
      set customer-leaving-queue-time-sco-hour customer-leaving-queue-time-sco-hour + time-entered-service - time-entered-queue
      if time-entered-service > time-entered-queue [
        set customer-leaving-waiting-count-sco customer-leaving-waiting-count-sco + 1
        set customer-leaving-waiting-count-sco-hour customer-leaving-waiting-count-sco-hour + 1
      ]
      if (time-entered-service - time-entered-queue) > 5 [
        set customer-leaving-waiting5-count-sco customer-leaving-waiting5-count-sco + 1
        set customer-leaving-waiting5-count-sco-hour customer-leaving-waiting5-count-sco-hour + 1
      ]
    ]
    set customer-service-time  ( customer-service-time + time-leaving-model - time-entered-service )
    set customer-service-time-hour ( customer-service-time-hour + time-leaving-model - time-entered-service )
    set customer-checkout-queue-mean-time ( customer-checkout-queue-time / customer-leaving-count )
  ]
end

to customer-update-statistic-hour
  set customer-arrival-count-hour 0
  set customer-leaving-count-not-infected-hour 0
  set customer-leaving-count-sco-hour 0
  set customer-leaving-waiting-count-hour 0
  set customer-leaving-waiting-count-server-hour 0
  set customer-leaving-waiting-count-sco-hour 0
  set customer-leaving-waiting5-count-hour 0
  set customer-leaving-waiting5-count-server-hour 0
  set customer-leaving-waiting5-count-sco-hour 0
  set customer-leaving-queue-time-server-hour 0
  set customer-leaving-queue-time-sco-hour 0
  set customer-leaving-exposed-count-hour 0
  set customer-leaving-exposure-time-hour 0
  set customer-leaving-exposure-count-hour 0
  set customer-leaving-count-hour 0
  set customer-checkout-queue-time-hour 0
  set customer-service-time-hour 0
  set customer-leaving-queue-time-not-infected-hour 0
  set customer-leaving-count-server-hour 0
end

to customer-update-statistic-minute
  set customer-arrival-count-minute 0
end

to server-service-begin ;;server procedure
  let bs 0
  let next-customer nobody
  if cashier-working-on != nobody[
    if (not is-agent? (customer-being-served ))[
      if (not empty? server-queue)[
        set next-customer (first server-queue)
        set server-queue  (but-first server-queue)
        move-queue-forward server-queue xcor ycor 0
      ]
      if (not empty? server-zone-queue)[
        set next-customer (first server-zone-queue)
        set server-zone-queue  (but-first server-zone-queue)
        move-queue-forward server-zone-queue server-zone-xcor server-zone-ycor 0
      ]
      ifelse next-customer != nobody [
        set customer-being-served next-customer
        set next-completion-time (ticks + [server-service-time] of next-customer )
        ask next-customer [
          set time-entered-service ticks
          set server-queued-on nobody
          set server-served-on myself
          set bs basket-size
          customer-move-to-server myself
        ]
        ; update server statisti of usage
        set time-break-end ticks
        set break-length ( break-length + time-break-end - time-break-start )
        if (time-break-end > time-break-start)[
          set break-count  break-count + 1
        ]
        recolor-server
      ][
        if not (open?) [ask cashier-working-on  [cashier-server-leave ]]
      ]

    ]
  ]
end

to servers-service-begin
  let available-server  one-of servers with [open? and not is-agent? (customer-being-served )]
  if available-server != nobody [
    ask available-server [
      server-service-begin
    ]
  ]
end

to server-complete-service [server-id]
  ask (server server-id) [
    ;print word word "customer: " customer-being-served  word server-id ticks
    ask customer-being-served [ customer-model-leave ]

    set next-completion-time 0
    ; update server statistic of working
    set time-break-start ticks
    recolor-server
    server-service-begin
    if cashier-working-on != nobody  [ask cashier-working-on [ if cashier-server-close-check?  [cashier-server-close ] ] ]
    ;print (word "server " self  "customers: " ([who] of server-customers-to-jockey))
    ask server-customers-to-jockey  [customer-jockey-to-server myself]
  ]
end

to-report server-customers-to-jockey
  let ipxcor pxcor
  let ipycor pycor
  report customers with [(server-served-on = nobody) and (xcor >= ( ipxcor - jockeying-distance )) and (xcor <= ( ipxcor + jockeying-distance )) and (xcor != ipxcor)]

end



to-report sco-zone-customers-to-jockey
  let ipxcor sco-zone-xcor
  let ipycor sco-zone-ycor
  report customers with [(server-served-on = nobody) and (xcor >= ( ipxcor - (floor (distance-sco-sco-h / 2)) - jockeying-distance - 1 )) and (xcor <= ( ipxcor + (floor (distance-sco-sco-h / 2)) + jockeying-distance + 1)) and (xcor != ipxcor) ]
end





to sco-servers-service-begin
  let available-sco-servers (sco-servers with [not is-agent? customer-being-served])
  let bs 0
  if (not empty? sco-zone-queue and any? available-sco-servers) [
    let next-customer (first sco-zone-queue)
    let next-sco-server one-of available-sco-servers
    set sco-zone-queue (but-first sco-zone-queue)
    ;set sco-expected-waiting-time  sco_ewt sco-zone-queue
    ask next-customer [
      set time-entered-service ticks
      set bs basket-size
      set server-served-on next-sco-server
      ;print word "server-served-on" server-served-on
      customer-move-to-server next-sco-server]
    ask next-sco-server [
      set customer-being-served next-customer
      set next-completion-time (ticks + [sco-server-service-time] of next-customer)
      ; update sco-server statistic of usage
      set time-break-end ticks
      set break-length ( break-length + time-break-end - time-break-start )
      if (time-break-end > time-break-start)[
        set break-count  break-count + 1
      ]
      recolor-sco-server]
    move-queue-forward sco-zone-queue sco-zone-xcor sco-zone-ycor 0
    ]
end

to sco-server-complete-service [sco-server-id]
  ask (sco-server sco-server-id) [
    ask customer-being-served [ customer-model-leave ]
     ask cashiers with [working?] [
      ;cashier-server-close
    ]
    set next-completion-time 0
    set label ""
    ; update sco-server statistic of usage
    set time-break-start ticks
    recolor-sco-server]
   sco-servers-service-begin
   ask sco-zone-customers-to-jockey  [customer-jockey-to-sco-zone]
end


to-report cashier-arrival-time-schedule

  ifelse cashier-arrival = "workschedule (POS)" [
    report time:difference-between start-time (first ts-get-next cashier-arrival-input current-time "all" )  "minutes"
  ][
    report time:difference-between start-time time:create "9999-12-31 00:00:00" "minutes"
  ]

end


to cashiers-store-arrive
  let line time:ts-get cashier-arrival-input current-time "all"
  if ( time:difference-between first line current-time "minutes") < 300 [
    let inumber-of-cashiers item 1 line
    cashiers-create inumber-of-cashiers cashier-work-time
  ]
end

to cashiers-create [quantity time-of-work ]
;create cashiers of quantity
if quantity > 0 [
  create-cashiers quantity [
     set time-start ticks
     set time-end ticks + time-of-work
     set xcor 0
     set ycor 0
     set time-break-start ticks
     set time-break-end max-run-time
     set break-count 0
     set break-length 0
     set shape "cashier-checkout"
     set working? false
     set backoffice? false
     recolor-cashier
    ]
   cashiers-backoffice-go
   if (cashier-server-enter-check?) [cashiers-server-enter]
  ]

end

to cashier-backoffice-go ;cashier procedue
  set shape "person"
  set working? false
  set backoffice? true
  set time-break-start ticks
  set server-working-on nobody
  set cashiers-backoffice lput self cashiers-backoffice
  cashier-update-satistic "backoffice-go"
  move-cashiers-backoffice
end

to cashiers-backoffice-go
  ask cashiers with [not working?] [cashier-backoffice-go]
end

to-report cashier-server-enter-check?
  let icheck? false
  ifelse single-queue? [
    if (any? servers with [open?]) and (not any? (servers with [open?])) or ((length server-zone-queue + length sco-zone-queue) / (count  (servers with [open?]) + 1)  > cashier-max-line) [set icheck? true] ]
  [
    if  (not any? (servers with [open?])) or ((sum ([length(server-queue)] of (servers with [open?])) + length(sco-zone-queue)) / (count  (servers with [open?]) + 1)  > cashier-max-line) [set icheck? true]
  ]
  report icheck?
end


to cashier-server-enter-time-schedule
  if cashier-server-enter-next-time < ticks [set cashier-server-enter-next-time  (ticks + cashier-return-time)]
end

to cashier-server-enter ;cashier procedure
  let server-to-work nobody
  let available-servers []
  ;First choice: server with cashiers that alredy closed checkout
  set available-servers (servers with [not open? and is-agent? cashier-working-on])
  ;Second choice servers with cashiers that should end of work till now
  if not (any? available-servers)[
    set available-servers (servers with [open? and is-agent? cashier-working-on and [time-end] of cashier-working-on <= (ticks + 1) ])
  ]
  ;Third choice closed checkout w/o cashier
  if not (any? available-servers) [
    set available-servers (servers with [not open? and not is-agent? cashier-working-on])
  ]

  set server-to-work min-one-of available-servers [who]
  ifelse server-to-work != nobody [
    ask server-to-work [
      if cashier-working-on != nobody [ ask cashier-working-on [cashier-server-leave] ]
      set cashier-working-on myself
      set open? true
      recolor-server
    ]
    set xcor [xcor] of server-to-work
    set ycor [ycor] of server-to-work
    set server-working-on server-to-work
    set working? true
    set time-break-end ticks
    set time-work-start ticks
    set work-count work-count + 1
    set break-length ( break-length + time-break-end - time-break-start )
    if (time-break-end > time-break-start)[ set break-count  break-count + 1 ]
    cashier-update-satistic "server-enter"
    recolor-cashier
    set cashiers-backoffice  remove self cashiers-backoffice
    move-cashiers-backoffice
    ask [server-customers-to-jockey]  of server-to-work  [customer-jockey-to-server server-to-work]
  ][
    cashier-backoffice-go
  ]



end

to cashiers-server-enter
;chose one of cashier in backoffice to go server
  if ( not empty? cashiers-backoffice ) [
    ask first cashiers-backoffice [cashier-server-enter]
  ]
end

to-report cashier-server-close-check? ;cashier procedure
 ; check if checkout can be closed:  Checkout can by closed in two cases working time of cashier is end or avarage queue is shortest than threshold
 let icheck? false
 if (((count servers with [open?]) > 1) or (number-of-sco-servers > 0))
  [
    ifelse ( single-queue?)
    [
      if (((length server-zone-queue + length sco-zone-queue) / (count  (servers with [open?]) + 1))  < cashier-min-line) [set icheck? true]]
    [
      if ((empty? [server-queue] of server-working-on) and ((sum ([length(server-queue)] of (servers with [open?])) + length(sco-zone-queue)) / (count  (servers with [open?]) + 1)  < cashier-min-line)) [set icheck? true]
    ]
  ]
  report icheck?
end

to cashier-server-close ;cashier procedure
  ;check if checkout can be close. if so close it
  ask server-working-on [ set open? false recolor-server ]
  if [customer-being-served] of server-working-on = nobody [
    cashier-server-leave ]
end

to cashiers-server-close
  ask cashiers with [working? and time-end <= ticks] [cashier-server-close]
  ask cashiers with [(time-end <= ticks) and not working?] [cashier-model-leave]
end

to-report cashier-server-leave-check? ;cashier procedure
;this reporter check if cashier can leave checkout
 let check? false
  if not ( [open?] of server-working-on ) and (( [customer-being-served] of server-working-on ) = nobody)  [
    if ( single-queue? and ( empty? server-zone-queue or ( not empty? server-zone-queue and any? servers with [open?] ))) [
      set check? true
    ]
    if (not single-queue? and empty? [server-queue] of server-working-on ) [
      set check? true ]
  ]
report check?
end


to cashier-server-leave ;cashier procedure
  set time-break-start ticks
  set time-work-end ticks
  set work-length ( work-length + time-work-end - time-work-start )
  if (time-work-end > time-work-start)[ set work-count  work-count + 1 ]
  set working? false
  ;set xcor 0
  ;set ycor 0
  ;print word ([customer-being-served] of server-working-on)  word word self  " leved server:  " word  server-working-on ticks
  ask server-working-on [
    set cashier-working-on nobody
    set expected-waiting-time 0
  ]
  recolor-cashier
  cashier-backoffice-go
  cashier-model-leave
end

to cashier-model-leave ;cashier procedure
  if (not working? and time-end <= ticks)[
    ;;;;;;print word "lista: " (list logo_clock ticks time-start time-end time-break-start time-break-end time-break-count time-break-length)
    ;time:ts-add-row cashier-leaving-data-file (list logo_clock ticks time-start time-end time-break-start time-break-end time-break-count time-break-length  )

    set time-break-end ticks
    set cashiers-backoffice remove self cashiers-backoffice
    move-cashiers-backoffice
    set break-length ( break-length + time-break-end - time-break-start )
    if (time-break-end > time-break-start) [set break-count  break-count + 1 ]
    cashier-update-output-file-list
    cashier-update-satistic "model-leave"
    die
  ]
end

to cashiers-model-leave
  ;ask all cashiers that not woring and out of schdule to go home
  ask cashiers with [not working? and time-end < ticks] [
    cashier-model-leave
  ]

end
to cashier-update-output-file-list

  if empty? cashier-output-file-list [
    set cashier-output-file-list fput (list "cashier-arrival-input-file" "customer-picking-queue-strategy" "customer-jockeying-strategy" "who" "time-real-end" "time-start" "time-end" "break-count" "break-length" "work-count" "work-length" "experiment") cashier-output-file-list
  ]
  set cashier-output-file-list lput (list cashier-arrival-input-file customer-picking-queue-strategy customer-jockeying-strategy who ticks-to-time ticks ticks-to-time time-start ticks-to-time time-end break-count break-length work-count work-length experiment) cashier-output-file-list
end

to cashier-update-satistic [utype]
  if utype = "arrival" [
    ;set customer-arrival-count (customer-arrival-count + 1)
    ;set customer-arrival-count-minute (customer-arrival-count-minute + 1)
    ;set customer-arrival-count-hour (customer-arrival-count-hour + 1)
  ]

  if utype = "backoffice-go" [

    set cashier-working-length-hour 0
    ;set cashier-server-leaving-effective-working-length cashier-server-leaving-working-length + ( ticks - time-break-end )
    set cashier-effective-working-length-hour 0
  ]

  if utype = "server-enter" [
   ;set cashier-server-leaving-working-length cashier-server-leaving-working-length + (ticks - time-break-start)

  ]



  if utype = "model-leave" [
    set cashier-working-length cashier-working-length + ( ticks - time-start )
    set cashier-effective-working-length cashier-effective-working-length + ( ticks - time-start - break-length)
    set cashier-break-count cashier-break-count + break-count
  ]

end


to-report next-server-complete
  report (min-one-of (servers with [is-agent? customer-being-served]) [next-completion-time])
end

to-report next-sco-server-complete
  report (min-one-of (sco-servers with [is-agent? customer-being-served]) [next-completion-time])
end


;to-report next-second-schedule  ;report next second in ticks (ticks are in min)
;  report ((( floor ( ticks * 60 )) / 60 ) +  0.016667 )
;end

;to next-second-events-complete  ;events to be done every second
;
;end

to-report next-minute-schedule  ;report next minute in ticks
  report (( floor ( ticks )) +  1 )
end

to next-minute-events-complete  ;events to be done every minute

  update-plots
  customer-update-statistic-minute
  set ticks-minute (ticks-minute + 1)
end


to-report next-hour-schedule  ;report next hour in ticks (ticks are in min)
  report ( 60 * ( floor ( ticks / 60 )  ) +  60 )
end

to next-hour-events-complete ;events to be done every second
  update-plots
  ;print word "ticks-hour " ticks-hour
  ;ifelse customer-leaving-count-hour != 0   [
  ;  print word ticks word " + " ( customer-leaving-waiting5-count-hour / customer-leaving-count-hour )
  ;][
  ;  print word ticks word " + " 0
  ;]
  customer-update-statistic-hour

  set ticks-hour ( ticks-hour + 1 )
end

to-report next-day-schedule  ;report next hour in ticks (ticks are in min)
  report ( 60 * 24 * ( floor ( ticks / (60 * 24))) + ( 60  * 24))
end

to next-day-events-complete
  if (customers-output-file-list != []) [csv:to-file customers-output-file customers-output-file-list]
  set customers-output-file-list []

  if (cashier-output-file-list != []) [csv:to-file  cashiers-output-file cashier-output-file-list]
  set cashier-output-file-list []

end
to end-run-complete
  next-day-events-complete

end

to-report ts-get-next [ logotimeseries logotime column-name ]
  ;report time series line after logotime
  let i 0
  let line time:ts-get logotimeseries logotime column-name
  let endline time:ts-get logotimeseries time:create "9999-12-31 00:00:00" column-name
  while [ (( time:difference-between logotime first line "minutes") <= 0) and line != endline ] [
    set i ( i + 1 )
    set line time:ts-get logotimeseries (time:plus logotime i "minutes") column-name
  ]
  report line
end

to-report ticks-to-time [itick]
  report time:show  (time:plus start-time itick "minutes") "yyyy-MM-dd HH:mm:ss"
end

to-report cashier-server-close-next-time
  ifelse (any? cashiers with [time-end >= ticks])[
    report [time-end] of min-one-of (cashiers with [time-end >= ticks]) [time-end]][
    report 0 ]
end
to go
  ifelse (ticks < max-run-time) [

    ;schedule of events done regulary i.e every second or hour
    ;let next-minute next-minute-schedule
    if next-minute <= ticks [ set next-minute next-minute-schedule ]
    ;print next-minute
    if next-hour <= ticks [ set next-hour next-hour-schedule ]

    ;print word ticks-hour word " - " ticks-minute

    if next-day <= ticks [ set next-day next-day-schedule ]

    ;schedule of events done discret
    if customer-arrival-next-time <= ticks  [ set customer-arrival-next-time (customer-arrival-time-schedule)]

    if cashier-arrival-next-time <= ticks [ set cashier-arrival-next-time  (cashier-arrival-time-schedule)]

    ;if cashier-server-leave-next-time <= ticks [set cashier-server-leave-next-time]
    set next-server-to-complete next-server-complete
    set next-sco-server-to-complete next-sco-server-complete

    ;set of events to list that is events queue to do within one go loop
    let event-queue (list (list max-run-time "end-run-complete"))

    ;**** firstly set to list  events done regulary
    ;if (next-second > ticks)[
    ;  set event-queue (fput (list next-second "next-second-events-complete") event-queue)]
     if (next-hour > ticks)[
      set event-queue (fput (list next-hour "next-hour-events-complete") event-queue)]

    if (next-minute > ticks)[
      set event-queue (fput (list next-minute "next-minute-events-complete") event-queue)]

    if (next-day > ticks)[
      set event-queue (fput (list next-day "next-day-events-complete") event-queue)]



    ;**** secondly set to list events done discretly
    if (customer-arrival-next-time > ticks)[
      set event-queue (fput (list customer-arrival-next-time "customer-store-arrive") event-queue)]

    if (cashier-arrival-next-time > ticks)[
      set event-queue (fput (list cashier-arrival-next-time "cashiers-store-arrive") event-queue)]

    if (cashier-server-enter-next-time > ticks)[
      set event-queue (fput (list cashier-server-enter-next-time "cashiers-server-enter") event-queue)]

    if (cashier-server-close-next-time) > ticks [
     set event-queue (fput (list cashier-server-close-next-time "cashiers-server-close") event-queue)]

    if (is-turtle? next-server-to-complete)[
      set event-queue (fput (list ([next-completion-time] of next-server-to-complete) "server-complete-service" ([who] of next-server-to-complete)) event-queue)]

    if (is-turtle? next-sco-server-to-complete)[
      set event-queue (fput (list ([next-completion-time] of next-sco-server-to-complete)
                                  "sco-server-complete-service" ([who] of next-sco-server-to-complete)) event-queue)]

    ;sort list of events according to time
    set event-queue (sort-by [ [ ?1 ?2 ] -> first ?1 < first ?2] event-queue)
    ;print event-queue

    ;run every event in list one by one
    let first-event first event-queue
    let next-event []
    ;print event-queue
    tick-advance ( (first first-event) - ticks)
    foreach event-queue [
      x -> set next-event x if ((first first-event) = (first next-event)) [
        run (reduce [ [ ?1 ?2 ] -> (word ?1 " " ?2)] (but-first next-event))
        ;print (reduce [ [ ?1 ?2 ] -> (word ?1 " " ?2)] (but-first next-event))
      ]
    ]
  ][; end of go
    stop
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
-2
65
662
410
-1
-1
16.0
1
9
1
1
1
0
1
1
1
-20
20
-10
10
0
0
1
ticks
50.0

SLIDER
4
790
134
823
number-of-servers
number-of-servers
0
20
20.0
1
1
NIL
HORIZONTAL

BUTTON
1
427
56
460
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
58
427
113
460
Next
go
NIL
1
T
OBSERVER
NIL
N
NIL
NIL
1

BUTTON
117
427
172
460
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
1

MONITOR
126
10
300
55
simulation current time
time:show current-time \"EEEE, dd.MM.YYYY HH:mm:ss\"
3
1
11

TEXTBOX
3
410
153
428
controls
11
0.0
1

TEXTBOX
5
775
182
794
servers (checkout) parameters
11
0.0
1

SLIDER
129
563
259
596
customer-cash-payment-rate
customer-cash-payment-rate
0
1
0.2
0.1
1
NIL
HORIZONTAL

CHOOSER
259
484
392
529
customer-picking-queue-strategy
customer-picking-queue-strategy
0 1 2 3 4 99
3

TEXTBOX
5
466
155
484
customers parameters
11
0.0
1

TEXTBOX
398
469
548
487
cashiers parameters
11
0.0
1

SLIDER
396
562
532
595
number-of-cashiers
number-of-cashiers
0
number-of-servers
0.0
1
1
NIL
HORIZONTAL

SLIDER
2
531
131
564
customer-arrival-mean-rate
customer-arrival-mean-rate
0
25
6.618
0.001
1
NIL
HORIZONTAL

SLIDER
129
531
259
564
customer-basket-mean-size
customer-basket-mean-size
0
100
9.0
1
1
NIL
HORIZONTAL

SLIDER
176
427
391
460
simulation-end-day
simulation-end-day
simulation-start-day
20
18.0
1
1
NIL
HORIZONTAL

PLOT
670
439
1239
559
customers served count
hours
count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"all             " 1.0 0 -7500403 true "" "if (ticks-minute / 60) = ticks-hour [plotxy ticks-hour customer-leaving-count-hour]"
"self-service" 1.0 0 -16448764 true "" "if (ticks-minute / 60) = ticks-hour [plotxy ticks-hour customer-leaving-count-sco-hour]"
"service" 1.0 0 -13345367 true "" "if (ticks-minute / 60) = ticks-hour [ plotxy ticks-hour  customer-leaving-count-hour - customer-leaving-count-sco-hour]"

PLOT
670
559
1239
679
mean queue times 
hours
minutes
0.0
10.0
0.0
5.0
true
true
"" ""
PENS
"all " 1.0 0 -9276814 true "" "if (customer-leaving-count-hour != 0) and ((ticks-minute / 60) = (ticks-hour ) ) [ \nplotxy ticks-hour (customer-checkout-queue-time-hour / customer-leaving-count-hour)]\nif (customer-leaving-count-hour = 0) and ((ticks-minute / 60) = (ticks-hour ) ) [ \nplotxy ticks-hour 0]"
"self-service" 1.0 0 -16777216 true "" "if (customer-leaving-count-sco-hour != 0 ) and ((ticks-minute / 60) = (ticks-hour)) [\nplotxy ticks-hour customer-leaving-queue-time-sco-hour / customer-leaving-count-sco-hour]\nif (customer-leaving-count-sco-hour = 0 ) and ((ticks-minute / 60) = (ticks-hour)) [\nplotxy ticks-hour 0]"
"service" 1.0 0 -14070903 true "" "if ( ( customer-leaving-count-hour - customer-leaving-count-sco-hour ) != 0 ) and ((ticks-minute / 60) = (ticks-hour)) [\nplotxy ticks-hour customer-leaving-queue-time-server-hour / ( customer-leaving-count-hour - customer-leaving-count-sco-hour )\n]\n\nif ( ( customer-leaving-count-hour - customer-leaving-count-sco-hour ) = 0 ) and ((ticks-minute / 60) = (ticks-hour)) [\nplotxy ticks-hour 0 \n]"

MONITOR
1508
32
1617
77
mean queue time
customer-checkout-queue-time / customer-leaving-count
3
1
11

TEXTBOX
1254
13
1479
41
Agregeted statistics (customers)
11
0.0
1

TEXTBOX
670
424
852
452
Statistics per hour
11
0.0
1

MONITOR
1290
32
1399
77
customers
customer-leaving-count
17
1
11

SLIDER
395
790
529
823
number-of-sco-servers
number-of-sco-servers
0
8
6.0
1
1
NIL
HORIZONTAL

SWITCH
4
835
134
868
single-queue?
single-queue?
1
1
-1000

SLIDER
3
886
131
919
distance-in-queue
distance-in-queue
1
3
1.0
1
1
NIL
HORIZONTAL

SLIDER
130
887
264
920
distance-queue-server
distance-queue-server
1
3
3.0
1
1
NIL
HORIZONTAL

SLIDER
264
887
387
920
distance-server-server
distance-server-server
1
3
2.0
1
1
NIL
HORIZONTAL

SLIDER
395
887
524
920
distance-sco-sco-h
distance-sco-sco-h
1
5
4.0
1
1
NIL
HORIZONTAL

SLIDER
525
887
659
920
distance-sco-sco-v
distance-sco-sco-v
1
3
2.0
1
1
NIL
HORIZONTAL

TEXTBOX
4
868
154
886
other-parameters
11
0.0
1

SLIDER
3
563
132
596
max-customers
max-customers
0
10000
500.0
1
1
NIL
HORIZONTAL

MONITOR
1290
77
1400
122
customers
customer-leaving-count-sco
0
1
11

MONITOR
1290
120
1400
165
customers
( customer-leaving-count - customer-leaving-count-sco )
3
1
11

MONITOR
1508
77
1617
122
mean queue time
customer-leaving-queue-time-sco / customer-leaving-count-sco
3
1
11

TEXTBOX
1257
43
1278
62
all
11
0.0
1

TEXTBOX
1253
80
1295
115
self service
11
0.0
1

TEXTBOX
1254
132
1293
152
service
11
0.0
1

MONITOR
1400
32
1509
77
customers %
100 * (customer-leaving-count / customer-leaving-count)
0
1
11

MONITOR
1400
77
1508
122
customers %
100 * (customer-leaving-count-sco / customer-leaving-count)
1
1
11

MONITOR
1402
122
1510
167
customers %
100 * (( customer-leaving-count - customer-leaving-count-sco ) / customer-leaving-count)
1
1
11

CHOOSER
3
484
132
529
customer-arrival-proces
customer-arrival-proces
"HPP" "NHPP (POS)"
1

CHOOSER
130
484
260
529
customer-basket-payment
customer-basket-payment
"Poisson\\Binomial" "ECDF (POS)"
1

CHOOSER
395
484
531
529
cashier-arrival
cashier-arrival
"constant number" "workschedule (POS)"
1

SLIDER
532
484
660
517
cashier-max-line
cashier-max-line
1
5
2.0
1
1
NIL
HORIZONTAL

SLIDER
531
561
659
594
cashier-return-time
cashier-return-time
0
5
1.0
0.5
1
NIL
HORIZONTAL

SLIDER
531
522
660
555
cashier-min-line
cashier-min-line
0
5
1.0
1
1
NIL
HORIZONTAL

TEXTBOX
395
775
625
794
sco-servers (self-checkout) parameters
11
0.0
1

MONITOR
301
10
425
55
simulation end time
time:show end-time \"dd.MM.YYYY HH:mm:ss\"
17
1
11

MONITOR
1
10
126
55
simulation start time
time:show start-time \"dd.MM.YYYY HH:mm:ss\"
17
1
11

SLIDER
396
528
532
561
cashier-work-time
cashier-work-time
120
720
240.0
1
1
NIL
HORIZONTAL

PLOT
668
25
1238
145
customers arrived count
minuts
count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"all              " 1.0 0 -3844592 true "" "plotxy ticks-minute customer-arrival-count-minute"

PLOT
669
145
1238
265
cashiers count
minutes
count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"all              " 1.0 0 -8053223 true "" "plotxy ticks-minute count cashiers "
"working" 1.0 0 -15040220 true "" "plotxy ticks-minute count cashiers with [working?]"

TEXTBOX
669
10
893
29
Statistic per minute
11
0.0
1

MONITOR
1290
199
1401
244
total time
sum [ticks - time-start] of cashiers + cashier-working-length
0
1
11

SLIDER
396
427
660
460
simulation-start-day
simulation-start-day
0
20
0.0
0.2
1
NIL
HORIZONTAL

MONITOR
1510
199
1618
244
changeovers
cashier-break-count + sum [break-count] of cashiers
0
1
11

MONITOR
1618
33
1726
78
mean queue time (only customers in queues)
customer-checkout-queue-time / customer-leaving-waiting-count
3
1
11

MONITOR
1618
78
1729
123
mean queue time (only customers in queues)
customer-leaving-queue-time-sco / customer-leaving-waiting-count-sco
3
1
11

MONITOR
1617
122
1725
167
mean queue time (only customers in queues)
(customer-checkout-queue-time - customer-leaving-queue-time-sco) / (customer-leaving-waiting-count-server)
3
1
11

MONITOR
1509
122
1618
167
mean queue time
(customer-checkout-queue-time - customer-leaving-queue-time-sco) / (customer-leaving-count - customer-leaving-count-sco)
3
1
11

MONITOR
1726
34
1849
79
P(queue time > 5) %
100 * customer-leaving-waiting5-count / customer-leaving-count
3
1
11

PLOT
670
680
1239
800
P(queue time > 5) 
hours
%
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"all             " 1.0 0 -7500403 true "" "if ((ticks-minute / 60) = (ticks-hour + 1)) and (customer-leaving-count-hour != 0) [ plotxy ticks-hour 100 * ( customer-leaving-waiting5-count-hour / customer-leaving-count-hour ) ]\nif ((ticks-minute / 60) = (ticks-hour + 1)) and (customer-leaving-count-hour = 0) [ plotxy ticks-hour 0 ]"
"self-service" 1.0 0 -16777216 true "" "if ((ticks-minute / 60) = (ticks-hour + 1)) and (customer-leaving-count-sco-hour != 0) [ plotxy ticks-hour 100 *( customer-leaving-waiting5-count-sco-hour / customer-leaving-count-sco-hour ) ]\nif ((ticks-minute / 60) = (ticks-hour + 1)) and (customer-leaving-count-sco-hour = 0) [ plotxy ticks-hour 0 ]"
"service" 1.0 0 -14070903 true "" "if ((ticks-minute / 60) = (ticks-hour + 1)) and (customer-leaving-count-server-hour != 0) [ plotxy ticks-hour 100 * ( customer-leaving-waiting5-count-server-hour / customer-leaving-count-server-hour ) ]\nif ((ticks-minute / 60) = (ticks-hour + 1)) and (customer-leaving-count-server-hour = 0) [ plotxy ticks-hour 0 ]"

TEXTBOX
1255
184
1443
202
Agregeted statistic (cashiers)
11
0.0
1

TEXTBOX
1258
215
1273
234
all
11
0.0
1

MONITOR
1725
78
1848
123
P(queue time > 5) %
100 * customer-leaving-waiting5-count-sco / customer-leaving-count-sco
3
1
11

MONITOR
1725
123
1848
168
P(queue time > 5) %
100 * customer-leaving-waiting5-count-server / customer-leaving-count-server
3
1
11

MONITOR
1400
199
1512
244
total time on servers
(sum [ticks - time-start] of cashiers) - (sum [break-length] of cashiers) + cashier-effective-working-length
0
1
11

CHOOSER
134
790
260
835
server-service-time-model
server-service-time-model
"EXPONENTIAL" "Reg. model (POS)"
1

SLIDER
135
835
260
868
server-service-time-expected
server-service-time-expected
0
10
1.346
0.001
1
NIL
HORIZONTAL

CHOOSER
531
790
661
835
sco-server-service-time-model
sco-server-service-time-model
"EXPONENTIAL" "Reg. model (POS)"
1

SLIDER
531
835
661
868
sco-server-service-time-expected
sco-server-service-time-expected
0
10
2.853
0.001
1
NIL
HORIZONTAL

MONITOR
1289
365
1399
410
total time
sum [ticks - time-start] of servers
0
1
11

MONITOR
1400
365
1512
410
service time
(sum [ticks - time-start] of servers) - (sum [break-length] of servers) - (sum [ticks - time-break-start] of servers with [time-break-start > time-break-end ] )
0
1
11

MONITOR
1619
199
1727
244
total working time
(sum [ticks - time-start] of cashiers) - (sum [break-length] of cashiers) + cashier-effective-working-length + cashier-return-time * (cashier-break-count + sum [break-count] of cashiers)
0
1
11

TEXTBOX
1255
258
1405
276
Agregeted statistic (servers)
11
0.0
1

MONITOR
1510
365
1619
410
utilization %
100 * ((sum [ticks - time-start] of servers) - (sum [break-length] of servers) - (sum [ticks - time-break-start] of servers with [time-break-start > time-break-end ] )) / (sum [ticks - time-start] of servers)
1
1
11

MONITOR
1289
320
1401
365
total time
sum [ticks - time-start] of sco-servers
0
1
11

MONITOR
1400
320
1512
365
service time
(sum [ticks - time-start] of sco-servers) - (sum [break-length] of sco-servers) - (sum [ticks - time-break-start] of sco-servers with [time-break-start > time-break-end ] )
0
1
11

MONITOR
1511
320
1619
365
utilization %
100 *((sum [ticks - time-start] of sco-servers) - (sum [break-length] of sco-servers) - (sum [ticks - time-break-start] of sco-servers with [time-break-start > time-break-end ] )) / (sum [ticks - time-start] of sco-servers)
1
1
11

MONITOR
1725
199
1838
244
utilization %
100 * ((sum [ticks - time-start] of cashiers) - (sum [break-length] of cashiers) + cashier-effective-working-length + cashier-return-time * (cashier-break-count + sum [break-count] of cashiers))/ (sum [ticks - time-start] of cashiers + cashier-working-length)
1
1
11

MONITOR
1289
275
1402
320
total-time
(sum [ticks - time-start] of sco-servers) + (sum [ticks - time-start] of servers)
0
1
11

MONITOR
1400
275
1513
320
service time
((sum [ticks - time-start] of sco-servers) - (sum [break-length] of sco-servers) - (sum [ticks - time-break-start] of sco-servers with [time-break-start > time-break-end ] )) + ((sum [ticks - time-start] of servers) - (sum [break-length] of servers) - (sum [ticks - time-break-start] of servers with [time-break-start > time-break-end ] ))
0
1
11

MONITOR
1512
275
1619
320
utilization %
100 * (((sum [ticks - time-start] of sco-servers) - (sum [break-length] of sco-servers) - (sum [ticks - time-break-start] of sco-servers with [time-break-start > time-break-end ] )) + ((sum [ticks - time-start] of servers) - (sum [break-length] of servers) - (sum [ticks - time-break-start] of servers with [time-break-start > time-break-end ] ))) / ((sum [ticks - time-start] of sco-servers) + (sum [ticks - time-start] of servers))
1
1
11

TEXTBOX
1254
283
1288
307
all
11
0.0
1

TEXTBOX
1253
323
1297
356
self service
11
0.0
1

TEXTBOX
1253
377
1297
400
service
11
0.0
1

PLOT
668
264
1238
384
servers utilization %
minutes
%
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"all          " 1.0 0 -5987164 true "" "if (count sco-servers + count servers) != 0 [ plotxy ticks-minute 100 *(count servers with [customer-being-served != nobody] + count sco-servers with [customer-being-served != nobody]) / (count sco-servers + count servers)] "
"self-service" 1.0 0 -16777216 true "" "if (count sco-servers) != 0 [ plotxy ticks-minute 100 *(count sco-servers with [customer-being-served != nobody]) / (count sco-servers)] "
"service" 1.0 0 -14730904 true "" "if (count servers) != 0 [ plotxy ticks-minute 100 *(count servers with [customer-being-served != nobody]) / (count servers)] "

CHOOSER
261
564
392
609
customer-jockeying-strategy
customer-jockeying-strategy
0 1
1

SLIDER
260
530
392
563
customer-sco-item-thershold
customer-sco-item-thershold
0
500
100.0
1
1
NIL
HORIZONTAL

INPUTBOX
3
597
202
657
customer-arrival-input-file
C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\customer-arrival-input-file-store2.csv
1
0
String

INPUTBOX
1
652
202
712
customer-basket-payment-input-file
C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\customer-basket-payment-input-file-store2.csv
1
0
String

BUTTON
202
655
260
715
Chose file
setup-customer-basket-payment-file
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
202
596
259
654
Chose file
setup-customer-arrival-input-file
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
395
595
600
655
cashier-arrival-input-file
C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\cashier-arrival-input-file-store2.csv
1
0
String

BUTTON
600
594
660
653
Chose file
setup-cashier-arrival-input-file 
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
3
715
203
775
customer-output-directory
C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel_Output\\customers2\\
1
0
String

BUTTON
201
715
261
775
Chose dir
setup-customer-output-directory
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
394
711
604
771
cashier-output-directory
C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel_Output\\cashiers2\\
1
0
String

BUTTON
604
711
661
771
Chose dir
setup-cashier-output-directory
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
2
921
659
954
experiment
experiment
1
100
10.0
1
1
NIL
HORIZONTAL

CHOOSER
261
610
391
655
customer-jockeying-distance
customer-jockeying-distance
0 1 2 3 4 99
1

CHOOSER
261
656
391
701
customer-jockeying-threshold
customer-jockeying-threshold
1 2 3 4 5 99
0

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

cashier
false
0
Rectangle -7500403 true true 60 210 75 165
Circle -7500403 true true 30 180 30
Polygon -7500403 true true 45 180 60 165 75 165 75 180 60 180 45 195 45 180
Polygon -7500403 true true 45 210 60 225 75 225 75 210 60 210 45 195 45 210

cashier-checkout
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 60 150 75 180 135 105

checkout-sco
false
0
Rectangle -7500403 true true 75 285 240 300
Rectangle -7500403 true true 60 225 255 285
Rectangle -7500403 false true 180 105 225 120
Line -16777216 false 75 285 240 285
Rectangle -7500403 true true 135 165 209 222
Line -7500403 true 195 120 194 169

checkout-service
false
0
Rectangle -7500403 true true 15 285 285 300
Rectangle -7500403 true true 45 105 119 162
Rectangle -7500403 true true 0 165 300 285
Rectangle -7500403 false true 60 45 105 60
Line -16777216 false 0 285 300 285
Line -7500403 true 75 60 74 109

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

customer-card
false
0
Polygon -7500403 true true 150 90 165 105 270 105 285 90 285 45 285 30 270 15 165 15 150 30 150 90
Polygon -16777216 true false 150 30 285 30 285 45 150 45 150 30
Rectangle -7500403 true true 135 180 150 195
Circle -7500403 true true 165 270 30
Circle -7500403 true true 240 270 30
Rectangle -7500403 true true 67 79 112 94
Line -7500403 true 165 240 165 180
Line -7500403 true 180 255 180 180
Line -7500403 true 195 285 195 180
Line -7500403 true 210 285 210 180
Line -7500403 true 225 285 225 180
Line -7500403 true 240 285 240 180
Line -7500403 true 255 270 255 180
Line -7500403 true 270 255 270 180
Line -7500403 true 285 225 285 180
Line -7500403 true 150 195 300 195
Line -7500403 true 285 210 165 210
Line -7500403 true 165 225 285 225
Line -7500403 true 165 240 270 240
Line -7500403 true 180 255 270 255
Line -7500403 true 180 270 255 270
Line -7500403 true 150 180 180 285
Line -7500403 true 150 180 300 180
Line -7500403 true 255 285 300 180
Line -7500403 true 180 285 255 285
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Polygon -7500403 true true 45 90 0 150 15 180 75 105
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Circle -7500403 true true 50 5 80

customer-card-infected
false
0
Polygon -7500403 true true 150 90 165 105 270 105 285 90 285 45 285 30 270 15 165 15 150 30 150 90
Polygon -16777216 true false 150 30 285 30 285 45 150 45 150 30
Rectangle -7500403 true true 135 180 150 195
Circle -7500403 true true 165 270 30
Circle -7500403 true true 240 270 30
Rectangle -7500403 true true 67 79 112 94
Line -7500403 true 165 240 165 180
Line -7500403 true 180 255 180 180
Line -7500403 true 195 285 195 180
Line -7500403 true 210 285 210 180
Line -7500403 true 225 285 225 180
Line -7500403 true 240 285 240 180
Line -7500403 true 255 270 255 180
Line -7500403 true 270 255 270 180
Line -7500403 true 285 225 285 180
Line -7500403 true 150 195 300 195
Line -7500403 true 285 210 165 210
Line -7500403 true 165 225 285 225
Line -7500403 true 165 240 270 240
Line -7500403 true 180 255 270 255
Line -7500403 true 180 270 255 270
Line -7500403 true 150 180 180 285
Line -7500403 true 150 180 300 180
Line -7500403 true 255 285 300 180
Line -7500403 true 180 285 255 285
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Polygon -7500403 true true 45 90 0 150 15 180 75 105
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Circle -7500403 true true 50 5 80
Rectangle -2674135 true false 0 0 15 300
Rectangle -2674135 true false 15 0 285 15
Rectangle -2674135 true false 300 0 315 300
Rectangle -2674135 true false 15 285 300 300
Rectangle -2674135 true false 285 0 300 300

customer-cash
false
0
Rectangle -7500403 true true 150 15 285 105
Rectangle -16777216 false false 165 30 270 90
Circle -16777216 true false 195 45 30
Polygon -16777216 true false 210 75 195 90 225 90 210 75 210 60
Rectangle -7500403 true true 135 180 150 195
Circle -7500403 true true 165 270 30
Circle -7500403 true true 240 270 30
Line -7500403 true 150 195 300 195
Line -7500403 true 285 210 165 210
Line -7500403 true 165 225 285 225
Line -7500403 true 165 240 270 240
Line -7500403 true 180 255 270 255
Line -7500403 true 180 270 255 270
Line -7500403 true 165 240 165 180
Line -7500403 true 180 255 180 180
Line -7500403 true 195 285 195 180
Line -7500403 true 210 285 210 180
Line -7500403 true 225 285 225 180
Line -7500403 true 240 285 240 180
Line -7500403 true 255 270 255 180
Line -7500403 true 270 255 270 180
Line -7500403 true 285 225 285 180
Polygon -7500403 false true 240 285 195 285 180 285 150 180 300 180 255 285
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Polygon -7500403 true true 45 90 0 150 15 180 75 105
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Circle -7500403 true true 50 5 80
Rectangle -7500403 true true 67 79 112 94

customer-cash-infected
false
0
Rectangle -7500403 true true 150 15 285 105
Rectangle -16777216 false false 165 30 270 90
Circle -16777216 true false 195 45 30
Polygon -16777216 true false 210 75 195 90 225 90 210 75 210 60
Rectangle -7500403 true true 135 180 150 195
Circle -7500403 true true 165 270 30
Circle -7500403 true true 240 270 30
Line -7500403 true 150 195 300 195
Line -7500403 true 285 210 165 210
Line -7500403 true 165 225 285 225
Line -7500403 true 165 240 270 240
Line -7500403 true 180 255 270 255
Line -7500403 true 180 270 255 270
Line -7500403 true 165 240 165 180
Line -7500403 true 180 255 180 180
Line -7500403 true 195 285 195 180
Line -7500403 true 210 285 210 180
Line -7500403 true 225 285 225 180
Line -7500403 true 240 285 240 180
Line -7500403 true 255 270 255 180
Line -7500403 true 270 255 270 180
Line -7500403 true 285 225 285 180
Polygon -7500403 false true 240 285 195 285 180 285 150 180 300 180 255 285
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Polygon -7500403 true true 45 90 0 150 15 180 75 105
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Circle -7500403 true true 50 5 80
Rectangle -7500403 true true 67 79 112 94
Rectangle -2674135 true false 0 0 15 300
Rectangle -2674135 true false 15 285 300 300
Rectangle -2674135 true false 285 0 300 300
Rectangle -2674135 true false 0 0 315 15

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

server
false
0
Rectangle -7500403 false true 75 75 225 240
Rectangle -7500403 true true 30 0 75 150
Polygon -7500403 false true 75 150 75 150 75 150 30 150 15 165 15 225 30 240 75 240 75 150
Rectangle -7500403 true true 60 210 75 165
Rectangle -7500403 true true 60 165 75 225

server-sco
false
0
Rectangle -7500403 false true 75 75 225 240
Rectangle -7500403 true true 60 210 75 165
Rectangle -7500403 true true 15 105 90 150
Rectangle -7500403 true true 15 150 75 210
Polygon -16777216 true false 15 105 15 105 15 90
Polygon -16777216 false false 15 105 90 105 90 150 15 150 15 105
Rectangle -16777216 false false 15 150 75 210

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
NetLogo 6.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment no_jockey" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="server-service-time-expected">
      <value value="1.346"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-work-time">
      <value value="240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-servers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-distance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-max-line">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-min-line">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="server-service-time-model">
      <value value="&quot;Reg. model (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-proces">
      <value value="&quot;NHPP (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival">
      <value value="&quot;workschedule (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-queue-server">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cashiers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-sco-sco-v">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-mean-size">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-end-day">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-payment">
      <value value="&quot;ECDF (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-server-service-time-model">
      <value value="&quot;Reg. model (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-customers">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-cash-payment-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-server-server">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-payment-input-file">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\customer-basket-payment-input-file-store1.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-output-directory">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel_Output\\cashiers0\\&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-strategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-mean-rate">
      <value value="6.618"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="single-queue?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-in-queue">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-return-time">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-sco-item-thershold">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experiment">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-picking-queue-strategy">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-start-day">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-input-file">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\customer-arrival-input-file-store1.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-sco-servers">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival-input-file">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\cashier-arrival-input-file-store1.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-sco-sco-h">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-threshold">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-output-directory">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel_Output\\customers0\\&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-server-service-time-expected">
      <value value="2.853"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment no_jockey2" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="server-service-time-expected">
      <value value="1.346"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-work-time">
      <value value="240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-servers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-distance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-max-line">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-min-line">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="server-service-time-model">
      <value value="&quot;Reg. model (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-proces">
      <value value="&quot;NHPP (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival">
      <value value="&quot;workschedule (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-queue-server">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cashiers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-sco-sco-v">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-mean-size">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-end-day">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-payment">
      <value value="&quot;ECDF (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-server-service-time-model">
      <value value="&quot;Reg. model (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-customers">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-cash-payment-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-server-server">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-payment-input-file">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\customer-basket-payment-input-file-store1.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-output-directory">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel_Output\\cashiers0\\&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-strategy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-mean-rate">
      <value value="6.618"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="single-queue?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-in-queue">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-return-time">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-sco-item-thershold">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experiment">
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
      <value value="17"/>
      <value value="18"/>
      <value value="19"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-picking-queue-strategy">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-start-day">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-input-file">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\customer-arrival-input-file-store1.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-sco-servers">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival-input-file">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\cashier-arrival-input-file-store1.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-sco-sco-h">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-threshold">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-output-directory">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel_Output\\customers0\\&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-server-service-time-expected">
      <value value="2.853"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Store 1:  no jockey/jockey; 20 experiments" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="server-service-time-expected">
      <value value="1.346"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-work-time">
      <value value="240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-servers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-distance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-max-line">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-min-line">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="server-service-time-model">
      <value value="&quot;Reg. model (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-proces">
      <value value="&quot;NHPP (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival">
      <value value="&quot;workschedule (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-queue-server">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cashiers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-sco-sco-v">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-mean-size">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-end-day">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-payment">
      <value value="&quot;ECDF (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-server-service-time-model">
      <value value="&quot;Reg. model (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-customers">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-cash-payment-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-server-server">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-payment-input-file">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\customer-basket-payment-input-file-store1.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-output-directory">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel_Output\\cashiers1\\&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-strategy">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-mean-rate">
      <value value="6.618"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="single-queue?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-in-queue">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-return-time">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-sco-item-thershold">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experiment">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
      <value value="17"/>
      <value value="18"/>
      <value value="19"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-picking-queue-strategy">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-start-day">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-input-file">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\customer-arrival-input-file-store1.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-sco-servers">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival-input-file">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\cashier-arrival-input-file-store1.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-sco-sco-h">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-threshold">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-output-directory">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel_Output\\customers1\\&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-server-service-time-expected">
      <value value="2.853"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Store 3:  no jockey/jockey; 10 experiments" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="server-service-time-expected">
      <value value="1.346"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-work-time">
      <value value="240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-servers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-distance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-max-line">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-min-line">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="server-service-time-model">
      <value value="&quot;Reg. model (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-proces">
      <value value="&quot;NHPP (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival">
      <value value="&quot;workschedule (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-queue-server">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cashiers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-sco-sco-v">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-mean-size">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-end-day">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-payment">
      <value value="&quot;ECDF (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-server-service-time-model">
      <value value="&quot;Reg. model (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-customers">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-cash-payment-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-server-server">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-payment-input-file">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\customer-basket-payment-input-file-store3.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-output-directory">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel_Output\\cashiers3\\&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-strategy">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-mean-rate">
      <value value="6.618"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="single-queue?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-in-queue">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-return-time">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-sco-item-thershold">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experiment">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-picking-queue-strategy">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-start-day">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-input-file">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\customer-arrival-input-file-store3.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-sco-servers">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival-input-file">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\cashier-arrival-input-file-store3.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-sco-sco-h">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-threshold">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-output-directory">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel_Output\\customers3\\&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-server-service-time-expected">
      <value value="2.853"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Store 2:  no jockey/jockey; 10 experiments" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="server-service-time-expected">
      <value value="1.346"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-work-time">
      <value value="240"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-servers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-distance">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-max-line">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-min-line">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="server-service-time-model">
      <value value="&quot;Reg. model (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-proces">
      <value value="&quot;NHPP (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival">
      <value value="&quot;workschedule (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-queue-server">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cashiers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-sco-sco-v">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-mean-size">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-end-day">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-payment">
      <value value="&quot;ECDF (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-server-service-time-model">
      <value value="&quot;Reg. model (POS)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-customers">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-cash-payment-rate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-server-server">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-payment-input-file">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\customer-basket-payment-input-file-store2.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-output-directory">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel_Output\\cashiers2\\&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-strategy">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-mean-rate">
      <value value="6.618"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="single-queue?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-in-queue">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-return-time">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-sco-item-thershold">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experiment">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-picking-queue-strategy">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-start-day">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-input-file">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\customer-arrival-input-file-store2.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-sco-servers">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival-input-file">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel\\cashier-arrival-input-file-store2.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-sco-sco-h">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-threshold">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-output-directory">
      <value value="&quot;C:\\Doktorat\\Models\\Supermarket_Queue_Model\\NetLogo_SupermarketQueueModel_Output\\customers2\\&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-server-service-time-expected">
      <value value="2.853"/>
    </enumeratedValueSet>
  </experiment>
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
