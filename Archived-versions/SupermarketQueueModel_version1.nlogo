;Simulation Queuing Model with Multiple Queues and Multiple Parallel Servers
;In this version we introduce self checkot servers SCO_servers
;Version 14: Implementation of jockeing

extensions [time table Csv]

breed [cashiers cashier]
breed [customers customer]
breed [servers server]
breed [sco-servers sco-server]


; Each customer records the time entering the system, and the time entering
; service, so that average time-in-queue/time-in-system statistics can be
; computed.

customers-own [
  basket-size
  payment-method
  sco-will
  time-entered-queue
  time-entered-service
  time-leaving-model
  expected-waiting-time
  expected-service-time
  sco-join-to
  sco
  num-of-servers
  num-of-sco
  num-of-customers
  num-of-articles
  num-of-jockeying
  server-join-to
  next-jockey-time
  server-queued-on
  server-served-on]

cashiers-own [
  time-start
  time-end
  time-break-start
  time-break-end
  time-break-count
  time-break-length
  working
  server-working-on
]

; Each server records the customer agent being served, and the scheduled
; completion of that service. Since servers are homogenous, individual
; utilization statistics aren't kept.

servers-own [
  customer-being-served
  cashier-working-on
  next-completion-time
  server-queue
  expected-waiting-time
  open
  sys
]

sco-servers-own [
  customer-being-served
  next-completion-time
  expected-waiting-time
  open
]

globals [
  ;**********************************************************
  ;************Global variable reffering to time*************
  ;**********************************************************
    logo_clock
    start_time
    end_time
    max-run-time
  ;**********************************************************
  ;**********Customer: visualisation of customer variables***
  ;**********************************************************
    customer-visual-xinterval
    customer-visual-yinterval
    customers-visual-per-row
  ;**********************************************************
  ;**********Customer: Arrival process global variables******
  ;**********************************************************
    customer-arrival-count
    customer-arrival-next-time
    customer-arrival-max-rate  ;Dashed Lambda
    customer-arrival-inter-rate
    customer-arrival-mean-rate
    customer-arrival-lambda
    customer-arrival-file
    customers-arrival-per-min
    customer-arrival-data-file
    customer-arrival-data-save-time
  ;**********************************************************
  ;**********Customer: Jockeying proces global variables*****
  ;**********************************************************

  ;**********************************************************
  ;***Customer: Basket size/Method of payment dice global var
  ;**********************************************************
    customer-basket-payment-file
    customer-basket-payment-distribution
    customer-basket-payment-distribution-x
  ;**********************************************************
  ;***Customer: Picking line process global variables********
  ;**********************************************************
  customer-scowillingness-file
  ;**********************************************************
  ;*****Customer: Leaving process****************************
  ;**********************************************************
  customer-leaving-data-file
  customer-leaving-data-save-time

  ;**********************************************************
  ;*********Cashier: Arrival proces global variables*********
  ;**********************************************************
    cashier-arrival-schedule-file
    cashier-arrival-next-time
    cashier-stop-next-time

  ;**********************************************************
  ;**********************************************************
  ;**********Cashier: enter server proces
    cashier-server-enter-next-time

   ;**********************************************************
  ;*****Cashier: Leaving process****************************
  ;**********************************************************
  cashier-leaving-data-file
  cashier-leaving-data-save-time

  number-of-cashier100
  number-of-cashier075
  number-of-cashier050
  ;**********************************************************
  ;*******Server: Global variables***************************
  ;**********************************************************
  server-queus-lengths
  server-zone-height
  server-zone-width
  server-ycor
  queue-server-offset
  ;**********************************************************
  ;*******SCO: Global variables******************************
  sco-queue
  sco-zone-width
  sco-zone-xcor
  sco-zone-ycor
  sco-expected-waiting-time
  ;**********************************************************
  ; Statistics for average load/usage of queue and servers
  ;*********************************************************
  mean-service-time
  mean-sco-service-time
  stats-start-time
  total-customer-queue-time
  total-customer-service-time
  total-time-in-queue
  total-time-in-system
  total-queue-throughput
  total-system-throughput
  sim
  str]

to-report InputPath [file]
  report word "../Netlogo_Input/" file
end

to-report OutputPath [file]
  report word "../Netlogo_Output/"  file
end

to setup
  clear-all
  reset-ticks
  setup-globals
  setup-servers
  setup-sco-servers
end

;**********************************************************************************************************************************************************
;******************************************Setup global variables******************************************************************************************
;**********************************************************************************************************************************************************
to setup-globals
 ;************************************************************************************************
 ;***********Customer:  visualisation global variable setup***************************************
 ;************************************************************************************************
  set customer-visual-xinterval 0.5
  set customer-visual-yinterval 1
  set customers-visual-per-row (1 + (world-width - 1) / customer-visual-xinterval)
  set-default-shape customers "person"
  set customer-arrival-file-input word store-no "_customers_input.csv"
  set customer-basket-payment-file-input word store-no "_basket_size_input.csv"
  set cashier-arrival-schedule-file-input word store-no "_cashiers_input.csv"
  set customer-leaving-data-file-output word store-no word "_transaction_output_" word customer-picking-line-strategy word simulation-no ".csv"
  set customer-arrival-data-file-output word store-no word "_customer_arrival_output_" word customer-picking-line-strategy word simulation-no ".csv"
  set cashier-leaving-data-file-output word store-no word "_cashier_output_" word customer-picking-line-strategy word simulation-no ".csv"

 ;************************************************************************************************


  ;************************************************************************************************
 ;***********Customer:  Arrival process glopbal variables setup***********************************
 ;************************************************************************************************
  set customer-arrival-next-time 0
  set customer-arrival-count 0

  if customer-arrival-file-input != ""[
    set customer-arrival-file time:ts-load  InputPath customer-arrival-file-input
    file-open InputPath customer-arrival-file-input
    let row csv:from-row file-read-line
    set row csv:from-row file-read-line
    set customer-arrival-max-rate item 1 row
    while [ not file-at-end? ] [
      set row csv:from-row file-read-line
      if item 1 row > customer-arrival-max-rate  [  set customer-arrival-max-rate item 1 row ]]
    file-close
    set customer-arrival-max-rate precision ( customer-arrival-max-rate / 60 ) 2
      ;;;;;;print word "customer-arrival--max-rate: " customer-arrival-max-rate
    ;************************************************
    ]

 set customer-arrival-data-file time:ts-create ["Customers" "Lambda"]
 set customer-arrival-data-save-time 0
 ;************************************************************************************************
 ;***********Customer: Basket/ methof pf payment dice process global variables********************
 ;************************************************************************************************
 if customer-basket-payment-file-input != ""
   [
    file-open InputPath customer-basket-payment-file-input
    set customer-basket-payment-distribution-x csv:from-row file-read-line
    ;;;;;;print word "customer-basket-payment-distribution-x :" customer-basket-payment-distribution-x
    file-close
    set customer-basket-payment-file time:ts-load InputPath customer-basket-payment-file-input
   ]
 ;************************************************************************************************
 ;**********Customer: Picking line global variables***********************************************
 ;************************************************************************************************

 if customer-scowillingness-file-input != "" [
    file-open InputPath customer-scowillingness-file-input
    set customer-scowillingness-file csv:from-file InputPath customer-scowillingness-file-input
    file-close
 ]
 ;************************************************************************************************
 ;**********Customer: Leaving process*************************************************************

  ifelse not file-exists? OutputPath customer-leaving-data-file-output [
    set customer-leaving-data-file time:ts-create ["time-leaving-model" "customer-picking-line-strategy" "basket-size" "payment-method" "sco-will"
                                                   "time-entered-queue" "time-entered-service" "totaltime" "trantime" "queuetime"
                                                   "sco" "num-of-servers" "num-of-sco" "num-of-customers" "num-of-articles" "expected-waiting-time" "num-of-jockeying"]
    ]
    [
    set customer-leaving-data-file time:ts-load OutputPath customer-leaving-data-file-output
    ]
  set customer-leaving-data-save-time 0
 ;************************************************************************************************
 ;************Cashier: Arrival process setup globac variables*************************************
 ;************************************************************************************************
 if cashier-arrival-schedule-file-input != "" [
    set cashier-arrival-schedule-file time:ts-load InputPath cashier-arrival-schedule-file-input
    set  cashier-arrival-next-time 0
  ]
 ;************************************************************************************************
 ;************Cashier: enter server proces global*************************************************
    set cashier-server-enter-next-time 0

 ;*************************************************************************************************
 ;************Cashier: Leaving process*************************************************************

  ifelse not file-exists? OutputPath cashier-leaving-data-file-output [
    set cashier-leaving-data-file (list (list "WorkstationGroupID" "WorkstationID" "TranID" "BeginDateTime" "EndDateTime" "OperatorID" "TranTime" "TranTime2" "WeekDay" "Items"))
    ]
    [
    set cashier-leaving-data-file csv:from-file OutputPath cashier-leaving-data-file-output
    ]
  set cashier-leaving-data-save-time 0


 ;************************************************************************************************
 ;*****************Model: global time variable*****************************************************
 ;************************************************************************************************
   set logo_clock time:create "0001-01-01 00:00:00"
   set start_time first time:ts-get customer-arrival-file  (time:create "0001-01-01 00:00:00") "all"
   let start_time1 first time:ts-get cashier-arrival-schedule-file  (time:create "0001-01-01 00:00:00") "all"
   set start_time time:plus start_time -1.0 "minutes"
   set start_time1 time:plus start_time1 -1.0 "minutes"
  ;;;;;;print word "st: "start_time
  ;;;;;;print word "st1: "start_time1


  if  time:is-before start_time1 start_time [set start_time start_time1 ]
   set end_time first time:ts-get customer-arrival-file  (time:create "9999-12-31 00:00:00") "all"
   set logo_clock time:anchor-to-ticks start_time 1 "minute"
   set max-run-time time:difference-between start_time end_time  "minute"
   reset-stats
end

