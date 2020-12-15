# NetLogo Supermarket Queue Model
NetLogo's data driven queue system model of typical supermarket's checkout zone. 

![alt text](/readme-images/model-interface.png)

## WHAT IS IT?
This is a model for simulation queue system of typical supermarket's checkout zone in NetLogo. As opposed to traditional models based on queue theory, it let simulate and examine complex system with non-stationary characteristics i.e.  dynamically changed intensity  of customers arrival,  servers availability and / or service time distribution. 
To mimic process accurately, the model can be driven with historical data (time series)  containing:  intensity of the transactions,  proportions of  transactions for various combination basket sizes/methods of payment  and  cashiers availability (workschedule). It let to examine various checkout zone configurations in terms of quantity and type of servers (service and self-service checkouts) and overview basic performance measures. The model was created with an agent approach (ABS - Agent Based Simulation) however it also meets DES (Discrete Events Simulation)  model definition.  

## HOW IT WORKS
System let to simulate queue system with followed characteristics:  
### customer arrival pattern
Depending on the settings, customer arrival can be simulated as: HPP (Homogenous Poisson Process) or NHPP (None-Homogenous Poisson Process). In first case, inter-arrival rate are sampled according to exponential distribution with given and constant lambda ( = 1 /  arrival rate). In second case intensity function Lambda(t) is designated as an interpolation between the calibration points which are POS (Point of Sale) transactions counts for each hour of available data. Simulation of NHPP is implemented with thinning algorithm.  
### service time pattern
Service time can be sampled according theoretical (exponential) distribution or designated in more complex way in several steps. In the second approach: firstly basket-size of each customer is drawn on the basis of empirical (historical data) or theoretical (Poisson) distribution. Secondly service time  is calculated as the sum of the transaction and break times separately for service and self-service servers (checkouts). The transaction times are compute according to power regression model equation just like the break times for self-service. In this regression model explanatory variable is basket size. The break times for service checkouts – simply randomly sampled. The parameters for this models was estimated according to historical data out of grocery supermarkets located in a large city in Southern Poland and are hardcoded within procedures 'customer-server-service-time-draw-regression' and customer-sco-server-service-time-draw-regression'     
### number of available servers
The number of servers (both service and self-service) is given as parameters. However the availability of servers depends - like in real supermarket -  on number of  cashiers present in store. The latter is dependent on workschedule (historical data) and planned work time given as parameter. Because in real environments, cashiers can perform other than checkout tasks in periods of low traffic, the a mechanism for leaving the checkouts and entering the backoffice zone has been implemented. Cashier is trigger: to close or to open checkout when the mean queue length fall below or exceed given thresholds respectively. It is also assumed that changeover from backoffice to checkout of cashier takes time (set as parameter). 
### queue discipline
First In First Served (FIFS) for both types of server. 
### number of queues
The system can mimic both multi or single queue to the service checkouts. For self-service checkouts, only single queue is possible. 
Since the system assumes multiple queues, various methods of queue picking have been implemented. Although the way of picking is an individual decision of each client, the model assumes that each cashier uses the same strategy. It is possible to simulate 5 different strategies (0 - 4) that reflect different levels of customer knowledge about the state of the system: from strategy 0 that reflect no information (pure random choice of queue) to strategy 4 which assumes ability to estimate expected waiting times in each queue (= queue with minimum expected waiting time is picked). Strategies 0 - 3  are between - see description of 'customer-picking-queue-strategy' parameter for more details.          
### customer's jockeying
Model can mimic jockeying of customers between the queues. The rule of jockeyng is implemented to be depend on 3 values. First parameter (strategy) decide whenever the customer is able to jockey or not, second parameter - distance -  decide abbout distance (between lines) within the customer is able to jockey and third parameter threshold decide about minimal difrence between current posiont of customer in queue and lenght of queue to jockeying.   

Historical time series can extracted out of transactional data that are collected by most of POS (Point of Sale) system -  see work "Data-driven simulation modelling of the checkout process in supermarkets: Insights for decision support in retail operations" for more details. 

