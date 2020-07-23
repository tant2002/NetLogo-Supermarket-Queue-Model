extensions [time table Csv]

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
  open
  sys
  open-start
  open-end
  open-length
  service-start
  service-end
  service-length
]

sco-servers-own [
  customer-being-served
  next-completion-time
  expected-waiting-time
  open
]

cashiers-own [
  time-start
  time-end
  time-break-start
  time-break-end
  break-count
  break-length
  work-length
  working?
  backoffice?
  server-working-on
]

customers-own [
  basket-size

  ;parameter drawn
  payment-method
  sco-will
  picking-queue-strategy
  server-service-time
  sco-server-service-time

  ;decision of picking
  sco-zone-queue-picked?
  server-zone-queue-picked?
  server-picked

  ;information which
  sco
  server-queued-on
  server-served-on


  time-start-exposure
  time-stop-exposure
  exposure-time
  exposure-count

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

  infected?
]

globals [

  ticks-hour
  ticks-minute
  max-run-time
  start-time
  end-time
  current-time

  ;POS input files names
  customer-arrival-input-file
  customer-basket-payment-input-file
  cashier-arrival-input-file

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



  ;*server visulaisation variables
  server-queue-offset
  server-zone-xcor
  server-zone-ycor
  sco-zone-xcor
  sco-zone-ycor

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

]

to setup-customer-arrival-data-read
; this procedure set initial values necessary to further proces POS data for arrival process calibration

  ; set POS input data files
  set customer-arrival-input-file "customer-arrival-input-file-store1.csv"

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

  set customer-basket-payment-input-file "customer-basket-payment-input-file-store1.csv"

  ; read posiible values of basket size / payment method
  file-open customer-basket-payment-input-file
    set customer-basket-payment-values csv:from-row file-read-line
  file-close

  ;time series vairable with basket size and mehod of paymant
  set customer-basket-payment-input time:ts-load  customer-basket-payment-input-file

end