to setup-servers
  let horizontal-interval 0
  set server-queus-lengths []
  set-default-shape servers "server"
  set server-zone-height world-height / 4
  set server-ycor (min-pycor + 1) + (server-zone-height / 2)
  set queue-server-offset 1.5

  if (number-of-servers <= 2) [set server-zone-width world-width / 2]
  if (number-of-servers > 2) and (number-of-servers <= 10) [set server-zone-width world-width * (number-of-servers - 2) / number-of-servers]
  if (number-of-servers > 10) [set server-zone-width world-width * 0.8]
  ifelse ( number-of-servers < 11) [set horizontal-interval (server-zone-width / number-of-servers)]
                                   [set horizontal-interval ((server-zone-width - 1)  / (number-of-servers / 2))]

  create-servers number-of-servers [
    ifelse (number-of-servers < 11) [setxy (min-pxcor + 0.3 * horizontal-interval + (who * horizontal-interval )) server-ycor]
       [
       ifelse ((who + 1) <= round(number-of-servers / 2))
          [setxy (min-pxcor + 0.3 * horizontal-interval + (who * (horizontal-interval))) server-ycor]
          [setxy (min-pxcor + 0.5 * horizontal-interval + ((who - round (number-of-servers / 2)) * (horizontal-interval) )) (server-ycor - 2  )]
       ]
    set size 2.75
    set label ""
    set customer-being-served nobody
    set cashier-working-on nobody
    set next-completion-time 0
    set server-queue []
    set open false
    set color red
    set sys false
   ]
end

to setup-sco-servers
  set sco-queue []
  set-default-shape sco-servers "server-sco"
  let horizontal-interval 4
  let vertical-interval 2
  ifelse number-of-sco-servers > 0 [
    create-sco-servers number-of-sco-servers [
      set color green
      let sco-server-ycor ((min-pycor + 1) + vertical-interval * ( int ((who - (count servers)) / 2)))

      let sco-server-xcor  (min-pxcor + server-zone-width) + horizontal-interval * ((who - (count servers)) mod 2)

      setxy sco-server-xcor  sco-server-ycor
      set size 2
      set label ""
      set customer-being-served nobody
      set next-completion-time 0
      set open true
    ]
    set sco-zone-xcor ([xcor] of (min-one-of sco-servers [xcor])) + (([xcor] of (max-one-of sco-servers [xcor]))-([xcor] of (min-one-of sco-servers [xcor]))) / 2
    set sco-zone-ycor ([ycor] of (min-one-of sco-servers [ycor])) + (([ycor] of (max-one-of sco-servers [ycor]))-([ycor] of (min-one-of sco-servers [ycor]))) / 2
 ][
  create-servers 1 [
    set sys TRUE
    let sco-server-ycor ((min-pycor + 2) + vertical-interval * ( int ((who + 2 - (count servers) ) / 2)))
    let sco-server-xcor  (min-pxcor + server-zone-width) + horizontal-interval * ((who - (count servers)) mod 2)
    ;;;;;print word "sco-zone-xcor " sco-zone-xcor
    ;;;;;print word "sco-zone-ycor " sco-zone-ycor
    ;;;;;print word "count servers: " count servers

    setxy  sco-server-xcor sco-server-ycor
    set size 3.75
    set label ""
    set customer-being-served nobody
    set next-completion-time 0
    set server-queue []
    set open true
    set color blue

   ]

  ]
  ;;;;;;print word "sco-servers :" sco-servers
end

;***********************************************************************************************
;*********************************Customer arrival process**************************************
;***********************************************************************************************
; Samples from the exponential distribution to schedule the time of the next
; customer arrival in the system.
to customer-arrival-schedule
  if (customer-arrival-proces = "NHPP_Mean") [customer-arrival-schedule-nhpp-mean]
  if (customer-arrival-proces = "NHPP_Inter_Thin") [customer-arrival-schedule-nhpp-inter-thinning]

end

to customer-arrival-schedule-nhpp-inter-thinning
  set customer-arrival-inter-rate 0
  let u 1
  let t* 0
  let i_clock logo_clock
  let i_ticks ticks
  ;;;;;;print word "customer-local-max-arrival-rate: " customer-local-max-arrival-rate
  ;;;;;;print word "item 0

  while [ abs (( time:difference-between i_clock (item 0 time:ts-get customer-arrival-file i_clock "all") "minutes" )) > 30 and (time:difference-between i_clock  end_time  "minutes") > 0  ]

  [
     set i_clock time:plus i_clock 1 "minutes"
     set i_ticks i_ticks + 1
     ;;;;;print i_ticks
    ]
 let customer-arrival-min-time i_clock
 if (time:difference-between i_clock  end_time  "minutes") > 0
  [while [ (customer-arrival-inter-rate / customer-arrival-max-rate) < u and (time:difference-between customer-arrival-min-time  end_time  "minutes") > 0  ]
    [
    ;;;;;print word "customer-arrival-inter-rate: " customer-arrival-inter-rate
    ;;;;;print word "customer-arrival-max-rate:  "  customer-arrival-max-rate
    set t* (t* + random-exponential (1 / customer-arrival-max-rate))
    ;;;;;;;print word "t*: " t*
    set customer-arrival-min-time time:plus i_clock t* "minutes"
    ;;;;;;;print word "customer-arrival-min-time: " customer-arrival-min-time
    set u random-float 1
    ;;;;;;;print word "u: " u
    set customer-arrival-inter-rate ( customer-arrival-inter-rate-read customer-arrival-min-time )]
      ;;;;;;;print word "customer-arrival-inter-rate "  customer-arrival-inter-rate
  ;;;;;;;print word "t* chosen: " t*
  set customer-arrival-lambda customer-arrival-inter-rate
  set customer-arrival-next-time (i_ticks + t*)]
end

to customer-arrival-schedule-nhpp-mean
  let i_clock logo_clock
  let i_ticks ticks
   while [ abs (( time:difference-between i_clock (item 0 time:ts-get customer-arrival-file i_clock "all") "minutes" )) > 30 ]
    [
     set i_clock time:plus i_clock 1 "minutes"
     set i_ticks i_ticks + 1
    ]

  set customer-arrival-mean-rate (customer-arrival-mean-rate-read i_clock )
  set customer-arrival-lambda customer-arrival-mean-rate
  set customer-arrival-next-time (i_ticks + random-exponential (1 / customer-arrival-mean-rate))
end

to-report customer-arrival-inter-rate-read [clock]
  let value 0
  carefully
      [set value  precision ( (time:ts-get-exact customer-arrival-file clock "\"Bons\"") / 60) 2 ]
      [set value  precision ( (time:ts-get-interp customer-arrival-file clock "\"Bons\"") / 60 ) 2 ]
 ;; print word clock value
  report value
end

to-report customer-arrival-mean-rate-read [clock]
  let value 0

  set value precision ((time:ts-get customer-arrival-file clock "Bons") / 60) 2
  ;;;;;;print word "clock: " clock
  ;;;;;;print word "value: " value
  report value
end


to customer-arrival-arrive

  let created-customer []
  let color-index (customer-arrival-count mod 70)
  let main-color (floor (color-index / 5))
  let shade-offset (color-index mod 5)
  create-customers 1
    [set color (3 + shade-offset + main-color * 10)
     set time-entered-queue ticks
     set created-customer self
     set sco-join-to 0
     set server-queued-on nobody
     set server-served-on nobody
     set server-join-to nobody
     set next-jockey-time 0
     set num-of-customers  count customers
     set num-of-articles  sum [basket-size] of customers
     set num-of-servers count (servers with [open])
     set num-of-sco number-of-sco-servers
     set num-of-jockeying 0]

  set customer-arrival-count (customer-arrival-count + 1)

  ask created-customer
    [customer-basket-payment-set self
     customer-sco-will-set self
     customer-pick-line self]

  customer-arrival-schedule

  if cashier-server-enter-check[
    cashier-server-enter-schedule]
end
;*****************************End of customer arrival process***********************************

to customer-jockeying
  if customer-jockeying-switch [
    if (customer-picking-line-strategy = 1 )  [customer-jockey-strategy1]
    if (customer-picking-line-strategy = 2 )  [customer-jockey-strategy2]
    if (customer-picking-line-strategy = 3 )  [customer-jockey-strategy3]
    if (customer-picking-line-strategy = 4 )  [customer-jockey-strategy4]]
end






;***********************************************************************************************
;**************Customer: Basket size and  method of payment distribution dice*******************
;***********************************************************************************************
to customer-basket-payment-distribution_set

  set customer-basket-payment-distribution ( but-first time:ts-get customer-basket-payment-file  logo_clock "all" )

  let basket-size-sum (sum  but-first time:ts-get customer-basket-payment-file  logo_clock "all")
  ;;;;;;print word "customer-basket-payment-distribution: " customer-basket-payment-distribution
  ;;;;;;print word "basket-size-sum: "  basket-size-sum
  if basket-size-sum > 0 [
    set customer-basket-payment-distribution  map  [ x ->  x / basket-size-sum ] customer-basket-payment-distribution
    ]
  let tempsum 0
  let tempsum_list []
  foreach customer-basket-payment-distribution [ x ->
   set tempsum (tempsum + x )
   set tempsum_list lput tempsum tempsum_list
  ]
  set customer-basket-payment-distribution tempsum_list

end

to-report customer-basket-payment-dice
let x random-float 1
  let y 1 + length filter [x1 -> x1 < x] customer-basket-payment-distribution
  report item y customer-basket-payment-distribution-x
end

to customer-basket-payment-set [customer-created]
 let customer-basket-payment customer-basket-payment-dice
 ask customer-created
  [
   ifelse customer-basket-payment < 1000
    [set basket-size customer-basket-payment
     set payment-method 1
     set shape "customer-cash"
    ][
     set basket-size (customer-basket-payment - 1000)
     set payment-method 2
     set shape "customer-card"
    ]
   set label precision basket-size 2
  ]
end
;************End Basket size distribution and method of payment*********************************

;***********************************************************************************************
;************Customer: Picking line process*****************************************************
;***********************************************************************************************
to customer-sco-will-set [customer-created]
  ifelse ([basket-size] of customer-created <= customer-sco-max-items)
    [set sco-will 1]
    [set sco-will 0]
end