![alt text](/readme-images/model-pitch3D.png)

## HOW TO USE IT
The main code of the model can be found in main directory in file SupermarketQueueModel_version_x_x.nlogo.  
The model use two Netlogo extensions that need to be lto be installed in local environment of NetLogo.
 - Time extension ( see https://github.com/NetLogo/Time-Extension ). 
 - The RNGS extension (see https://github.com/cstaelin/RNGS-Extension).
Instruction for extensions in NetLogo can be find on http://ccl.northwestern.edu/netlogo/docs/extensions.html.
Due to exc installations, the model can only be launched in the local netlogo environment (no possible to use Netlogo Web)  
Depend on user decision, the model can be run with mode that use POS (Point of Sale) historical data or with inputs generated randomly according to theoretical distributions. To drive model with POS data  the values, parameters "customer-arrival-process", "customer-basket-payment", "cashier-arrival", 'server-service-time-model' and 'sco-server-service-time-model' need to be set on relevant values (see section Parameters bellow) and input files (see section POS data input files) need to be provide. 

### POS data input files
As example, the files contained historical data generated out POS  transactional data from supermarket located in southern Poland was provided. However,  it is possible to use any data. Please note data range of all files need to be coherent. Files are in time series format and need NetLogo Time extension ( see https://github.com/NetLogo/Time-Extension ). The path to each file need to be indicated as parameter. 
#### [customer-arrival-input-file-store1.csv](customer-arrival-input-file-store1.csv)
This file contain data that are necessary to generate arrivals of customers to checkouts in supermarket. It's assumed that arrivals of customers Non Homogenous Poisson Process (NHPP) and expected value of arrived customers in each hour is close to number of transaction in each hour. In the model expected value of arrivals (lambda function in NHPP) is equal to the linear interpolation between calibration points. The calibration points are number of transaction (transactions count) for each hour .  The data in file contains following fields (columns):
"timestamp" = full hour +/- 30 min , "customer-transaction-count" = number of transactions within time window <full hour, full hour + 1>.  
#### [customer-basket-payment-input-file-store1.csv](customer-basket-payment-input-file-store1.csv)
This file contain data which are necessary to sample basket size and method of payment of customers.  Although the drawing of the payment method does not  affect currently on the model, it can be used for future extensions. The structure of file is as follow:
"timestamp" = full hour  , the rest of fields contain count of transactions for each basket size (articles in transaction ) and method of payment within time window <full hour, full hour + 1>. Names of this fields are decoded as follow:   0 + basket size,  for method of payment cash , 1000 + basket size for non-cash methods of payment: "1"
,"2", "3", ...,"1001, "1002", "1003"... .
#### [cashier-arrival-input-file-store1.csv](cashier-arrival-input-file-store1.csv)
This file contains workschedule of cashiers. It determines number of cashiers that arrive to work in each full-hour of simulation. This file specifies only the time of cashiers arrivals. The length of shifts (time cashiers spent in store) is determined by parameter 'cashier-work-time' (see description below). The structure of the file is as follow: "timestamp" = time of cashier's arrival to store, "number-of-cashiers" = number of cashiers that arrive to store on this time. 
### Parameters
![alt text](/readme-images/model-parameters.png)
#### simulation-start-day
Value in days (1 day = 1440 ticks). In case of data driven simulation start date and time is determined by the earliest date/time in input files.  In case inputs generated randomly according theoretical distributions,  the start date is 01-01-0001 00:00:01. The parameter simulation-start-day  let to shift starting of simulation by selected number of days. Example earliest date and time in input files is 01-02-2018 00:50:01, the parameter value 3 shift start the simulation to  04-02-2018 00:50:01.
#### simulation-end-day
Value in days (1 day = 1440 ticks). In standard case simulation end date and time is determined by the latest date/time in input fields. In case inputs generated randomly according theoretical distributions,  the end date and time is  01-01-0001 00:00:01 + simulation-end-day value. 
#### customer-arrival-process
This parameter determine customer arrivals to the system: value "HPP" means Homogenous Poisson Process with lambda value taken out of "customer-arrival-mean-rate" parameter (lambda = 1/customer-arrival-mean-rate) ; value "NHPP (POS)" means Non-Homogenous Poisson Process with lambda function determined by calibration points in customer-arrival-input-file-store1.csv input file. 
#### customer-arrival-mean-rate
See description of "customer-arrival-process" parameter
#### max-customers
In case of customer arrivals with "HPP" this parameter can be used to limit capacity of system in terms of number of customers. 
#### customer-basket-payment
This parameter indicate the way of determination basket size and payment method. Value "Poisson\Binomial" means: basket size is drawn with Poisson distribution and  parameter lambda equal to parameter  "customer-basket-mean-size";  payment method with binomial distribution and probability value out of parameter "customer-cash-payment-rate". "ECDF (POS)" value means that basket size and method of payment is drawn according to empirical distributions determined for each hour of simulation out of POS data (file customer-basket-payment-input-file-store1.csv)
#### customer-basket-mean-size
See description of "customer-basket-payment" parameter 
#### customer-cash-payment-rate
See description of "customer-basket-payment" parameter 
#### customer-picking-queue-strategy
It determine the strategy of picking line by the customer. Followed possibility are available: 0 the line is picked randomly, using a uniform distribution; 1 - the line with the lowest number of customers is picked, 2 - the line with the lowest number of items in all baskets in this line is picked; 3 the line with the lowest mean service time-implied expected waiting time is picked, i.e. the expected waiting time for each queue is calculated using the number of customers and the mean service time for service and self-service checkouts; 4 the line with the lowest power regression-implied expected waiting time is picked, i.e., the expected waiting time for each queue is calculated using the number of customers and the expected service and break times.
Value 99  means that will be sampled out of 0 - 4 according to uniform distribution for every agent customer separately.
#### customer-sco-item-threshold
The parameter determine whenever customer can or cannot use sco-servers. Customers with basket size that exceed the value of the parameter are referred to the service checkouts (servers). Only if none of service checkout is open,  customers with basket size that exceed thershold are referred to sco-servers. This parameter let to simulate i.e. "expres self-service checkouts" scenarios.     
#### customer-jockeying-strategy
It determine the strategy of jockeying by customer. Followed possibility are available: 0 - customer does not jockey in any case, 1 - customer jockey if  his  position in line exceeds the line length that is within jockeying distance by the jockeying threshold. Value 99 means that strategy 1 or 2 will sampled ccording to uniform distribution for every agent customer separately.
#### customer-jockeying-distance  
It determines the distance (between lines on both side) in which the customer is willing to jockey. Please note that parameter distance-server-server determine the distance between lines. So the jockeying distance must take account of the distance between lines. In other words this parameters must reflect differences between coordinates of servers. 
Possible value is 1 2 3 4. Value 99 means that distance will be sampled out of 1 - 4 according to uniform distribution for every agent customer separately. 
####  customer-jockeying-threshold
Minimal difference between actual position of customer in lines and length of the length of the queue to which the customer is willing to jockey. Value 99  means that threshold will be sampled out of 1 - 4 according to uniform distribution for every agent customer separately.

#### cashier-arrival
The parameter determine availability of cashiers in  store. The value "constant number" means that constant number of cashiers is determine by parameter "number-of-cashiers" from the beginning till end of simulation. The value "workschedule (POS)" means that cashiers number is determine be workschedule defined in file "cashier-arrival-input-file-store1.csv" and parameter "cashier-work-time". Note that value "number-of-cashiers" greater than 0 add  cashiers to the quantities defined in "cashier-arrival-input-file-store1.csv" in whole period of simulation. 
#### cashier-work-time
Value in minutes (ticks). See description of "cashier-arrival" parameter and "cashier-arrival-input-file-store1.csv" input file. Example value 240 means that cashier work in 4-hour shift starting from date/ time from  cashier-arrival-input-file-store1.csv" file. 
#### number-of-cashiers
See description of "cashier-arrival" parameter and "cashier-arrival-input-file-store1.csv" input file.
#### cashier-max-line
This parameter determine behaviour of cashiers in the system. In case average queues length in model exceeds this value the available cashier trigger to go from backoffice to checkout (server).   
#### cashier-min-line 
This parameter determine behaviour of cashiers in the system. In case average queue length in store is less than this value, the cashier close checkout (server). Note, that  cashier will remain in checkout until last customer from current queue will be served. Closed checkout means no new customer can join to the queue assign to checkout. 
#### cashier-return-time
Value in minutes (ticks). This parameter determine time the cashier need to switch from backoffice to checkout. In other words: it takes "cashier-return-time"  minutes to go from backoffice to checkout and open it. 
#### customer-arrival-input-file
The parameter contain path to the file with data necessary generate customer arrivals - see description of customer-arrival-input-file-store1.csv above.
#### customer-basket-payment-input-file
The parameter contain path to the file with data necessary assign basket size and  method of payment to the customers – see description of customer-basket-payment-input-file-store1.csv file above.
#### cashier-arrival-input-file
The parameter contain work schedule of cashiers - see description of cashier-arrival-input-file-store1.csv file above.
#### customer-output-directory
It determines the directory in which the result files with customers data will be saved. The files contain data separately for each agent - customer. To avoid problems with processing big size file one simulation may generate many files. The file example name  "customers-output-file_1_0_17_121245576AM13-gru-2020.csv" - first three numbers in the name means picking-line-strategy, jockeying-strategy and experiment number chosen in simulation. Last symbols in file's name contain system date & time of file creation.  
#### cashier-output-directory
It determines the directory in which the result files with cashier data will be saved. The files contain data separately for each agent - cashier. To avoid problems with processing big size file one simulation may generate many files. The file example name  "customers-output-file_1_0_17_121245576AM13-gru-2020.csv" - first three numbers in the name means picking-line-strategy, jockeying-strategy and experiment number chosen in simulation. Last symbols in file's name contain system date & time of file creation. 
#### number-of-servers
It determine number of checkouts that are available to be open on the store. 
#### single-queue?
It determine organisation of queues for servers. Switch-on mean single queue to all servers (checkouts), Switch-off mean separate queue to each open checkouts. 
#### server-service-time-model
The choicer indicate how service time on servers is calculated. Value "EXPONENTIAL" means that service time is sampled out of theoretical (exponential) distribution with lambda parameter taken out of 'server-service-time-expected'. Value "Reg. model (POS)" means service times are compute according to power regression - see section 'service time pattern' above.
#### server-service-time-expected
The parameter is used for two purposes. Firstly it is used as input (Lambda) parameter for sampling service time with theoretical distribution- see description of parameter 'server-service-time-model'. Secondly, it is used as mean service time for calculation expected service time - in strategy 3 of picking the line by customers - see description 'customer-picking-queue-strategy' 

#### sco-server-service-time-model
The choicer indicate how service time on sco-servers (self-service checkouts) is calculated. Value "EXPONENTIAL" means that service time is sampled out of theoretical (exponential) distribution with lambda parameter taken out of 'sco-server-service-time-expected'. Value "Reg. model (POS)" means service times are compute according to power regression - see section 'service time pattern' above.
#### sco-server-service-time-expected
The parameter is used for two purposes. Firstly it is used as input (Lambda) parameter for sampling service time with theoretical distribution- see description of parameter 'sco-server-service-time-model. Secondly, it is used as mean service time for calculation expected service time in strategy 3 of picking the line by customers - see description 'customer-picking-queue-strategy' 

#### other parameters
distance-in-queue, distance-queue-server, distance-server-server, distance-sco-sco-h, distance-sco-sco-v determines spatial distances between customers in queues, servers, sco-servers, servers and customers. Although the spatial parameter do not  affect currently on the  model, they can be used for future extensions. 
#### experiment
This parameter let to mark experiments. It is counter that is saved in output files.

### Plots
#### customers arrived cunt 
![alt text](/readme-images/plot-customers-arrived-count.png)

The plot shows number of customers arrived to the system within every minute of simulation.
#### cashiers count 
![alt text](/readme-images/plot-cashiers-count.png) 

The plot number of cashiers that are in system. The statistic is calculated for every full minute (tick) of simulation. 
#### servers utilization 
![alt text](/readme-images/plot-servers-utilization.png) 

The plot shows percentage of used server/sco-servers out of all of used server/sco-servers. The statistic is calculated for every full minute (tick) of simulation. 
#### customers served count
![alt text](/readme-images/plot-customers-served-count.png) 

The plot shows number of customers that complete transaction within every hour of simulation. Data are presented in summarised form and with distinction between customers served on service (servers) and self-service (sco-servers) checkouts.   
#### mean queue times
![alt text](/readme-images/plot-mean-queue-times.png) 

The plot shows mean queue (waiting) time within every hour of simulation. Data are presented in summarised form and with distinction between customers served on service (servers) and self-service (sco-servers) checkouts.
#### P(queue time > 5 )
![alt text](/readme-images/plot-probability.png) 

The plot shows rate of customers that need to wait in queue more than 5 minutes (ticks). 

### Aggregated statistics
#### for customers 
![alt text](/readme-images/outputs-customers.png) 

Statistics shows 'number of customers', 'percentage of customers', 'mean queue (waiting) time', mean queue time (only for customers that need to wait) and rate of customers that have to wait more than 5 minutes (ticks). Data are presented for all customers and with distinction for service (servers) self-service (sco-server) checkouts.    
#### for cashiers
![alt text](/readme-images/outputs-cashiers.png) 

Statistics show: 'total time' (means sum of time that each cashier spent in system), 'total time on server' (means sum of time each cashier was on server), 'changeovers' (number of times all cashiers shift between servers and backoffice), 'total working time' (sum of 'time on server' and multiplication of 'changeovers' and value of 'cashier-return-time') and 'utilization' (ratio of 'total working time' and  'total time')     

#### for servers
![alt text](/readme-images/outputs-servers.png) 

'total time' is multiplication of simulation time and number of servers/ sco-servers. 'service time' is sum of times of serving customers on servers/ sco-servers.  'utilization' is ratio of 'service time' and  'total time'.

## THINGS TO TRY
### Simple M/M/1 model
If only one server is set in  system and theoretical (exponential) distribution of customer and service time is set, then it is simple M/M/1 queue model. A simulation of a sufficiently long period of time should cause the 'mean queue time' statistic to aim for theoretical values calculated using a formula known from queue theory. 
### Historical data driven experiments 
Base of historical data it is possible to mimic queues in  checkout zone of real supermarket.
#### Picking queue strategy
Try various picking line strategy to see how proper referral of customers to pick 'right' queue can affect on performance of system measured by waiting time or/and  utilization of cashiers. 
#### Servers / SCO-servers configuration variants
By change the configuration of system (quantity of various types of servers) it is possible to check the impact various investments variants on work demand (utilization of cashiers).

## AUTHORSHIP
Created July 2020
Tomasz Antczak 
email: tomasz.antczak@pwr.edu.pl

## HOW TO CITE
If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.
Antczak  T. (2020). NetLogo Supermarket Queue Model https://github.com/tant2002/NetLogo-Supermarket-Queue-Model 

## CREDITS AND REFERENCES
Wilensky  U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Sheppard C., Railsback S.,  Kelter J. NetLogo time extensions, https://github.com/NetLogo/Time-Extension 

The RNGS extension updated to NetLogo 5.0 https://github.com/cstaelin/RNGS-Extension

Cizek P. Hardle W. Weron R. (Eds.) (2011). Statistical Tools for Finance and Insurance (2nd ed.), Springer

Antczak T., Weron R., (2019),  Point of sale (POS) data from a supermarket: Transactions and cashier operations, Data 4 (2) (2019) 67.