to setup-cashier-arrival
  set cashiers-backoffice []
  cashiers-create number-of-cashiers 99999999999
  ;print (cashier-arrival = "workschedule (POS)")
  if (cashier-arrival = "workschedule (POS)") [
    set cashier-arrival-input-file "cashier-arrival-input-file-store1.csv"
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
  ask patches [
    set floor? FALSE
  ]
  ask patches with [ pycor  >= ( (min-pycor ) + 1) ] [
    set floor? TRUE
  ]
  ask patches [recolor-patch]
end


 to setup-servers
  let server-ycor ( (min-pycor  ) + 1)
  set-default-shape servers "checkout-service"
  set server-queue-offset 5
  set server-zone-queue []
  if number-of-servers > 0 [
    let max-in-row floor ( abs max-pxcor ) / distance-server-server
    create-servers number-of-servers [
      ifelse ( who < max-in-row) [
        setxy (- ( who * distance-server-server ) ) server-ycor
      ][
        setxy (- (( who - max-in-row) * distance-server-server ) - 1 ) ( server-ycor + distance-server-server )
      ]

      set label ""
      set customer-being-served nobody
      set cashier-working-on nobody
      set next-completion-time 0
      set server-queue []
      set open false
      recolor-server
      set sys false
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
      let sco-server-xcor  distance-server-server + horizontal-interval * ((who - (count servers)) mod 2)
      setxy sco-server-xcor  sco-server-ycor
      set label ""
      set customer-being-served nobody
      set next-completion-time 0
      set open true
      recolor-sco-server
    ]
    set sco-zone-xcor ([xcor] of (min-one-of sco-servers [xcor])) + (([xcor] of (max-one-of sco-servers [xcor]))-([xcor] of (min-one-of sco-servers [xcor]))) / 2
    set sco-zone-ycor [ycor] of max-one-of sco-servers [ycor]
 ]
end



to setup
  clear-all
  reset-ticks
  setup-store
  setup-servers
  setup-sco-servers
  setup-customer-arrival-data-read
  setup-customer-basket-payment-data-read
  setup-cashier-arrival
  setup-times
  ;print customer-arrival-max-rate
end


to recolor-patch  ;; patch procedure

  set pcolor grey + 0.5
  if (floor?)  [ set pcolor grey ]
  if (contamination  > 1)  [ set pcolor blue]
  ;if (contamination  > 1)  [ set pcolor scale-color blue contamination 0.1 25 ]
end

to recolor-server  ;; server procedure
  if (not open) [ set color red]
  if (open)  [ set color green]
  ;if (customer-being-served != nobody)  [ set color yellow]
end

to recolor-sco-server  ;; sco-server procedure
  if (not open) [ set color red]
  if (open)  [ set color green]
  if (customer-being-served != nobody)  [ set color yellow]
end

to recolor-cashier  ;; sco-server procedure
  if (not working?) [ set color red]
  if (working?)  [ set color green]
end


to move-cashiers-backoffice   [b-xcor b-ycor]
;move all cashiers in backoffice to theier positions
foreach cashiers-backoffice [
    x ->  ask x
    [ ask x [
      setxy ( b-xcor - position x cashiers-backoffice ) b-ycor
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
  report (i_ticks + random-exponential (1 / customer-arrival-mean-rate))
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
      set t* (t* + random-exponential (1 / customer-arrival-max-rate))
    ;;;;;;;print word "t*: " t*
      set customer-arrival-min-time time:plus i_clock t* "minutes"
    ;;;;;;;print word "customer-arrival-min-time: " customer-arrival-min-time
      set u random-float 1
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
      customer-server-service-time-draw
      customer-sco-server-service-time-draw
      customer-update-satistic "arrival"
      setxy max-pxcor min-pycor
      set time-entered-model ticks
      set sco-zone-queue-picked? FALSE
      set server-zone-queue-picked? FALSE
      set server-picked nobody
      set server-queued-on nobody
      set server-served-on nobody
      set exposure-count 0

      set num-of-customers  count customers
      set num-of-articles  sum [basket-size] of customers
      set num-of-servers count (servers with [open])
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
  let x random-float 1
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

  set basket-size random-poisson ( customer-basket-mean-size )
  ifelse ( (random-float 1) < customer-cash-payment-rate )
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

to customer-sco-will-draw ;; customer procedure
 ; no logic is implemented - every customer can use SCO
 set sco-will 1
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
  let transaction-time (e ^ ( 2.121935 + 0.698402 * ln basket-size + random-normal 0 0.4379083) ) / 60
  let break-time (random-gamma 4.830613 (1 /  3.074209 )) / 60
  set server-service-time transaction-time + break-time
end

to customer-sco-server-service-time-draw-regression ; customer procedure
  ;set sco-server-service-time according to power regression model with parameters  estimated according to POS data
  let transaction-time (e ^ ( 3.122328 + 0.672461 * ln basket-size + random-normal 0 0.4907405) ) / 60
  let break-time (e ^ ( 3.51669 + 0.22300 * ln basket-size + random-normal 0 0.4820532) ) / 60
  set sco-server-service-time transaction-time + break-time
end

to customer-server-service-time-draw-exponetial ;;customer procedure
  ;set server-service-time according exponerial distribution with parameter  'server-service-time-expected'
  set server-service-time random-exponential ( server-service-time-expected )
end

to customer-sco-server-service-time-draw-exponetial
   ;set 'sco-server-service-time' according exponerial distribution with parameter  'server-service-time-expected'
  set sco-server-service-time random-exponential ( sco-server-service-time-expected )
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
    report (( count  customers with [member? self [server-queue] of myself ]) + 1 ) * server-service-time-expected
  ][
    report ( count customers with [member? self [server-queue] of myself ]) * server-service-time-expected
  ]
end

to-report sco-zone-waiting-time-expected-regression
;report expected waiting time on sco-zone.  if no SCO checkout is define it return max run time
  ifelse any? sco-servers with [open] [
    let next-sco-server  min-one-of sco-servers with [next-completion-time > ticks] [next-completion-time]
    ;select sco-server that next finish service
    ifelse next-sco-server != nobody [
      report (sum ( [ customer-sco-server-service-time-expected-regression ] of  customers with [member? self sco-zone-queue ]) / count sco-servers with [open] ) + ( [next-completion-time] of next-sco-server - ticks )
    ][
      report (sum ( [ customer-sco-server-service-time-expected-regression ] of  customers with [member? self sco-zone-queue ]) / count sco-servers with [open] )
    ]
  ][
    report max-run-time]
end

to-report sco-zone-waiting-time-expected-mean
;report expected waiting time on sco-zone according to assumed mean service time .  if no SCO checkout is define it return max run time
;reporer use external parameter 'sco-server-service-time-expected'
  ifelse any? sco-servers with [open] [
    report ((length sco-zone-queue) * sco-server-service-time-expected)  / count sco-servers with [open]
  ][
    report max-run-time]
end

to-report server-zone-waiting-time-expected-regression
;report expected waiting time on server-zone (single queue)
  let next-server  min-one-of servers with [open and next-completion-time > ticks] [next-completion-time]
  let waiting-time-expected time:difference-between current-time end-time  "minute"
  ;select sco-server that next finish service
  if any? servers with [open] [
    ifelse next-server != nobody  [
      set waiting-time-expected  (sum ( [ customer-server-service-time-expected-regression ] of  customers with [member? self server-zone-queue ]) / count servers with [open] ) + ( [next-completion-time] of next-server - ticks )
    ][
      set waiting-time-expected  (sum ( [ customer-server-service-time-expected-regression ] of  customers with [member? self server-zone-queue ]) / count servers with [open] )
    ]
  ]
  report  waiting-time-expected
end

to-report server-zone-waiting-time-expected-mean
;report expected waiting time on server-zone (single queue) ccording to assumed mean service time
;reporer use external parameter 'server-service-time-expected'

  ifelse any? servers with [open] [
    report ((length server-zone-queue) * server-service-time-expected)  / count servers with [open]
  ][
    report  max-run-time
  ]
end


to-report customer-server-service-time-expected-regression ;;customer reporter
   ;report expected waiting time on server of customer
   let transaction-time-expected (e ^ ( 2.121935 + 0.698402 * ln basket-size) ) / 60
   let break-time-expected (3.074209 * (4.830613)) / 60
   report transaction-time-expected + break-time-expected
End

to-report customer-sco-server-service-time-expected-regression ;;customer reporter
   ;report expected waiting time on sco-server of customer
   let transactiom-time-expected (e ^ ( 3.122328 + 0.672461 * ln basket-size) ) / 60
   let break-time-expected  (e ^ ( 3.51669 + 0.22300 * ln basket-size) ) / 60
   report transactiom-time-expected + break-time-expected
end



to customer-picking-queue-strategy-draw ;customer procedure
  ; In this  procedure individual picking strategy couuld be assign to each customer. However in our model it's assumed that each customer select the same strategy. Nothing is drawn.
  ; Strategy is assign to alla customers according to chosen parameter

  if (customer-picking-line-strategy = 0 )  [set picking-queue-strategy 0]
  if (customer-picking-line-strategy = 1 )  [set picking-queue-strategy 1]
  if (customer-picking-line-strategy = 2 )  [set picking-queue-strategy 2]
  if (customer-picking-line-strategy = 3 )  [set picking-queue-strategy 3]
  if (customer-picking-line-strategy = 4 )  [set picking-queue-strategy 4]
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
    ifelse (i != 0) or (number-of-sco-servers = 0) or (sco-will = 0) [
      set server-zone-queue-picked? TRUE
    ][
      set sco-zone-queue-picked? TRUE
    ]
  ][
    let available-servers (servers with [open])
    let number-of-queues ( count available-servers )
    let i random number-of-queues
    ifelse (i != 0) or (number-of-sco-servers = 0) or (sco-will = 0)
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

    if (length(server-zone-queue) <= length(sco-zone-queue)) or (not any? (sco-servers with [open]))[
      set server-zone-queue-picked? TRUE
      ]
    if (length(server-zone-queue) > length(sco-zone-queue)) or (not any? servers with [open] )[
      set sco-zone-queue-picked? TRUE]
  ][ ;if all servers have sparate queues
    let iserver-picked (min-one-of (servers with [open]) [length server-queue])
    ifelse iserver-picked != nobody [
      if (length([server-queue] of iserver-picked) <= length(sco-zone-queue)) or (not any? (sco-servers with [open]))[
        set server-picked iserver-picked]
      if (length([server-queue] of iserver-picked) > length(sco-zone-queue)) or (iserver-picked = nobody)[
        set sco-zone-queue-picked? TRUE]
    ][
      set sco-zone-queue-picked? TRUE]
  ]

  customer-checkout-queue-join
end


to customer-checkout-queue-pick-strategy2 ;customer procedure
  ;let checkout-queue-picked []
  ;let available-servers (servers with [open and not is-agent? customer-being-served])
  let iserver-picked (min-one-of (servers with [open])  [sum [basket-size] of turtle-set server-queue])

  let server-picked-item-number 0
  let sco-zone-item-number 0
  let server-zone-item-number 0

  if iserver-picked != nobody [set server-picked-item-number sum [basket-size] of turtle-set ( [server-queue] of iserver-picked) ]
  if not empty? sco-zone-queue [set  sco-zone-item-number sum [basket-size] of turtle-set ( sco-zone-queue )]
  if not empty? server-zone-queue [set  server-zone-item-number sum [basket-size] of turtle-set ( server-zone-queue )]

  ifelse single-queue? [  ;if single queue for all servers

    if (server-zone-item-number <= sco-zone-item-number) or (not any? (sco-servers with [open]))[
      set server-zone-queue-picked? TRUE
      ]
    if (server-zone-item-number > sco-zone-item-number) or (iserver-picked = nobody)[
      set sco-zone-queue-picked? TRUE]
  ][ ;if all servers have sparate queues

    if (server-picked-item-number <= sco-zone-item-number) or (not any? (sco-servers with [open]))[
      set server-picked iserver-picked]
    if (server-picked-item-number > sco-zone-item-number) or (iserver-picked = nobody)[
      set sco-zone-queue-picked? TRUE]
  ]
  customer-checkout-queue-join
end




;******pick line strategy  : the minimal expected time according to mean service time  **
to customer-checkout-queue-pick-strategy3
  let iserver-picked (min-one-of (servers with [open])  [server-waiting-time-expected-mean])

  let server-picked-waiting-time-expected 0
  if iserver-picked != nobody [set server-picked-waiting-time-expected  [server-waiting-time-expected-mean] of iserver-picked ]

  ifelse single-queue? [  ;if single queue for all servers

    if (server-zone-waiting-time-expected-mean <= sco-zone-waiting-time-expected-mean) or (not any? (sco-servers with [open]))[
      set server-zone-queue-picked? TRUE
      ]
    if (server-zone-waiting-time-expected-mean > sco-zone-waiting-time-expected-mean) or (iserver-picked = nobody)[
      set sco-zone-queue-picked? TRUE]
  ][ ;if all servers have sparate queues

    if (server-picked-waiting-time-expected <= sco-zone-waiting-time-expected-mean) or (not any? (sco-servers with [open]))[
      set server-picked iserver-picked]
    if (server-picked-waiting-time-expected > sco-zone-waiting-time-expected-mean) or (iserver-picked = nobody)[
      set sco-zone-queue-picked? TRUE]
  ]
  customer-checkout-queue-join
end


;******pick line strategy  : the minimal expected time according to number of items and expected time of transaction and break **
to customer-checkout-queue-pick-strategy4
  let iserver-picked (min-one-of (servers with [open])  [server-waiting-time-expected-regression])

  let server-picked-waiting-time-expected 0
  if iserver-picked != nobody [set server-picked-waiting-time-expected  [server-waiting-time-expected-regression] of iserver-picked ]

  ifelse single-queue? [  ;if single queue for all servers

    if (server-zone-waiting-time-expected-regression <= sco-zone-waiting-time-expected-regression) or (not any? (sco-servers with [open]))[
      set server-zone-queue-picked? TRUE
      ]
    if (server-zone-waiting-time-expected-regression > sco-zone-waiting-time-expected-regression) or (iserver-picked = nobody)[
      set sco-zone-queue-picked? TRUE]
  ][ ;if all servers have sparate queues

    if (server-picked-waiting-time-expected <= sco-zone-waiting-time-expected-regression) or (not any? (sco-servers with [open]))[
      set server-picked iserver-picked]
    if (server-picked-waiting-time-expected > sco-zone-waiting-time-expected-regression) or (iserver-picked = nobody)[
      set sco-zone-queue-picked? TRUE]
  ]
  customer-checkout-queue-join
end

to customer-checkout-queue-join ;;customer procedure
  if ( server-picked != nobody)[
    ifelse [open] of server-picked[
      set sco 0
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
      set sco 0
      set server-picked nobody
      set sco-zone-queue-picked? FALSE
      customer-checkout-queue-pick
    ]
  ]
  if (number-of-sco-servers != 0 and sco-zone-queue-picked? ) [
    set sco 1
    set sco-zone-queue-picked? FALSE
    set server-picked nobody
    set time-entered-queue ticks
    customer-move-in-queue (length sco-zone-queue) sco-zone-xcor sco-zone-ycor
    set sco-zone-queue (lput self sco-zone-queue)
    sco-servers-service-begin
  ]
  if (number-of-servers != 0 and server-zone-queue-picked? ) [
    set sco 0
    set sco-zone-queue-picked? FALSE
    set server-picked nobody
    set server-zone-queue-picked? FALSE
    set time-entered-queue ticks
    customer-move-in-queue (length server-zone-queue) server-zone-xcor server-zone-ycor
    set server-zone-queue (lput self server-zone-queue)
    servers-service-begin
  ]


end

to customer-model-leave ;;customer procedure
  set time-leaving-model ticks
  customer-update-satistic  "model-leave"
  die
end

to customer-exposure-check ;;customer procedure
 ;check if customer is on the contaminated patches. If so update statistic
  ;print exposure-count
  if (not infected?)[
    if (contamination > 0 and time-start-exposure < ticks and time-stop-exposure  < ticks)   [
      set time-start-exposure  ticks
      set time-stop-exposure max-run-time + 9999
      set exposure-count exposure-count + 1
    ]

    if (contamination = 0 and time-start-exposure > 0 and time-stop-exposure > ticks) [
      set exposure-time exposure-time + (ticks - time-start-exposure)
      set time-stop-exposure ticks
    ]
  ]
  if exposure-count > 1 [
  ]
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


    if sco = 0 [
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

    if sco = 1 [
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

    if exposure-time > 0 [
      set customer-leaving-exposed-count customer-leaving-exposed-count + 1
      set customer-leaving-exposed-count-hour customer-leaving-exposed-count-hour + 1
      set customer-leaving-exposure-time customer-leaving-exposure-time + exposure-time
      set customer-leaving-exposure-time-hour customer-leaving-exposure-time-hour + exposure-time
      set customer-leaving-exposure-count customer-leaving-exposure-count +  exposure-count
      set customer-leaving-exposure-count-hour customer-leaving-exposure-count-hour + exposure-count
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
      if next-customer != nobody [
        set customer-being-served next-customer
        set next-completion-time (ticks + [server-service-time] of next-customer )
        ask next-customer [
          set time-entered-service ticks
          set server-queued-on nobody
          set server-served-on myself
          set bs basket-size
          customer-move-to-server myself
        ]
        recolor-server
      ]
    ]
  ]
end

to servers-service-begin
  let available-server  one-of servers with [open and not is-agent? (customer-being-served )]
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
    ask cashier-working-on [
      cashier-server-close
      if cashier-server-leave-check? [cashier-server-leave]
    ]
    set next-completion-time 0
    recolor-server
  server-service-begin
  ]
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
      recolor-sco-server]
    move-queue-forward sco-zone-queue sco-zone-xcor sco-zone-ycor 0
    ]