to customer-pick-line [customer-created]

  if (customer-picking-line-strategy = 0 )  [customer-pick-line-strategy0 customer-created]
  if (customer-picking-line-strategy = 1 )  [customer-pick-line-strategy1 customer-created]
  if (customer-picking-line-strategy = 2 )  [customer-pick-line-strategy2 customer-created]
  if (customer-picking-line-strategy = 3 )  [customer-pick-line-strategy3 customer-created]
  if (customer-picking-line-strategy = 4 )  [customer-pick-line-strategy4 customer-created]

end


;******pick line strategy 0 : the random queue**

to customer-join-line [customer-joined]
  let server-joined [server-join-to] of customer-joined
  ; join to line
  if ( server-joined != nobody)[
    ifelse [open] of server-joined[
      ask customer-joined [
      ;;;;;;print word "customer-server-line-picked: " customer-server-line-picked
        set sco 0
        set server-join-to nobody
        set sco-join-to 0
        set server-queued-on server-joined
        move-forward (length ([server-queue] of server-joined)) ([xcor] of server-joined) ([ycor] of server-joined) ]
      ask server-joined [
        set server-queue (lput customer-joined server-queue)
        server-service-begin self ]]
    [
      set sco 0
      set server-join-to nobody
      set sco-join-to 0
      customer-pick-line self]]
   ; join to sco line
  if (number-of-sco-servers != 0 and [sco-join-to] of customer-joined = 1 )[
    ask customer-joined [
      set sco 1
      set sco-join-to 0
      set server-join-to nobody
      move-forward (length sco-queue) sco-zone-xcor sco-zone-ycor]
    set sco-queue (lput customer-joined sco-queue)
    sco-server-service-begin]

end


to customer-pick-line-strategy0 [customer-created]
  let customer-server-line-picked nobody
  let available-servers (servers with [open])
  let number-of-queues ( count available-servers )
  let i random number-of-queues
  ;;;;;;print word "i: " i
  ask customer-created [
    ifelse (i != 0) or (number-of-sco-servers = 0) or (sco-will = 0)
      [set customer-server-line-picked one-of available-servers]
      [set customer-server-line-picked nobody]
    ifelse ( customer-server-line-picked != nobody)[
      set server-join-to customer-server-line-picked]
    [ set sco-join-to 1]
  customer-join-line self]
end



;******pick line strategy 1 : the minimal number of customers**
to customer-pick-line-strategy1 [customer-created]
  let customer-server-line-picked nobody
  let available-servers (servers with [open and not is-agent? customer-being-served])

  ifelse (available-servers = no-turtles)
   [ set customer-server-line-picked (min-one-of (servers with [open]) [length server-queue])]
   [ set customer-server-line-picked one-of available-servers]

  ask customer-created [
    ifelse (customer-server-line-picked != nobody) or (number-of-sco-servers = 0)  [
      ifelse ((length([server-queue] of customer-server-line-picked) <= length(sco-queue)) or (number-of-sco-servers = 0) or (sco-will = 0))[
        set server-join-to customer-server-line-picked]
      [ set sco-join-to 1]]
          ;print word "sco-queue: " sco-queue
    [ set sco-join-to 1]
      customer-join-line self]
end


to customer-jockey-strategy11
  ;select customer to jockey: last customer from the longest line that exced shortest line by threshold
  let customer-jockey nobody
  let max-queue []
  let min-queue []
  if any? (servers with [open]) [
    set max-queue [server-queue] of (max-one-of (servers with [open]) [length server-queue])
    set min-queue [server-queue] of (min-one-of (servers with [open]) [length server-queue])]
  if length max-queue < length sco-queue [set max-queue sco-queue ]
  if (length min-queue > length sco-queue)  [set min-queue sco-queue ]
  if not empty? max-queue and (length max-queue - 1) > (length min-queue + customer-jockey-lenght-threshold)  [
      set  customer-jockey last max-queue]

  ;customer selected: leave the curent line and chose to another to join;
  ;                   not join imediatly, the time will be postpone (next-jockey-time)
  if customer-jockey != nobody [
    let customer-server-line-picked []
    let available-servers (servers with [open and not is-agent? customer-being-served])
    ifelse (available-servers = no-turtles)
     [ set customer-server-line-picked (min-one-of (servers with [open]) [length server-queue])]
     [ set customer-server-line-picked one-of available-servers]
    ;customer-created alredy in some line (jockeying)
    ask customer-jockey [
      if (server-queued-on != nobody) [
       ifelse (customer-server-line-picked != nobody) or (number-of-sco-servers = 0) [
         ifelse (length([server-queue] of customer-server-line-picked) <= length(sco-queue)) or (number-of-sco-servers = 0)  or (sco-will = 0)[
           if ((position self  [server-queue] of server-queued-on) + customer-jockey-lenght-threshold ) > ([length server-queue] of customer-server-line-picked) [
             customer-queue-leave self
             set server-join-to customer-server-line-picked
             set num-of-jockeying (num-of-jockeying + 1) ]
             set next-jockey-time ticks + customer-jockeing-time ]
         [ if (((position self  [server-queue] of server-queued-on) + customer-jockey-lenght-threshold ) >  length sco-queue and number-of-sco-servers != 0)  [
             customer-queue-leave self
             set sco-join-to 1
              set num-of-jockeying (num-of-jockeying + 1)
             set next-jockey-time ticks + customer-jockeing-time ]]]
       [ if (((position self  [server-queue] of server-queued-on) + customer-jockey-lenght-threshold ) >  length sco-queue and number-of-sco-servers != 0)  [
             customer-queue-leave self
             set sco-join-to 1
             set num-of-jockeying (num-of-jockeying + 1)
             set next-jockey-time ticks + customer-jockeing-time]]]
      if (sco != 0) [
        if (customer-server-line-picked != nobody) and ((position self sco-queue) + customer-jockey-lenght-threshold ) > [length server-queue] of customer-server-line-picked [
          customer-queue-leave self
          set num-of-jockeying (num-of-jockeying + 1)
          set server-join-to customer-server-line-picked
          set next-jockey-time ticks + customer-jockeing-time]]]]
end

to customer-jockey-strategy1
  ;select customer to jockey: last customer from the  line with maximum items that exced  line with minimum items by threshold
  let customer-jockey nobody

  let server-max-queue nobody
  let server-min-queue nobody
  if any? (servers with [open]) [
    set server-max-queue max-one-of (servers with [open and not empty? server-queue])  [length server-queue]]
  set server-min-queue min-one-of (servers with [open]) [length server-queue]

  if server-max-queue != nobody [
    if length [server-queue] of server-max-queue < length sco-queue [
      set server-max-queue nobody]]

  if server-min-queue != nobody [
    if (length [server-queue] of server-min-queue > length sco-queue) and (number-of-sco-servers > 0) [
      set server-min-queue nobody]]

  if server-max-queue != nobody  and  server-min-queue != nobody  [
    if length but-last [server-queue] of server-max-queue  > length [server-queue] of server-min-queue + customer-jockey-lenght-threshold [
       set  customer-jockey last [server-queue] of server-max-queue
       ask  customer-jockey[
         customer-queue-leave self
         set num-of-jockeying (num-of-jockeying + 1)
         set server-join-to server-min-queue
         set next-jockey-time ticks + customer-jockeing-time]]]

  if server-max-queue != nobody and  server-min-queue = nobody  [
    if length but-last [server-queue] of server-max-queue  > length sco-queue + customer-jockey-lenght-threshold [
      set  customer-jockey last [server-queue] of server-max-queue
      ask  customer-jockey[
        if sco-will = 1 [
          customer-queue-leave self
          set num-of-jockeying (num-of-jockeying + 1)
          set server-join-to nobody
          set sco-join-to 1
          set next-jockey-time ticks + customer-jockeing-time]]]]

 if server-max-queue = nobody  and  server-min-queue != nobody and not empty? sco-queue    [
      if  length but-last sco-queue   > length [server-queue] of server-min-queue + customer-jockey-lenght-threshold [
       set  customer-jockey last sco-queue
       ask  customer-jockey[
         customer-queue-leave self
         set num-of-jockeying (num-of-jockeying + 1)
         set server-join-to server-min-queue
         set next-jockey-time ticks + customer-jockeing-time]]]
end




;*****pick line strategy 2: minimal number of item
to customer-pick-line-strategy2 [customer-created]
  let customer-server-line-picked []
  let available-servers (servers with [open and not is-agent? customer-being-served])
  let server-line-picked-item-number 0
  let sco-line-item-number 0
  ifelse (available-servers = no-turtles)
   [ set customer-server-line-picked (min-one-of (servers with [open])  [sum [basket-size] of turtle-set server-queue])]
   [ set customer-server-line-picked one-of available-servers]

  if customer-server-line-picked != nobody [
    set server-line-picked-item-number sum [basket-size] of turtle-set ( [server-queue] of customer-server-line-picked )
    set sco-line-item-number sum [basket-size] of turtle-set ( sco-queue )]


  ask customer-created[
    if ( customer-server-line-picked != nobody) [
      ifelse (server-line-picked-item-number <= sco-line-item-number) or (number-of-sco-servers = 0) or (sco-will = 0) [
        set server-join-to customer-server-line-picked]
      [ set sco-join-to 1]]
          ;print word "sco-queue: " sco-queue
    if ( customer-server-line-picked = nobody and (number-of-sco-servers != 0) )[
      set sco-join-to 1]
    customer-join-line self]

end

to customer-jockey-strategy2
  ;select customer to jockey: last customer from the  line with maximum items that exced  line with minimum items by threshold
  let customer-jockey nobody

  let server-max-queue nobody
  let server-min-queue nobody
  if any? (servers with [open]) [
    set server-max-queue max-one-of (servers with [open and not empty? server-queue])  [sum [basket-size] of turtle-set server-queue]
    set server-min-queue min-one-of (servers with [open])  [sum [basket-size] of turtle-set server-queue]]

  if server-max-queue != nobody [
    if sum [basket-size] of turtle-set([server-queue] of server-max-queue) < sum [basket-size] of turtle-set(sco-queue) [
      set server-max-queue nobody]]

  if server-min-queue != nobody [
    if (sum [basket-size] of turtle-set([server-queue] of server-min-queue) > sum [basket-size] of turtle-set(sco-queue)) and (number-of-sco-servers > 0) [
      set server-min-queue nobody]]

  if server-max-queue != nobody  and  server-min-queue != nobody  [
    if sum [basket-size] of turtle-set(but-last [server-queue] of server-max-queue)  > sum [basket-size] of turtle-set([server-queue] of server-min-queue) + customer-jockey-items-threshold [
       set  customer-jockey last [server-queue] of server-max-queue
       ask  customer-jockey[
         customer-queue-leave self
         set num-of-jockeying (num-of-jockeying + 1)
         set server-join-to server-min-queue
         set next-jockey-time ticks + customer-jockeing-time]]]

  if server-max-queue != nobody and  server-min-queue = nobody  [
    if sum [basket-size] of turtle-set(but-last [server-queue] of server-max-queue)  > sum [basket-size] of turtle-set(sco-queue) + customer-jockey-items-threshold [
      set  customer-jockey last [server-queue] of server-max-queue
      ask  customer-jockey[
        if sco-will = 1 [
          customer-queue-leave self
          set num-of-jockeying (num-of-jockeying + 1)
          set server-join-to nobody
          set sco-join-to 1
          set next-jockey-time ticks + customer-jockeing-time]]]]

 if server-max-queue = nobody  and  server-min-queue != nobody and not empty? sco-queue    [
      if  sum [basket-size] of turtle-set(but-last sco-queue)  > sum [basket-size] of turtle-set([server-queue] of server-min-queue) + customer-jockey-items-threshold [
       set  customer-jockey last sco-queue
       ask  customer-jockey[
         customer-queue-leave self
         set num-of-jockeying (num-of-jockeying + 1)
         set server-join-to server-min-queue
         set next-jockey-time ticks + customer-jockeing-time]]]
end




;******pick line strategy  : the minimal expected time according to number of customers and  mean time of service of customer **
to customer-pick-line-strategy3 [customer-created]
  let customer-server-line-picked []
  let available-servers (servers with [open and not is-agent? customer-being-served])
  let customer-server-line-picked-exp-time 0
  let customer-sco-exp-time 0
   ;;;;;;print word "(servers with [open]) [(length server-queue]): "  [(length server-queue)] of (servers with [open])
  ;;;;;;print word "2* (servers with [open]) [(length server-queue]): " [2 * (length server-queue)] of (servers with [open])
  ;;;;;;print word " (min-one-of (servers with [open]) [length server-queue])]: "  (min-one-of (servers with [open]) [(5 * length server-queue) + (8 * length server-queue) ])


  ifelse (available-servers = no-turtles)
    [ set customer-server-line-picked (min-one-of (servers with [open]) [(( server-transaction-avg-time + server-break-avg-time ) * length server-queue)])]
    [ set customer-server-line-picked one-of available-servers]

  if ( customer-server-line-picked != nobody) [  set customer-server-line-picked-exp-time (length([server-queue] of customer-server-line-picked)) * (server-transaction-avg-time + server-break-avg-time)]

  if ( number-of-sco-servers > 0) [ set customer-sco-exp-time ((length(sco-queue) * (sco-server-transaction-avg-time + sco-server-break-avg-time)) / number-of-sco-servers)]

 ask customer-created [
    ifelse ( customer-server-line-picked != nobody) [
      ifelse (customer-server-line-picked-exp-time <= customer-sco-exp-time) or (number-of-sco-servers = 0) or (sco-will = 0) [
        set server-join-to customer-server-line-picked]
      [ set sco-join-to 1]]
          ;print word "sco-queue: " sco-queue
    [ set sco-join-to 1]
    customer-join-line self]
end


to customer-jockey-strategy3
  ;select customer to jockey: last customer from the  line with maximum items that exced  line with minimum items by threshold
  let customer-jockey nobody
  let sco-server-expected-waiting-time 0
  ask servers with [open][
    ifelse is-agent? customer-being-served [
      set expected-waiting-time ((server-transaction-avg-time + server-break-avg-time ) * length server-queue)]
    [ set expected-waiting-time ((server-transaction-avg-time + server-break-avg-time ) * length server-queue)]]

  if ( number-of-sco-servers > 0) [ set sco-server-expected-waiting-time ((length(sco-queue) * (sco-server-transaction-avg-time + sco-server-break-avg-time)) / number-of-sco-servers)]
  let server-max-queue nobody
  let server-min-queue nobody
  let max-queue []
  let min-queue []
  if any? (servers with [open]) [
    set server-max-queue max-one-of (servers with [open and not empty? server-queue]) [expected-waiting-time]
    set server-min-queue min-one-of (servers with [open]) [expected-waiting-time]]

  ifelse server-max-queue != nobody [
    ifelse [expected-waiting-time] of server-max-queue  < sco-server-expected-waiting-time [
      set max-queue sco-queue
      set server-max-queue nobody]
    [ set max-queue [server-queue] of server-max-queue]]
  [ set max-queue sco-queue]

  ifelse server-min-queue != nobody [
    ifelse [expected-waiting-time] of server-min-queue  > sco-server-expected-waiting-time and number-of-sco-servers > 0 [
      set min-queue sco-queue
      set server-min-queue nobody ]
    [ set min-queue [server-queue] of server-min-queue]]
  [set min-queue sco-queue]

  if not empty? max-queue  and  server-min-queue != nobody  [
    if (server-transaction-avg-time + server-break-avg-time ) * length but-last max-queue > [expected-waiting-time] of server-min-queue + customer-jockey-time-threshold [
       set  customer-jockey last max-queue
       ask  customer-jockey[
         customer-queue-leave self
         set num-of-jockeying (num-of-jockeying + 1)
         set server-join-to server-min-queue
         set next-jockey-time ticks + customer-jockeing-time]]]

  if not empty? max-queue  and  server-min-queue = nobody  [
    if (server-transaction-avg-time + server-break-avg-time ) * length but-last max-queue > sco-server-expected-waiting-time + customer-jockey-time-threshold [
       set  customer-jockey last max-queue
       ask  customer-jockey[
         customer-queue-leave self
         set num-of-jockeying (num-of-jockeying + 1)
         set server-join-to nobody
         set sco-join-to 1
         set next-jockey-time ticks + customer-jockeing-time]]]
end




;******pick line strategy  : the minimal expected time according to number of items and expected time of transaction and break **
to customer-pick-line-strategy4 [customer-created]
  let customer-server-line-picked []
  let available-servers (servers with [open and not is-agent? customer-being-served])
  let customer-server-line-picked-exp-time 0
  let customer-sco-exp-time 0
  let text-jockey ""
  ;;;;;;print word "(servers with [open]) [(length server-queue]): "  [(length server-queue)] of (servers with [open])
  ;;;;;;print word "2* (servers with [open]) [(length server-queue]): " [2 * (length server-queue)] of (servers with [open])
  ;;;;;;print word " (min-one-of (servers with [open]) [length server-queue])]: "  (min-one-of (servers with [open]) [(5 * length server-queue) + (8 * length server-queue) ])

  ask servers with [open]
      [ ifelse is-agent? customer-being-served
         [set expected-waiting-time ((server-waiting-time-expected [server-queue] of self nobody)  + next-completion-time - ticks)]
         [set expected-waiting-time (server-waiting-time-expected [server-queue] of self nobody)]]
  set sco-expected-waiting-time  (sco-server-waiting-time-expected sco-queue  nobody)

 ifelse (available-servers = no-turtles)
    [ set customer-server-line-picked (min-one-of (servers with [open]) [expected-waiting-time])]
    [ set customer-server-line-picked one-of available-servers]

 if ( customer-server-line-picked != nobody) [set customer-server-line-picked-exp-time [expected-waiting-time] of customer-server-line-picked]
 if ( number-of-sco-servers > 0) [ set customer-sco-exp-time sco-expected-waiting-time]

 ask customer-created [
    ifelse ( customer-server-line-picked != nobody)[
        ;;;;print word "sco-expected-waiting-time: " sco-expected-waiting-time
        ;;;;print word "sco-queue length: " length sco-queue
        ;;;;print word "sco basket size sum: " sum [basket-size] of turtle-set ( sco-queue )
      ifelse (customer-server-line-picked-exp-time <= customer-sco-exp-time) or (number-of-sco-servers = 0) or (sco-will = 0)[
        set server-join-to customer-server-line-picked]
      [ set sco-join-to 1]]
          ;print word "sco-queue: " sco-queue
    [ set sco-join-to 1]
    customer-join-line self]
end

to customer-jockey-strategy4
  ;select customer to jockey: last customer from the  line with maximum items that exced  line with minimum items by threshold
  let customer-jockey nobody
  let sco-server-expected-waiting-time 0
  ask servers with [open][
    ifelse is-agent? customer-being-served[
      set expected-waiting-time ((server-waiting-time-expected [server-queue] of self nobody)  + next-completion-time - ticks)]
    [ set expected-waiting-time (server-waiting-time-expected [server-queue] of self nobody)]]

  if ( number-of-sco-servers > 0)[ set sco-server-expected-waiting-time  (sco-server-waiting-time-expected sco-queue  nobody)]

  let server-max-queue nobody
  let server-min-queue nobody
  if any? (servers with [open]) [
    set server-max-queue max-one-of (servers with [open and not empty? server-queue]) [expected-waiting-time]
    set server-min-queue min-one-of (servers with [open]) [expected-waiting-time]]

  if server-max-queue != nobody [
    if [expected-waiting-time] of server-max-queue  < sco-server-expected-waiting-time [
      set server-max-queue nobody]]

  if server-min-queue != nobody [
    if ([expected-waiting-time] of server-min-queue  > sco-server-expected-waiting-time) and (number-of-sco-servers > 0) [
      set server-min-queue nobody]]

  if server-max-queue != nobody  and  server-min-queue != nobody  [
    if server-waiting-time-expected [server-queue] of server-max-queue (last [server-queue] of server-max-queue)  > [expected-waiting-time] of server-min-queue + customer-jockey-time-threshold [
       set  customer-jockey last [server-queue] of server-max-queue
       ask  customer-jockey[
         customer-queue-leave self
         set num-of-jockeying (num-of-jockeying + 1)
         set server-join-to server-min-queue
         set next-jockey-time ticks + customer-jockeing-time]]]

  if server-max-queue != nobody and  server-min-queue = nobody  [
    if server-waiting-time-expected [server-queue] of server-max-queue (last [server-queue] of server-max-queue) > sco-server-expected-waiting-time + customer-jockey-time-threshold [
      set  customer-jockey last [server-queue] of server-max-queue
      ask  customer-jockey[
        if sco-will = 1 [
          customer-queue-leave self
          set num-of-jockeying (num-of-jockeying + 1)
          set server-join-to nobody
          set sco-join-to 1
          set next-jockey-time ticks + customer-jockeing-time]]]]

 if server-max-queue = nobody  and  server-min-queue != nobody and not empty? sco-queue    [
      if sco-server-waiting-time-expected sco-queue (last sco-queue)  > [expected-waiting-time] of server-min-queue + customer-jockey-time-threshold [
       set  customer-jockey last sco-queue
       ask  customer-jockey[
         customer-queue-leave self
         set num-of-jockeying (num-of-jockeying + 1)
         set server-join-to server-min-queue
         set next-jockey-time ticks + customer-jockeing-time]]]