end

to sco-server-complete-service [sco-server-id]
  ask (sco-server sco-server-id) [
    ask customer-being-served [ customer-model-leave ]
    set next-completion-time 0
    set label ""
    recolor-sco-server]
   sco-servers-service-begin
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
     set time-break-end ticks
     set break-count 0
     set break-length 0
     set shape "cashier-checkout"
     set working? false
     set backoffice? false
     recolor-cashier
     cashier-backoffice-go    ]
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
  move-cashiers-backoffice  max-pxcor min-pycor
end

to-report cashier-server-enter-time-schedule

  ifelse any? (servers with [open])
  [
    ifelse single-queue?
    [
      ifelse ((length server-zone-queue + length sco-zone-queue) / (count  (servers with [open]) + 1)  > cashier-max-line)
      [
      report ticks + cashier-return-time ]
      [report ticks ]
    ][
      ifelse ((sum ([length(server-queue)] of (servers with [open])) + length(sco-zone-queue)) / (count  (servers with [open]) + 1)  > cashier-max-line)
      [report ticks + cashier-return-time ]
      [report ticks ]]
  ]
  [
    report ticks + cashier-return-time
  ]

end

to cashier-server-enter ;cashier procedure
  let server-to-work nobody
  let available-servers []
  ;First choice: server with cashiers that alredy closed checkout
  set available-servers (servers with [not open and is-agent? cashier-working-on])
  ;Second choice servers with cashiers that should end of work till now
  if not (any? available-servers)[
    set available-servers (servers with [open and is-agent? cashier-working-on and [time-end] of cashier-working-on <= (ticks + 1) ])
  ]
  ;Third choice closed checkout w/o cashier
  if not (any? available-servers) [
    set available-servers (servers with [not open and not is-agent? cashier-working-on])
  ]

  set server-to-work one-of available-servers
  if server-to-work != nobody [
    ask server-to-work [
      if cashier-working-on != nobody [ ask cashier-working-on [cashier-server-leave] ]
      set cashier-working-on myself
      set open true
      recolor-server
    ]
    set xcor [xcor] of server-to-work
    set ycor [ycor] of server-to-work
    set server-working-on server-to-work
    set working? true
    set time-break-end ticks
    set break-length ( break-length + time-break-end - time-break-start )
    if (time-break-end > time-break-start)[
      set break-count  break-count + 1 ]
    cashier-update-satistic "server-enter"
    recolor-cashier
    set cashiers-backoffice  remove self cashiers-backoffice
    move-cashiers-backoffice  max-pxcor min-pycor
  ]