end



to-report server-waiting-time-expected [cs from-customer]
; Report expected waiting time for queue cs
; expexted waiting time is calculated for customer on position max-position
let max-position 9999
if from-customer != nobody
  [set max-position position from-customer cs]
let ei 0
  foreach cs [
      x -> if ((position x cs) < max-position) [set ei  ei + server-transaction-time-expected ([basket-size] of x) + server-break-time-expected ]]
  report ei
end

to-report sco-server-waiting-time-expected [cs from-customer]
  let max-position 9999
  if from-customer != nobody
    [set max-position position from-customer cs]
; Report expected waiting time for queue cs
; expexted waiting time is calculated for customer on position max-position
  let ei 0
  let is 0

  ifelse any? sco-servers [
    ask sco-servers
      [set expected-waiting-time  ticks
       if is-agent? customer-being-served [set expected-waiting-time next-completion-time]]

    foreach cs [
      x -> if (position x cs < max-position) [
        set is [who] of  min-one-of sco-servers [expected-waiting-time]
        ask sco-server is
          [set expected-waiting-time  expected-waiting-time + sco-server-service-time-expected ([basket-size] of x) + sco-server-break-time-expected  ([basket-size] of x)] ]]

    report ([expected-waiting-time] of min-one-of sco-servers [expected-waiting-time]) - ticks]
  [
    report 9999999]
end





to customer-queue-leave [customer-to-leave]
let m 0
  ask customer-to-leave [
   ifelse sco = 0
     [ set m position self [server-queue] of server-queued-on]
     [ set m position self sco-queue ]
   set xcor 0
   set ycor 0
   ]
  ifelse [sco] of customer-to-leave = 0
    [ ask  [server-queued-on] of customer-to-leave [
            set server-queue remove customer-to-leave server-queue
            move-queue server-queue xcor ycor (m)] ]
    [ set sco-queue remove customer-to-leave sco-queue
      move-queue sco-queue sco-zone-xcor sco-zone-ycor (m)]
  ask customer-to-leave [
    set server-queued-on nobody
    set sco 0 ]
end


;************End Picking line process***********************************************************

;***********************************************************************************************
;**************Customer: Leaving process*********************************************************

to customer-model-leave [customer-to-leave]

  ask customer-to-leave


     [set time-leaving-model logo_clock
       time:ts-add-row customer-leaving-data-file (list time-leaving-model time-leaving-model customer-picking-line-strategy basket-size payment-method sco-will (ticks-to-date time-entered-queue)
                                                  (ticks-to-date time-entered-service) (ticks - time-entered-service) (ticks - time-entered-queue)
                                                  (time-entered-service - time-entered-queue) (sco) (num-of-servers) (num-of-sco) (num-of-customers) (num-of-articles) expected-waiting-time num-of-jockeying)
       ;;;;print word "expected before die: " expected-waiting-time
       die]

       ;;;;;print word "customer-leaving-data-save-time: " customer-leaving-data-save-time
       ;;;;;print word "ticks: " ticks
 ;********save output data every 60 secound
 ;if customer-leaving-data-save-time < ticks
 ;   [ time:ts-write customer-leaving-data-file OutputPath customer-leaving-data-file-output
 ;     set customer-leaving-data-save-time (ticks + 60)]

end

to-report ticks-to-date [iticks]
 report time:plus start_time iticks "minutes"
end


to-report ts-future-get [iclock iticks its n]
  let line []

  let i 0
  set line time:ts-get its (time:plus iclock i "minutes") "all"
  ;;;;;;print word "line: " line
  while [(time:difference-between (time:plus iclock i "minutes") first line "minutes") <= 0 and i <= n]
    [set i ( i + 1)
     set line time:ts-get its (time:plus iclock i "minutes") "all"]

   ifelse  time:difference-between iclock first line "minutes" > 0
    [report iticks + (time:difference-between iclock first line  "minutes")]
    [report 0 ]
end
;***********************************************************************************************
;**********************Cashier: Arrival process*************************************************
;***********************************************************************************************
to cashier-arrival-schedule

  ;;;;;;print word "cashier-arrival-next-time: " cashier-arrival-next-time
  if cashier-arrival-next-time <= ticks [set cashier-arrival-next-time ts-future-get logo_clock ticks cashier-arrival-schedule-file 60 ]
  ;;;;;;print word "cashier-arrival-next-time2: " cashier-arrival-next-time
end

to cashier-arrive
  let line time:ts-get cashier-arrival-schedule-file logo_clock "all"
  if (time:difference-between first line logo_clock "minutes") < 300[

    ;set number-of-cashier100 item 3 line
    ;set number-of-cashier075 item 2 line
    set number-of-cashier050 item 1 line
    ;let number-of-cashier0125 item 1 line

    ;cashier-creation number-of-cashier100 480
    ;cashier-creation number-of-cashier075 360
    cashier-create number-of-cashier050 240
    ;cashier-create number-of-cashier0125 60
  ]
end
;**************************End of cashier arrive proces*****************************************

to cashier-create [numberv timev]
;;;;;;print word "creation of cashiers" numberv
;;;;;;print word "creation of cashiers" numberv
if numberv > 0 [
  let created-cashier nobody
  create-cashiers numberv [
     set color red
     set time-start ticks
     set time-end ticks + timev
     set xcor 0
     set ycor 0
     set created-cashier self
     set time-break-start ticks
     set time-break-end ticks
     set time-break-count 0
     set time-break-length 0
     set shape "cashier"
     set size 2.75
     set working false
     set server-working-on nobody
     cashier-data-save self "OperatorArrive"
    ]
    if cashier-server-enter-check [cashier-server-enter]
  ]
  cashiers-backoffice-go

   ;  set server-working-on nobody
   ;  cashier-data-save self "OperatorArrive"  ]
end

to cashiers-backoffice-go
  let cashiers-list [ self ] of cashiers with [not working]
  let i 1
  foreach cashiers-list [ x ->
   ask x
     [
      set xcor min-pxcor + i
      set ycor min-pycor
      set shape "person"
      set size 1
      set i i + 1]]

end
;*****************Schedule enter cashier from back office
to cashier-server-enter-schedule

  if cashier-server-enter-next-time < ticks [set cashier-server-enter-next-time ( ticks + cashier-return-time)]
  ;;;;;;print word "cashier-server-enter-next-time: " cashier-server-enter-next-time
end

to-report cashier-server-enter-check
  ifelse any? (servers with [open])
    [ ifelse ((sum ([length(server-queue)] of (servers with [open])) + length(sco-queue)) / (count  (servers with [open]) + 1)  > cashier-max-line)
      [ report true ]
      [ report false ]]
    [ report true ]
end

to-report cashier-server-close-check [processed-server]
  ifelse [server-queue] of processed-server = [] and not [sys] of processed-server
  [ifelse any? servers with [open]
     [ifelse ((sum ([length(server-queue)] of (servers with [open])) + length(sco-queue)) / (count  (servers with [open]) + 1) < cashier-min-line)
       [ report true ]
       [ report false]]
     [report false]]
  [report false]
end



to cashier-server-enter

  let processed-cashier one-of cashiers with [not working]
  if processed-cashier != nobody
    [ let server-to-work  []

      ;First choice: server with cashiers that alredy closed checkout
      let available-servers (servers with [not open and is-agent? cashier-working-on])

      ;Second choice servers with cashiers that should end of work til now
      if not (any? available-servers)
        [ set available-servers (servers with [open and is-agent? cashier-working-on and [time-end] of cashier-working-on <= (ticks + 1) ])]

      ;Third choice closed checkout w/o cashier
      if not (any? available-servers)
        [ set available-servers (servers with [not open and not is-agent? cashier-working-on])]


      set server-to-work one-of available-servers
      cashier-server-leave [cashier-working-on] of server-to-work

      ask server-to-work
        [ set cashier-working-on processed-cashier
          ;;;;;;print word "procssed-cashier  " processed-cashier
          set open true
          set color green]
      ask processed-cashier
         [ set xcor [xcor] of server-to-work
           set ycor [ycor] of server-to-work
           set shape "cashier"
           set size 2.75
           set server-working-on server-to-work
           set working true
           set time-break-end ticks
           set time-break-length ( time-break-length + time-break-end - time-break-start )
            if (time-break-end > time-break-start)
               [set time-break-count  time-break-count + 1 ]
            cashier-data-save self "OperatorSignOn"]
         ]

      customer-jockeying
end

to cashier-end-schedule

  if not(one-of cashiers with [time-end >= ticks] = nobody)
         [set cashier-stop-next-time [time-end] of min-one-of (cashiers with [time-end >= ticks]) [time-end]]

end

to cashier-stop
  let cashiers-to-stop  (cashiers with [(time-end <= ticks) and working ])
  let servers-to-stop []
  ;;;;;;print word "cashiers-to-stop: " cashiers-to-stop
  if any? cashiers-to-stop
    [ ask cashiers-to-stop
      [ set servers-to-stop ( fput server-working-on servers-to-stop ) ]

      if servers-to-stop != []
       [foreach servers-to-stop
         [ x ->  cashier-server-close x ]]]

  set cashiers-to-stop  (cashiers with [(time-end <= ticks) and not working ])
  if any? cashiers-to-stop
     [ ask cashiers-to-stop
        [cashier-model-leave self]]