end

to cashiers-server-enter
;chose on of cashier in backoffice to go server
  if ( not empty? cashiers-backoffice ) [
    ask first cashiers-backoffice [cashier-server-enter]
  ]

end

to-report cashier-server-close-check? ;cashier procedure
 ; check if checkout can be closed:  Checkout can by closed in two cases working time of cashier is end or avarage queue is shortest than threshold
 let check? false
  if number-of-sco-servers != 0 or (count servers with [open]) > 1 [
    ifelse time-end < ticks [
      set check? true
    ][
      if ( single-queue? and length server-zone-queue < cashier-min-line ) or
      (not single-queue? and ((sum ([length(server-queue)] of (servers with [open])) + length(sco-zone-queue)) / (count  (servers with [open]) + (ifelse-value (number-of-sco-servers > 0) [1] [0] )) < cashier-min-line)) [
        set check? true
      ]
    ]
  ]
  report check?
end

to cashier-server-close ;cashier procedure
  ;check if checkout can be close. if so close it
  if cashier-server-close-check?  [
    ask server-working-on [
      set open false
      recolor-server
    ]
  ]
end

to-report cashier-server-leave-check? ;cashier procedure
;this reporter check if cashier can leave checkout
 let check? false
  if not ( [open] of server-working-on ) and ( [customer-being-served] of server-working-on ) = nobody  [
    if ( single-queue? and ( empty? server-zone-queue or ( not empty? server-zone-queue and any? servers with [open] ))) [
      set check? true
    ]
    if (not single-queue? and empty? [server-queue] of server-working-on ) [
      set check? true ]
  ]