end

to cashier-server-close [server-to-close]
  ask server-to-close
   [ set open false
     set color red
     if customer-being-served = nobody
      [cashier-server-leave ([cashier-working-on] of self)]]

end


to cashier-server-leave [ processed-cashier ]
  ;;;;;;print word "processed-cashier1: " processed-cashier
  ;;;;;;print word "is-agent? 1: " is-agent? processed-cashier
  if is-agent? processed-cashier
  [ask processed-cashier
    [ set time-break-start ticks
      set working false
      cashier-data-save self "OperatorSignOff"
      set color red
      set xcor 0
      set ycor 0
      ask server-working-on [ set cashier-working-on nobody
                              set expected-waiting-time 0 ]
      set server-working-on nobody
      cashier-model-leave self ]]
      cashiers-backoffice-go
end

to cashier-model-leave [processed-cashier]
   ;;;;;;print word "processed-cashier2: " processed-cashier
   ;;;;;;print word "is-agent? 2: " is-agent? processed-cashier

   if is-agent? processed-cashier
     [ask processed-cashier
        [ if time-end <= (ticks + 1)
           [
            cashier-data-save self "OperatorLeave"
            ;set cashier-leaving-data-file (sentence cashier-leaving-data-file ( list (list (time:show logo_clock "dd.MM.YYYY HH:mm:ss") ticks who time-start time-end time-break-start time-break-end time-break-count time-break-length  )))
              die
      ]]]
  ; if cashier-leaving-data-save-time < ticks
  ;  [ csv:to-file OutputPath cashier-leaving-data-file-output cashier-leaving-data-file
  ;    set cashier-leaving-data-save-time (cashier-leaving-data-save-time + 300)]
end

to cashier-data-save [processed-cashier operation]
  ask processed-cashier[
    let WorkstationId 0
    if server-working-on != nobody [set WorkstationId ([who] of server-working-on)]
    let cashier-data-to-save (list 1 WorkstationId (word (time:show logo_clock "YYYYMMddHHmmss") who )  (time:show logo_clock "YYYY-MM-dd HH:mm:ss") (time:show logo_clock "YYYY-MM-dd HH:mm:ss") (who) 0 0 0 operation)
    set cashier-leaving-data-file (sentence cashier-leaving-data-file ( list cashier-data-to-save))

  ]
end