report check?
end


to cashier-server-leave ;cashier procedure
  set time-break-start ticks
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
     set cashiers-backoffice remove self cashiers-backoffice
     move-cashiers-backoffice  max-pxcor min-pycor
     set break-length ( break-length + time-break-end - time-break-start )
     if (time-break-end > time-break-start)[
      set break-count  break-count + 1
    ]
    cashier-update-satistic "model-leave"
    die
  ]
   ;if cashier-leaving-data-save-time < ticks
   ;[ time:ts-write cashier-leaving-data-file OutputPath cashier-leaving-data-file-output
   ;  set cashier-leaving-data-save-time (cashier-leaving-data-save-time + 300)]
end

to cashiers-model-leave
  ;ask all cashiers that not woring and out of schdule to go home
  ask cashiers with [not working? and time-end < ticks] [
    cashier-model-leave
  ]

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

to end-run-complete

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


to go
  ifelse (ticks < max-run-time) [
    cashiers-model-leave
    ;schedule of events done regulary i.e every second or hour
    ;let next-minute next-minute-schedule
    if next-minute <= ticks [ set next-minute next-minute-schedule ]
    ;print next-minute
    if next-hour <= ticks [ set next-hour next-hour-schedule ]
    ;print word ticks-hour word " - " ticks-minute

    ;schedule of events done discret
    if customer-arrival-next-time <= ticks  [ set customer-arrival-next-time (customer-arrival-time-schedule)]

    if cashier-arrival-next-time <= ticks [ set cashier-arrival-next-time  (cashier-arrival-time-schedule)]

    if cashier-server-enter-next-time <= ticks [ set cashier-server-enter-next-time (cashier-server-enter-time-schedule)]
   ; if cashier-server-leave-next-time <= ticks [set cashier-leave-next-time
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



    ;**** secondly set to list events done discretly
    if (customer-arrival-next-time > ticks)[
      set event-queue (fput (list customer-arrival-next-time "customer-store-arrive") event-queue)]

    if (cashier-arrival-next-time > ticks)[
      set event-queue (fput (list cashier-arrival-next-time "cashiers-store-arrive") event-queue)]

    if (cashier-server-enter-next-time > ticks)[
      set event-queue (fput (list cashier-server-enter-next-time "cashiers-server-enter") event-queue)]


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
0
56
663
385
-1
-1
15.244
1
9
1
1
1
0
1
1
1
-21
21
-10
10
0
0
1
ticks
50.0

SLIDER
3
575
133
608
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
2
403
57
436
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
60
403
115
436
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
118
403
173
436
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
5
387
155
405
controls
11
0.0
1

TEXTBOX
5
561
155
579
servers (checkout) parameters
11
0.0
1

SLIDER
130
528
260
561
customer-cash-payment-rate
customer-cash-payment-rate
0
1
0.3
0.1
1
NIL
HORIZONTAL

CHOOSER
258
452
389
497
customer-picking-line-strategy
customer-picking-line-strategy
0 1 2 3 4
3

TEXTBOX
4
435
154
453
customers parameters
11
0.0
1

TEXTBOX
397
437
547
455
cashiers parameters
11
0.0
1

SLIDER
393
530
529
563
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
3
495
132
528
customer-arrival-mean-rate
customer-arrival-mean-rate
0
25
8.0
0.001
1
NIL
HORIZONTAL

SLIDER
130
495
260
528
customer-basket-mean-size
customer-basket-mean-size
0
100
21.0
1
1
NIL
HORIZONTAL

SLIDER
396
404
659
437
simulation-end-day
simulation-end-day
simulation-start-day
20
19.0
1
1
NIL
HORIZONTAL

PLOT
669
162
1238
282
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
669
282
1238
402
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
922
544
1031
589
mean queue time
customer-checkout-queue-time / customer-leaving-count
3
1
11

TEXTBOX
669
525
894
553
Agregeted statistics (customers)
11
0.0
1

TEXTBOX
669
147
851
175
Statistics per hour (customers)
11
0.0
1

MONITOR
705
544
814
589
customers
customer-leaving-count
17
1
11

SLIDER
394
579
528
612
number-of-sco-servers
number-of-sco-servers
0
8
1.0
1
1
NIL
HORIZONTAL

SWITCH
3
619
133
652
single-queue?
single-queue?
1
1
-1000

SLIDER
3
670
131
703
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
131
671
265
704
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
265
671
388
704
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
3
703
132
736
distance-sco-sco-h
distance-sco-sco-h
1
3
3.0
1
1
NIL
HORIZONTAL

SLIDER
132
704
266
737
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
5
652
155
670
other-parameters
11
0.0
1

SLIDER
3
528
132
561
max-customers
max-customers
0
100
96.0
1
1
NIL
HORIZONTAL

MONITOR
705
589
815
634
customers
customer-leaving-count-sco
0
1
11

MONITOR
705
633
815
678
customers
( customer-leaving-count - customer-leaving-count-sco )
3
1
11

MONITOR
923
589
1032
634
mean queue time
customer-leaving-queue-time-sco / customer-leaving-count-sco
3
1
11

TEXTBOX
671
555
692
574
all
11
0.0
1

TEXTBOX
669
595
704
629
self service
11
0.0
1

TEXTBOX
669
644
708
664
service
11
0.0
1

MONITOR
815
544
924
589
customers %
100 * (customer-leaving-count / customer-leaving-count)
0
1
11

MONITOR
815
589
923
634
customers %
100 * (customer-leaving-count-sco / customer-leaving-count)
1
1
11

MONITOR
816
634
924
679
customers %
100 * (( customer-leaving-count - customer-leaving-count-sco ) / customer-leaving-count)
1
1
11

CHOOSER
2
452
131
497
customer-arrival-proces
customer-arrival-proces
"HPP" "NHPP (POS)"
1

CHOOSER
130
452
260
497
customer-basket-payment
customer-basket-payment
"Poisson\\Binomial" "ECDF (POS)"
1

CHOOSER
394
452
530
497
cashier-arrival
cashier-arrival
"constant number" "workschedule (POS)"
1

SLIDER
530
452
658
485
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
530
531
660
564
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
530
497
659
530
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
564
625
583
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
394
498
530
531
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
"all              " 1.0 0 -16777216 true "" "plotxy ticks-minute customer-arrival-count-minute"

PLOT
1241
24
1810
144
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
Statistic per minute (customers)
11
0.0
1

MONITOR
1294
545
1403
590
total time in work
sum [ticks - time-start] of cashiers + cashier-working-length
0
1
11

SLIDER
177
403
392
436
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
1514
545
1622
590
changeovers
cashier-break-count + sum [break-count] of cashiers
0
1
11

MONITOR
1032
545
1140
590
mean queue time (only customers in queues)
customer-checkout-queue-time / customer-leaving-waiting-count
3
1
11

MONITOR
1033
590
1144
635
mean queue time (only customers in queues)
customer-leaving-queue-time-sco / customer-leaving-waiting-count-sco
3
1
11

MONITOR
1031
634
1139
679
mean queue time (only customers in queues)
(customer-checkout-queue-time - customer-leaving-queue-time-sco) / (customer-leaving-waiting-count-server)
3
1
11

MONITOR
924
634
1033
679
mean queue time
(customer-checkout-queue-time - customer-leaving-queue-time-sco) / (customer-leaving-count - customer-leaving-count-sco)
3
1
11

MONITOR
1623
545
1737
590
total working time
(sum [ticks - time-start] of cashiers) - (sum [break-length] of cashiers) + cashier-effective-working-length + cashier-return-time * (cashier-break-count + sum [break-count] of cashiers)
0
1
11

MONITOR
1138
545
1252
590
P(queue time > 5) 
customer-leaving-waiting5-count / customer-leaving-count
3
1
11

PLOT
670
402
1239
522
P(queue time > 5)
hours
probability
0.0
10.0
0.0
0.005
true
true
"" ""
PENS
"all             " 1.0 0 -7500403 true "" "if ((ticks-minute / 60) = (ticks-hour + 1)) and (customer-leaving-count-hour != 0) [ plotxy ticks-hour ( customer-leaving-waiting5-count-hour / customer-leaving-count-hour ) ]\nif ((ticks-minute / 60) = (ticks-hour + 1)) and (customer-leaving-count-hour = 0) [ plotxy ticks-hour 0 ]"
"self-service" 1.0 0 -16777216 true "" "if ((ticks-minute / 60) = (ticks-hour + 1)) and (customer-leaving-count-sco-hour != 0) [ plotxy ticks-hour ( customer-leaving-waiting5-count-sco-hour / customer-leaving-count-sco-hour ) ]\nif ((ticks-minute / 60) = (ticks-hour + 1)) and (customer-leaving-count-sco-hour = 0) [ plotxy ticks-hour 0 ]"
"service" 1.0 0 -14070903 true "" "if ((ticks-minute / 60) = (ticks-hour + 1)) and (customer-leaving-count-server-hour != 0) [ plotxy ticks-hour ( customer-leaving-waiting5-count-hour / customer-leaving-count-server-hour ) ]\nif ((ticks-minute / 60) = (ticks-hour + 1)) and (customer-leaving-count-server-hour = 0) [ plotxy ticks-hour 0 ]"

TEXTBOX
1247
523
1435
546
Agregeted statistic (cashiers)
11
0.0
1

TEXTBOX
1249
9
1437
32
Statistic per minute (cashiers)
11
0.0
1

TEXTBOX
1270
557
1285
580
all
11
0.0
1

MONITOR
1140
590
1252
635
P(queue time > 5)
customer-leaving-waiting5-count-sco / customer-leaving-count-sco
3
1
11

MONITOR
1140
635
1252
680
P(queue time > 5)
customer-leaving-waiting5-count-server / customer-leaving-count-server
3
1
11

MONITOR
1404
545
1514
590
effective-working-time
(sum [ticks - time-start] of cashiers) - (sum [break-length] of cashiers) + cashier-effective-working-length
0
1
11

CHOOSER
133
575
259
620
server-service-time-model
server-service-time-model
"EXPONENTIAL" "Reg. model (POS)"
1

SLIDER
134
620
259
653
server-service-time-expected
server-service-time-expected
0
10
0.111
0.001
1
NIL
HORIZONTAL

CHOOSER
531
579
661
624
sco-server-service-time-model
sco-server-service-time-model
"EXPONENTIAL" "Reg. model (POS)"
0

SLIDER
531
625
661
658
sco-server-service-time-expected
sco-server-service-time-expected
0
10
0.111
0.001
1
NIL
HORIZONTAL

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