to go


  ifelse (ticks < max-run-time) [
    customer-basket-payment-distribution_set
    let next-event []
    let next-server-to-complete next-server-complete
    let next-sco-server-to-complete next-sco-server-complete
    let next-customer-to-jockey next-customer-jockey
    set server-queus-lengths []
    ;******schedule events according to external sources******
    ;;;;;print "start cashier end schedule"
    cashier-end-schedule
    ;;;;;print "start cashier arrival schedule"
     cashier-arrival-schedule
    ;if (customer-arrival-next-time <= 0 ) [
    ;;;;;print "start customer arrival schedule"
    customer-arrival-schedule
    ;;;;;print "end customer arrival schedule"

    ;***********Set of event queue*********************************
    let event-queue (list (list max-run-time "end-run"))
    if (is-turtle? next-customer-to-jockey)[
      set event-queue (fput ( list ([next-jockey-time] of next-customer-to-jockey)  "join-line" ( next-customer-to-jockey )) event-queue)]

    if (customer-arrival-next-time > ticks)[
      set event-queue (fput (list customer-arrival-next-time "customer-arrival-arrive") event-queue)]

    if (cashier-arrival-next-time > ticks )[
      set event-queue (fput (list cashier-arrival-next-time "cashier-arrive") event-queue)]

    if (cashier-stop-next-time > ticks)[
      set event-queue (fput (list cashier-stop-next-time "cashier-stop") event-queue)]

    if (is-turtle? next-server-to-complete)[
      set event-queue (fput (list ([next-completion-time] of next-server-to-complete) "complete-service" ([who] of next-server-to-complete)) event-queue)]

    if (is-turtle? next-sco-server-to-complete)[
      set event-queue (fput (list ([next-completion-time] of next-sco-server-to-complete)
                                  "complete-sco-service" ([who] of next-sco-server-to-complete)) event-queue)]

    if (cashier-server-enter-next-time > ticks)[
      set event-queue (fput (list cashier-server-enter-next-time "cashier-server-enter") event-queue)]

    if (stats-reset-time > ticks)[
      set event-queue (fput (list stats-reset-time "reset-stats") event-queue) ]

    ;****************************************************************
    ;***************sort an event queue********************************
    set event-queue (sort-by [ [ ?1 ?2 ] -> first ?1 < first ?2] event-queue)
       ;;;;;print event-queue
       ;;;;;print customer-leaving-data-file
    ;****************************************************************

    ;***************run first event in queue*************************
    let first-event first event-queue
      ;;;;;print "Start update stat"
    update-usage-stats first first-event
        ;;;;;print "End usage stat"
    foreach event-queue [
      x -> set next-event x if ((first first-event) = (first next-event)) [
        ;print word "runned  " (reduce [ [ ?1 ?2 ] -> (word ?1 " " ?2)] (but-first next-event))
        ;;;;print word "ticks: " ticks
        run (reduce [ [ ?1 ?2 ] -> (word ?1 " " ?2)] (but-first next-event))]]]

  [ stop]

end


; Ends the execution of the simulation. In fact, this procedure does nothing,
; but is still necessary. When the associated event is the first in the event
; queue, the clock will be updated to the simulation end time prior to this
; procedure being invoked; this causes the go procedure to stop on the next
; iteration.

to end-run
  time:ts-write customer-leaving-data-file OutputPath customer-leaving-data-file-output
  csv:to-file OutputPath cashier-leaving-data-file-output cashier-leaving-data-file
  ask cashiers [cashier-model-leave self]
end


; Creates a new customer agent, select queue, adds it to the queue, and attempts to start
; service.


to-report server-transaction-time-random [bs]
 ;calculation of server service  time according to power regrssion model to simplify computation normal dostribution of residual was taken
 report  (e ^ ( 2.121935 + 0.698402 * ln bs + random-normal 0 0.4379083) ) / 60
end

to-report server-break-time-random
 ;to simplyfy computing gamma random was taken  as break-time distribution
 report (random-gamma 3.074209 (1 / 4.830613)) / 60

end

to-report server-transaction-time-expected [bs]
 report (e ^ ( 2.121935 + 0.698402 * ln bs) ) / 60
end

to-report server-break-time-expected
 report (3.074209 * (4.830613)) / 60
end




to server-service-begin [processed-server]
  if (not is-agent? ([customer-being-served] of processed-server ))[
    ifelse (not empty? ([server-queue] of processed-server))[
        let bs 0
        let next-customer (first  ([server-queue] of processed-server))
        ask processed-server[
          set server-queue  (but-first server-queue)]
        ask next-customer [
          set time-entered-service ticks
          set bs basket-size
          set server-queued-on nobody
          set server-served-on processed-server
          set total-time-in-queue
          (total-time-in-queue + time-entered-service - time-entered-queue)
          set total-queue-throughput (total-queue-throughput + 1)
          move-to processed-server]
       ask processed-server [
          set customer-being-served next-customer
          set next-completion-time (ticks + server-transaction-time-random bs + server-break-time-random)
          set label precision next-completion-time 3
          set color yellow]]
    [ if not ([open] of processed-server) [cashier-server-leave ([cashier-working-on] of processed-server)]]]
  move-queue ([server-queue] of processed-server) ([xcor] of processed-server) ([ycor] of processed-server) 0
  customer-jockeying
end


to-report sco-server-service-time-random [bs]
;calculation of server service  time according to power regrssion model to simplify computation normal dostribution of residual was taken
 report  (e ^ ( 3.122328 + 0.672461 * ln bs + random-normal 0 0.4907405) ) / 60

end

to-report sco-server-break-time-random [bs]
 report (e ^ ( 3.51669 + 0.22300 * ln bs + random-normal 0 0.4820532) ) / 60
end

to-report sco-server-service-time-expected [bs]
 report  (e ^ ( 3.122328 + 0.672461 * ln bs) ) / 60
end

to-report sco-server-break-time-expected [bs]
 report (e ^ ( 3.51669 + 0.22300 * ln bs) ) / 60
end





to sco-server-service-begin
  let available-sco-servers (sco-servers with [not is-agent? customer-being-served])
  let bs 0
  if (not empty? sco-queue and any? available-sco-servers) [
    let next-customer (first sco-queue)
    let next-sco-server one-of available-sco-servers
    set sco-queue (but-first sco-queue)
    ;set sco-expected-waiting-time  sco_ewt sco-queue
    ask next-customer [
      set time-entered-service ticks
      set total-time-in-queue
        (total-time-in-queue + time-entered-service - time-entered-queue)
      set total-queue-throughput (total-queue-throughput + 1)
      set bs basket-size
      set server-served-on next-sco-server
      ;print word "server-served-on" server-served-on
      move-to next-sco-server]
    ask next-sco-server [
      set customer-being-served next-customer
      set next-completion-time (ticks + sco-server-service-time-random bs + sco-server-break-time-random bs)
      set label precision next-completion-time 3
      set color yellow]
    move-queue sco-queue sco-zone-xcor sco-zone-ycor 0
    customer-jockeying]
end


to join-line [customer-to-join]
  ask (customer-to-join) [
    customer-join-line customer-to-join]
  customer-jockeying
end

; Updates time-in-system statistics, removes current customer agent, returns the
; server to the idle state, and attempts to start service on another customer.

to complete-service [server-id]
  ask (server server-id) [
    set total-time-in-system (total-time-in-system + ticks
      - [time-entered-queue] of customer-being-served)
    set total-system-throughput (total-system-throughput + 1)
    customer-model-leave customer-being-served

    set customer-being-served nobody
    set next-completion-time 0
    ifelse open
      [set color green]
      [set color red]
    set label ""]
  server-service-begin (server server-id)
  if cashier-server-close-check (server server-id)   [cashier-server-close server server-id]
  ;and not [sys] of (server server-id)
end

to complete-sco-service [sco-server-id]
  ask (sco-server sco-server-id) [
    set total-time-in-system (total-time-in-system + ticks
      - [time-entered-queue] of customer-being-served)
    set total-system-throughput (total-system-throughput + 1)
    customer-model-leave customer-being-served

    set customer-being-served nobody
    set next-completion-time 0
    set color green
    set label ""]
   sco-server-service-begin
end


; Reports the busy server with the earliest scheduled completion.

to-report next-customer-jockey
  report (min-one-of (customers with [(is-agent? server-join-to or sco-join-to = 1) and next-jockey-time != 0 ]) [next-jockey-time])
end


to-report next-server-complete
  report (min-one-of (servers with [is-agent? customer-being-served]) [next-completion-time])
end

to-report next-sco-server-complete
  report (min-one-of (sco-servers with [is-agent? customer-being-served]) [next-completion-time])
end
;

to-report min-sco-server-complete-time
   ifelse is-agent? one-of sco-servers with [not is-agent? customer-being-served]
      [report ticks]
      [report [next-completion-time] of next-sco-server-complete]

end

to move-queue [moved-queue queue-xcor queue-ycor min-position]
;print word "moved-queue: " moved-queue
foreach moved-queue [
    x ->  ask x
    [ if position x moved-queue >= min-position [ move-forward (position x moved-queue) queue-xcor queue-ycor]]]
end

to move-forward [queue-position queue-xcor queue-ycor ]
  let new-xcor queue-xcor
  let new-ycor
     ( queue-ycor + queue-server-offset + (customer-visual-yinterval * queue-position))
  ifelse (new-ycor > max-pycor) [
    hide-turtle]
  [setxy new-xcor new-ycor
    if (hidden?) [
      show-turtle]]
end

; Sets all aggregate statistics back to 0 - except for the simulation start
; time (used for computing average queue length and average server utilization),
; which is set to the current time (which is generally not 0, for a reset-stats
; event).

to reset-stats
  set total-customer-queue-time 0
  set total-customer-service-time 0
  set total-time-in-queue 0
  set total-time-in-system 0
  set total-queue-throughput 0
  set total-system-throughput 0
  set stats-start-time ticks
end


; Updates the usage/utilization statistics and advances the clock to the
; specified event time.

to update-usage-stats [event-time]
  let delta-time (event-time - ticks)
  let busy-servers (servers with [is-agent? customer-being-served])
  ask servers [ set server-queus-lengths lput length ([server-queue] of self) server-queus-lengths   ]
  ; ;;;;;;print server-queus-lengths
  let in-queue (sum server-queus-lengths)
  let in-process (count busy-servers)
  let in-system (in-queue + in-process)
  set customers-arrival-per-min count customers with  [time-entered-queue > ticks - 1]
  set total-customer-queue-time
    (total-customer-queue-time + delta-time * in-queue)
  set total-customer-service-time
    (total-customer-service-time + delta-time * in-process)
  tick-advance (event-time - ticks)
  do-plotting_Customers_in_Queues
  update-plots

  time:ts-add-row customer-arrival-data-file (list logo_clock customers-arrival-per-min customer-arrival-lambda )
  if customer-arrival-data-save-time < ticks [
    time:ts-write customer-arrival-data-file OutputPath customer-arrival-data-file-output
    set customer-arrival-data-save-time (customer-arrival-data-save-time + 60)]
end







; Updates statistics (which also advances the clock) and dispatches the end-run,
; reset-stats, complete-service, or arrive procedure  , based on the next event
; scheduled.set label precisionset label precision


to do-plotting_Customers_in_Queues
  set-current-plot "Customers_in_Queues"
  let q 0
  let y 0
  foreach server-queus-lengths [ x ->
    set q ( q + 1)
    create-temporary-plot-pen word "Server " q
    set-plot-pen-color q * 5
    plotxy ticks  y + x
    ;set y (y + x)
   ]
  create-temporary-plot-pen "SCO-Server"
  set-plot-pen-color blue
  plotxy ticks length sco-queue
end
@#$#@#$#@
GRAPHICS-WINDOW
278
10
811
353
-1
-1
15.91
1
9
1
1
1
0
1
1
1
-16
16
-10
10
1
1
1
ticks
30.0

SLIDER
5
242
271
275
number-of-servers
number-of-servers
1
20
20.0
1
1
NIL
HORIZONTAL

SLIDER
3
312
271
345
number-of-sco-servers
number-of-sco-servers
0
8
6.0
1
1
NIL
HORIZONTAL

BUTTON
11
72
66
105
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
3
277
269
310
stats-reset-time
stats-reset-time
1
max-run-time / 2
301.0
100
1
ticks
HORIZONTAL

BUTTON
69
72
124
105
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
127
72
182
105
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
189
10
274
55
Logo Time
ticks
3
1
11

PLOT
820
164
1499
314
Customers arrival process
time
totalas
0.0
1000.0
0.0
20.0
true
true
"plot-pen-down" ""
PENS
"NHPP (thinned)" 1.0 0 -2674135 true "" "plotxy ticks customers-arrival-per-min"
"lambda(t)" 1.0 0 -10899396 true "" "plotxy ticks customer-arrival-lambda"

MONITOR
11
10
186
55
Calendar / Clock
time:show logo_clock \"EEEE, dd.MM.YYYY HH:mm:ss\"
17
1
11

PLOT
818
317
1500
596
Customers_in_Queues
time
totals
0.0
1000.0
0.0
10.0
true
true
"" ""
PENS

PLOT
820
11
1500
161
Cashiers
time
totals
0.0
1000.0
0.0
10.0
true
true
"" ""
PENS
"in_store    " 1.0 0 -16777216 true "" "plotxy ticks (count cashiers)"
"on_checkout" 1.0 0 -2674135 true "" "plotxy ticks (count cashiers with [working = true])"

INPUTBOX
654
674
814
734
customer-arrival-file-input
4560_customers_input.csv
1
0
String

INPUTBOX
132
612
299
672
customer-basket-payment-file-input
4560_basket_size_input.csv
1
0
String

CHOOSER
132
368
266
413
customer-picking-line-strategy
customer-picking-line-strategy
0 1 2 3 4 11
4

CHOOSER
-1
368
124
413
customer-arrival-proces
customer-arrival-proces
"NHPP_Mean" "NHPP_Inter" "NHPP_Inter_Thin"
2

INPUTBOX
477
612
653
672
customer-scowillingness-file-input
sco_usage.csv
1
0
String

INPUTBOX
300
674
474
734
customer-arrival-data-file-output
4560_customer_arrival_output_410.csv
1
0
String

INPUTBOX
131
674
299
734
customer-leaving-data-file-output
4560_transaction_output_410.csv
1
0
String

INPUTBOX
301
613
475
673
cashier-arrival-schedule-file-input
4560_cashiers_input.csv
1
0
String

CHOOSER
130
468
269
513
cashier-min-line
cashier-min-line
1 2 3 4 5 6 7 8 9 10
0

INPUTBOX
272
468
394
528
cashier-return-time
1.0
1
0
Number

INPUTBOX
476
674
652
734
cashier-leaving-data-file-output
4560_cashier_output_410.csv
1
0
String

SLIDER
0
418
123
451
customer-sco-max-items
customer-sco-max-items
5
100
100.0
1
1
NIL
HORIZONTAL

CHOOSER
2
468
121
513
cashier-max-line
cashier-max-line
0 1 2 3 4
2

INPUTBOX
-1
611
126
671
simulation-no
10.0
1
0
Number

INPUTBOX
-1
673
126
733
store-no
4560
1
0
String

INPUTBOX
272
368
396
428
customer-jockeing-time
0.1
1
0
Number

INPUTBOX
403
368
540
428
customer-jockey-lenght-threshold
2.0
1
0
Number

TEXTBOX
14
56
164
74
Control
11
0.0
1

TEXTBOX
6
597
156
615
File-name-parameters
11
0.0
1

TEXTBOX
8
227
158
245
Model-parameters
11
0.0
1

TEXTBOX
5
349
155
367
Customer-parameters
11
0.0
1

TEXTBOX
2
453
152
471
Cashier-parameters
11
0.0
1

INPUTBOX
687
370
811
430
customer-jockey-items-threshold
30.0
1
0
Number

INPUTBOX
543
369
682
429
customer-jockey-time-threshold
0.5
1
0
Number

TEXTBOX
1
519
151
537
Server-parameters
11
0.0
1

INPUTBOX
-2
536
123
596
server-transaction-avg-time
64.78542
1
0
Number

INPUTBOX
128
536
264
596
server-break-avg-time
15.97272
1
0
Number

INPUTBOX
270
536
395
596
sco-server-transaction-avg-time
103.1093
1
0
Number

INPUTBOX
400
536
533
596
sco-server-break-avg-time
68.06317
1
0
Number

SWITCH
132
420
264
453
customer-jockeying-switch
customer-jockeying-switch
1
1
-1000

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
Circle -7500403 true true 50 5 80
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Rectangle -7500403 true true 67 79 112 94
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Polygon -7500403 true true 45 90 0 150 15 180 75 105
Circle -7500403 true true 165 270 30
Circle -7500403 true true 240 270 30
Polygon -7500403 false true 240 285 195 285 180 285 150 180 300 180 255 285
Line -7500403 true 150 195 300 195
Line -7500403 true 285 210 165 210
Line -7500403 true 165 225 285 225
Line -7500403 true 165 240 270 240
Line -7500403 true 180 255 270 255
Line -7500403 true 180 270 255 270
Line -7500403 true 195 285 195 180
Line -7500403 true 180 255 180 180
Line -7500403 true 165 240 165 180
Line -7500403 true 210 285 210 180
Line -7500403 true 225 285 225 180
Line -7500403 true 240 285 240 180
Line -7500403 true 255 270 255 180
Line -7500403 true 270 255 270 180
Line -7500403 true 285 225 285 180
Rectangle -7500403 true true 135 180 150 195
Polygon -7500403 true true 150 90 165 105 270 105 285 90 285 45 285 30 270 15 165 15 150 30 150 90
Polygon -16777216 true false 150 30 285 30 285 45 150 45 150 30

customer-cash
false
0
Circle -7500403 true true 50 5 80
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Rectangle -7500403 true true 67 79 112 94
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Polygon -7500403 true true 45 90 0 150 15 180 75 105
Rectangle -7500403 true true 150 15 285 105
Circle -16777216 true false 195 45 30
Polygon -16777216 true false 210 75 195 90 225 90 210 75 210 60
Rectangle -16777216 false false 165 30 270 90
Circle -7500403 true true 165 270 30
Circle -7500403 true true 240 270 30
Polygon -7500403 false true 240 285 195 285 180 285 150 180 300 180 255 285
Line -7500403 true 150 195 300 195
Line -7500403 true 285 210 165 210
Line -7500403 true 165 225 285 225
Line -7500403 true 165 240 270 240
Line -7500403 true 180 255 270 255
Line -7500403 true 180 270 255 270
Line -7500403 true 195 285 195 180
Line -7500403 true 180 255 180 180
Line -7500403 true 165 240 165 180
Line -7500403 true 210 285 210 180
Line -7500403 true 225 285 225 180
Line -7500403 true 240 285 240 180
Line -7500403 true 255 270 255 180
Line -7500403 true 270 255 270 180
Line -7500403 true 285 225 285 180
Rectangle -7500403 true true 135 180 150 195

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
  <experiment name="1060 experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="customer-scowillingness-file-input">
      <value value="&quot;sco_usage.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-leaving-data-file-output">
      <value value="&quot;1060_cashier_output_01.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-picking-line-strategy">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-proces">
      <value value="&quot;NHPP_Inter_Thin&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-return-time">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-leaving-data-file-output">
      <value value="&quot;1060_transaction_output_01.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-servers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-max-line">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-min-line">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-sco-max-items">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-no">
      <value value="101"/>
      <value value="102"/>
      <value value="103"/>
      <value value="104"/>
      <value value="105"/>
      <value value="106"/>
      <value value="107"/>
      <value value="108"/>
      <value value="109"/>
      <value value="110"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-payment-file-input">
      <value value="&quot;1060_basket_size_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival-schedule-file-input">
      <value value="&quot;1060_cashiers_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats-reset-time">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-data-file-output">
      <value value="&quot;1060_customer_arrival_output_01.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-sco-servers">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-file-input">
      <value value="&quot;1060_customers_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="store-no">
      <value value="&quot;1060&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="4560 experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="customer-scowillingness-file-input">
      <value value="&quot;sco_usage.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-leaving-data-file-output">
      <value value="&quot;4560_cashier_output_01.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-picking-line-strategy">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arrival_proces">
      <value value="&quot;NHPP_Inter_Thin&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-return-time">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-leaving-data-file-output">
      <value value="&quot;4560_transaction_output_01.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-servers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-max-line">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-min-line">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-max-basket">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation">
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
    <enumeratedValueSet variable="customer-basket-payment-file-input">
      <value value="&quot;4560_basket_size_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival-schedule-file-input">
      <value value="&quot;4560_cashiers_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats-reset-time">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-data-file-output">
      <value value="&quot;4560_customer_arrival_output_01.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-sco-servers">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-file-input">
      <value value="&quot;4560_customers_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Store">
      <value value="&quot;4560&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="6161 experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="customer-scowillingness-file-input">
      <value value="&quot;sco_usage.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-leaving-data-file-output">
      <value value="&quot;6161_cashier_output_01.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-picking-line-strategy">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arrival_proces">
      <value value="&quot;NHPP_Inter_Thin&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-return-time">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-leaving-data-file-output">
      <value value="&quot;6161_transaction_output_01.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-servers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-max-line">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-min-line">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-max-basket">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation">
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
    <enumeratedValueSet variable="customer-basket-payment-file-input">
      <value value="&quot;6161_basket_size_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival-schedule-file-input">
      <value value="&quot;6161_cashiers_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats-reset-time">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-data-file-output">
      <value value="&quot;6161_customer_arrival_output_01.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-sco-servers">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-file-input">
      <value value="&quot;6161_customers_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Store">
      <value value="&quot;6161&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="6161 experiment 11 - 25" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="customer-scowillingness-file-input">
      <value value="&quot;sco_usage.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-leaving-data-file-output">
      <value value="&quot;6161_cashier_output_011.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-picking-line-strategy">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arrival_proces">
      <value value="&quot;NHPP_Inter_Thin&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-return-time">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-leaving-data-file-output">
      <value value="&quot;6161_transaction_output_011.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-servers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-max-line">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-min-line">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-max-basket">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation">
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
      <value value="21"/>
      <value value="22"/>
      <value value="23"/>
      <value value="24"/>
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-payment-file-input">
      <value value="&quot;6161_basket_size_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival-schedule-file-input">
      <value value="&quot;6161_cashiers_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats-reset-time">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-data-file-output">
      <value value="&quot;6161_customer_arrival_output_011.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-sco-servers">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-file-input">
      <value value="&quot;6161_customers_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Store">
      <value value="&quot;6161&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="sco-server-break-avg-time">
      <value value="68.06317"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-scowillingness-file-input">
      <value value="&quot;sco_usage.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-leaving-data-file-output">
      <value value="&quot;1060_cashier_output_49999.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-picking-line-strategy">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-return-time">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-leaving-data-file-output">
      <value value="&quot;1060_transaction_output_49999.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-servers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="server-transaction-avg-time">
      <value value="64.78542"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-sco-max-items">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockey-time-threshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-max-line">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-no">
      <value value="9999"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-min-line">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeing-time">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-proces">
      <value value="&quot;NHPP_Inter_Thin&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-server-transaction-avg-time">
      <value value="103.1093"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-payment-file-input">
      <value value="&quot;1060_basket_size_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="store-no">
      <value value="&quot;1060&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="server-break-avg-time">
      <value value="15.97272"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival-schedule-file-input">
      <value value="&quot;1060_cashiers_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats-reset-time">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-sco-servers">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-data-file-output">
      <value value="&quot;1060_customer_arrival_output_49999.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeing-lenght-threshold">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-file-input">
      <value value="&quot;1060_customers_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockey-items-threshhold">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1060 experiment + jockey" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="sco-server-break-avg-time">
      <value value="68.06317"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-scowillingness-file-input">
      <value value="&quot;sco_usage.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-leaving-data-file-output">
      <value value="&quot;1060_cashier_output_4101.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-picking-line-strategy">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-return-time">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-leaving-data-file-output">
      <value value="&quot;1060_transaction_output_4101.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-servers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="server-transaction-avg-time">
      <value value="64.78542"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-sco-max-items">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockey-time-threshold">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-max-line">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-no">
      <value value="101"/>
      <value value="102"/>
      <value value="103"/>
      <value value="104"/>
      <value value="105"/>
      <value value="106"/>
      <value value="107"/>
      <value value="108"/>
      <value value="109"/>
      <value value="110"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-min-line">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeing-time">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-proces">
      <value value="&quot;NHPP_Inter_Thin&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-server-transaction-avg-time">
      <value value="103.1093"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-payment-file-input">
      <value value="&quot;1060_basket_size_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="store-no">
      <value value="&quot;1060&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="server-break-avg-time">
      <value value="15.97272"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival-schedule-file-input">
      <value value="&quot;1060_cashiers_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats-reset-time">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-sco-servers">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-data-file-output">
      <value value="&quot;1060_customer_arrival_output_4101.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeing-lenght-threshold">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-file-input">
      <value value="&quot;1060_customers_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockey-items-threshhold">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="customer-scowillingness-file-input">
      <value value="&quot;sco_usage.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-server-break-avg-time">
      <value value="68.06317"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-leaving-data-file-output">
      <value value="&quot;1060_cashier_output_4101.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-picking-line-strategy">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockey-items-threshold">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-return-time">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-leaving-data-file-output">
      <value value="&quot;1060_transaction_output_4101.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockey-lenght-threshold">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-servers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockey-time-threshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-no">
      <value value="102"/>
      <value value="103"/>
      <value value="104"/>
      <value value="105"/>
      <value value="106"/>
      <value value="107"/>
      <value value="108"/>
      <value value="109"/>
      <value value="110"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-sco-max-items">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-max-line">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="server-transaction-avg-time">
      <value value="64.78542"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-min-line">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeing-time">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-proces">
      <value value="&quot;NHPP_Inter_Thin&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-server-transaction-avg-time">
      <value value="103.1093"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-payment-file-input">
      <value value="&quot;1060_basket_size_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="store-no">
      <value value="&quot;1060&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="server-break-avg-time">
      <value value="15.97272"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival-schedule-file-input">
      <value value="&quot;1060_cashiers_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats-reset-time">
      <value value="5901"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-sco-servers">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-data-file-output">
      <value value="&quot;1060_customer_arrival_output_4101.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-file-input">
      <value value="&quot;1060_customers_input.csv&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1060_no_jockey_run" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="sco-server-break-avg-time">
      <value value="68.06317"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-scowillingness-file-input">
      <value value="&quot;sco_usage.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-leaving-data-file-output">
      <value value="&quot;1060_cashier_output_01.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-picking-line-strategy">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockey-items-threshold">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-return-time">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-leaving-data-file-output">
      <value value="&quot;1060_transaction_output_01.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockey-lenght-threshold">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-servers">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockey-time-threshold">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-jockeying-switch">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-sco-max-items">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="server-transaction-avg-time">
      <value value="64.78542"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-max-line">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="simulation-no">
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
    <enumeratedValueSet variable="customer-jockeing-time">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-min-line">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-proces">
      <value value="&quot;NHPP_Inter_Thin&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sco-server-transaction-avg-time">
      <value value="103.1093"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-basket-payment-file-input">
      <value value="&quot;1060_basket_size_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="store-no">
      <value value="&quot;1060&quot;"/>
      <value value="&quot;4560&quot;"/>
      <value value="&quot;6161&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="server-break-avg-time">
      <value value="15.97272"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cashier-arrival-schedule-file-input">
      <value value="&quot;1060_cashiers_input.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats-reset-time">
      <value value="301"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-sco-servers">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-data-file-output">
      <value value="&quot;1060_customer_arrival_output_01.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="customer-arrival-file-input">
      <value value="&quot;1060_customers_input.csv&quot;"/>
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
