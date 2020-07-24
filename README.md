# NetLogo_SupermarketQueueModel
 Simulation data driven model of queue system of typical supermarket's checkout zone. 

![alt text](/readme-images/model-interface.png)

## WHAT IS IT?
This is a complex model for simulatation queue system of tipical supermarket's checkout zone. As opposed to traditional models based on queue theory, it let simulate and examine complex system with non-stationary characteristics i.e.  dynamically changed intensity  of customers arrival,  servers availability and / or service time distribution. 
Th mimmic proces accuratly, the model can be driven with historical data (time series)  containing  transactions intensities,  proportions of  transactions for various combination basket sizes/methods of payment  and  cashiers avalability (workschedule). It let to examine  configurations in terms of quntity ond type of servers (service and selfsevice checkouts). The model was created with an agent approach (ABS - Agent Based Simulation) however it also meets DES (Discret Events Simulation)  model definition.  

## HOW IT WORKS
System let to simulate queue system with followed characteristics:  
### customer arrival patern
Depending on the settings, customer arrival can be simulated as: HPP (Homogenous Poisson Process) or NHPP (None-Homogenous Poisson Process). In first case, interarrival rate are sampled according to exponetial distribution with given and constant lambda ( = 1 /  arrival rate). In second case intensity function Lambda(t) is designated as an interpolation between the calibration points which historical data of  transactions counts for each full hour +/- 30 minuts.
### service time patern
Service time cold be drawn simply according theoretical (exponetial) distribution or designated in more comlex way in several steps. In the second approach: firsty basket-size of each customer is drown  on the basis empirical distrubutions (historical data) , then service time  is calculated as the sum of the transaction and break times separatly for service and self-service servers (checkouts). The transaction times are compute according to power regression model equetion just like the break times for self-service. The break times for service checkouts – simply randomly sampled. The parameters for this models was estimated according to historical transactional data out of grocery supermarkets located in a large city in Southern Poland and are hardcoded within procedures 'customer-server-service-time-draw-regression' and customer-sco-server-service-time-draw-regression'     
### number of available servers
The number of servers (both service and self-service) is given as parameters. However the avialability of servers customers depends - like in real supermarket -  on number of  cashiers present in store. The latter is dependent on workschedule (historical data) and planned work time given as parameter. Because in real environments, cashiers can perform another task during periods of low trafic, the a mechanism for leaving the checkouts and entering the backoffice zone has been implemented. Cashier is triger: to close checkout  or to open checkout when the mean queu lenght fall bellow or excced given thresholds respectivelly. It's alsso assumed that changeover from backoffice to checkout of cashier takes time (set as parameter). 
### queue discipline
First In First Served (FIFS) for both types of server. 
### number of queues
The system can mimic both multi or single queeue to the service checkouts. For self-service checkouts, only single queue is possible. 
Since the system assumes multiple queues, various methods of queue picking have been implemented. Although the way of picking is an individual decision of each client, the model assumes that each cashiers uses the same strategy. It is possible to simulate 5 different strategies (0 - 4) that reflect different levels of customer knowledge about the state of the system: from strategy 0 that reflect no information (= pure random choice of line) to strategy 4 which assume konowing expected waiting times in each queue (= queue with minumum expexted waiting time is picked). Strategies 0 - 3  are between - see description of 'customer-picking-queue-strategy' paramaeter for more details.          

Historical time serires can extracted out of transactional data that are colected by most of POS (Point of Sales) system -  see work "Data-driven simulation modeling of the checkout process in supermarkets: Insights for decision support in retail operations" for more details. 

![alt text](/readme-images/model-pitch3D.png)

## HOW TO USE IT
Depend on user decision, the model can be run with mode that use POS data or with inputs generated randomly according to theoretical distributions. To drive model with POS data  the values, parameters "customer-arrival-process", "customer-basket-payment", "cashier-arrival" need to be set on relevant values (see section Parameters bellow) and input files (see section POS data input files) need to be provide.  

### POS data input files
As example, the files contains historical data generated out POS (Point of Sale)  transactions data from supermarket located in southern Poland was provide. The date was extracted out with special procedures. Please note data range of all files need to be coherent. Files are in time series format and need NetLogo Time extension - see https://github.com/NetLogo/Time-Extension to be instaled in local enviroment of NetLogo. Instruction for extensions in NetLogo can be find on http://ccl.northwestern.edu/netlogo/docs/extensions.html.
#### customer-arrival-input-file-store1.csv
This file contain data that are necessary to generate arrivals of customers to checkouts in supermarket. It's assumed that arrivals of customers follows Poisson process (non homogenous) and expected value of arrived customers in each hour is close to number of transaction in each hour.  
In the model expected value of arrivals (lambda function of Poisson process) is equal to the linear interpolation between calibration points. The calibration points are number of transaction (transaction count) for each hour. This data can be extracted out of POS data.  The data in file contain following fields (columns):
"timestamp" - full hour + 30 min , "customer-transaction-count" - number of transactions within time window <full hour, full hour + 1>.  
#### customer-basket-payment-input-file-store1.csv
This file contain data which are necessary to dice basket size and method of payment of customers. Although the drawing of the payment method does not  affect currently on the model, it can be used for future extensions. The structure of is as follow:
"timestamp" - full hour + 30 min , the rest of fields contain count of transactions for each basket size (articles in transaction ) and method of payment within time window full hour, full hour + 1. Names of this fields are decoded as follow:   0 + basket size,  for method of payment cash , 1000 + basket size for non-cash methods of payment: "1"
,"2", "3", ...,"1001, "1002", "1003"... .
#### cashier-arrival-input-file-store1.csv
This file contains workschedule of cashiers. It determines number of cashiers that arrive to work in each full-hour of simulation. Please note that length shift (time cashier spent in store) is determined by parameter 'cashier-work-time' (see description below). The structure of the file is as follow: "timestamp" - full hour of cashier's arrival to store, "number-of-cashiers" - number of cashiers that arrive to store on particular time. 
### Parameters
![alt text](/readme-images/model-parameters.png)
#### simulation-start-day
Value in days (1 day = 3600 ticks). In standard case simulation start date and time is determined by the earliest date/time in input fieles or , in case inputs generated randomly according theoretical distributions,  the start date is 01-01-0001 00:00:01. The parameter simulation-start-day parameter let to shift starting of simulation by selected number of days. 
#### simulation-end-day
Value in days (1 day = 3600 ticks). In standard case simulation end date and time is determined by the latest date/time in input fields. In case inputs generated randomly according theoretical distributions,  the end date and time is  01-01-0001 00:00:01 + simulation-end-day value. 
#### customer-arrival-proces
This parameter determine customer arrivals to the system: value "HPP" means Homogenous Poisson Process with lambda value taken out of "customer-arrival-mean-rate" parameter (lambda = 1/customer-arrival-mean-rate) ; value "NHPP (POS)" means Non-Homogenous Poisson Process with lambda function determined by calibration points in customer-arrival-input-file-store1.csv input file. 
#### customer-arrival-mean-rate
See description of "customer-arrival-process" parameter
#### max-customers
In case of customer arrivals with "HPP" this parameter can be used to limit capacity of system in terms of number of customers. 
#### customer-basket-payment
This parameter indicate the way of determination basket size and payment method. Value "Poisson\Binomial" means: basket size is drawn with poisson distribution and  parameter lambda equal to parameter  "customer-basket-mean-size";  payment method with binomial distribution and probability value out of parameter "customer-cash-payment-rate".  
"ECDF (POS)" value means that basket size and method of payment is drawn according to empirical distributions determined for each hour of simulation out of POS data (file customer-basket-payment-input-file-store1.csv)
#### customer-basket-mean-size
See description of "customer-basket-payment" parameter 
#### customer-cash-payment-rate
See description of "customer-basket-payment" parameter 
#### customer-picking-queue-strategy
It determine the strategy picking line by the customer. Followed possibility are available: 0 the line is picked randomly, using a uniform distribution; 1 - the line with the lowest number of customers is picked, 2 - the line with the lowest number of items in all baskets in this line is picked; 3 the line with the lowest mean service time-implied expected waiting time is picked, i.e.the expected waiting time for each queue is calculated using the number of customers and the mean service time for service and self-service checkouts; 4 the line with the lowest power regression-implied expected waiting time is picked, i.e., the expected waiting time for each queue is calculated using the number of customers and the expected service and break times.
#### cashier-arrival
The parameter determine availability of cashiers in  store. The value "constant number" means that constant number of cashiers is determine by parameter "number-of-cashiers" from the beginning till end of simulation. The value "workschedule (POS)" mean that cashiers number is determine be workschedule defined in file "cashier-arrival-input-file-store1.csv" and parameter "cashier-work-time". Note that value "number-of-cashiers" greater than 0 add  cashiers to the quantities defined in "cashier-arrival-input-file-store1.csv" in whole period of simulation. 
#### cashier-work-time
Value in minutes (ticks). See description of "cashier-arrival" parameter and "cashier-arrival-input-file-store1.csv" input file.
#### number-of-cashiers
See description of "cashier-arrival" parameter and "cashier-arrival-input-file-store1.csv" input file.
#### cashier-max-line
This parameter determine behaviour of cashiers in the system. In case average queues length in store exceed this value the available cashier trigger to go from backoffice to checkout (server).   
#### cashier-min-line 
This parameter determine behaviour of cashiers in the system. In case average queue length in store is less than this value the cashier close checkout (server). Note that,  cashier will remain in checkout until last customer from current queue will be served. Closed checkout means no new customer can join to the line assign to checkout. 
#### cashier-return-time
Value in minutes (ticks). This parameter determine time the cashier need to switch from backoffice to checkout. In other words: it takes "cashier-return-time"  minutes to go from backoffice to checkout and open it. 
#### number-of-servers
It determine number of checkouts that are available to be open on the store. 
#### single-queue?
It determine organisation of queues. Swith on mean single queue to all servers (checkouts), Swith off mean separate queue to each open checkouts. 
#### server-service-time-model
The choicer indicate how service time on servers is calculated. Value "EXPONENTIAL" means that service time is sampled out of theoretical (exponetial) distibution with lambda parameter taken out of 'server-service-time-expected'. Value "Reg. model (POS)" means service times are compute according to power regression - see section 'service time patern' above.
#### server-service-time-expected
The parameter is used for two purposes. Firstly it isued as input (Lambda) parameter for sampling service time with theoretical distribution- see desription 'server-service-time-model'. Secondly, it is used as mean service time for calculation expected service time in case of strategy 3 of picking the line by customers - see desription 'customer-picking-queue-strategy' 

#### sco-server-service-time-model
The choicer indicate how service time on sco-servers (self-service chekouts) is calculated. Value "EXPONENTIAL" means that service time is sampled out of theoretical (exponetial) distibution with lambda parameter taken out of 'server-service-time-expected'. Value "Reg. model (POS)" means service times are compute according to power regression - see section 'service time patern' above.
#### sco-server-service-time-expected
The parameter is used for two purposes. Firstly it isued as input (Lambda) parameter for sampling service time with theoretical distribution- see desription 'sco-server-service-time-model'. Secondly, it is used as mean service time for calculation expected service time in case of strategy 3 of picking the line by customers - see desription 'customer-picking-queue-strategy' 

#### other parameters
distance-in-queue, distance-queue-server, distance-server-server, distance-sco-sco-h, distance-sco-sco-v determines spatial distances between customers in queues, servers, sco-servers, servers and customers. Although the spatial parameter do not  affect currently on the  model, they can be used for future extensions. 
### Plots
#### customers arrived cunt 
![alt text](/readme-images/plot-customers-arrived-count.png)
The plot shows number of customers arrived to the system within every minute of simulation.
#### cashiers count 
![alt text](/readme-images/plot-cashiers-count.png)
The plot number of cashiers that are in system within every minute of simulaion. The staistic is calculated for every full minute (tick) of simulation. 
#### servers utilization 
![alt text](/readme-images/plot-servers-utilization.png)
The plot shows percentage of used server/sco-servers out of all of used server/sco-servers. The staistic is calculated for every full minute (tick) of simulation. 

#### customers served count
![alt text](/readme-images/plot-customers-served-count.png)
The plot shows number of customers that complete transaction within every minute of simulation. Data are presented in summarised form and with distinction between customers served on service (servers) and self-service (SCO-servers) checkouts.   
#### mean queue times
![alt text](/readme-images/plot-mean-queue-times.png)
The plot shows mean queue (waiting) time within every hour of simulation. Data are presented in summarised form and with distinction between customers served on service (servers) and self-service (SCO-servers) checkouts.
#### P(queue time > 5 )
![alt text](/readme-images/plot-probability.png)
The plot shows rate of customers that need to wait in queue more than 5 minutes (ticks). This is only for overview. To calculate  probability, results from many repeated experiments need to be complete.  
### Aggregated statistics
#### for customers 
![alt text](/readme-images/outputs-customers.png)
Statistics shows 'number of customers', 'percentage of customers', 'mean queue (waiting) time', mean queue (waiting) time only for customers that need to wait and probability (rate) of customers that have to wait more than 5 minutes (ticks). Data are presented for all customers and with distinction for service (servers) sel-service (SCO-server) checkouts.    
#### for cashiers
![alt text](/readme-images/outputs-cashiers.png)
Stitistic shows: 'total time' (means sum of time that each cashier spent in system), 'total time on server' (means sum of time each cashier was on server), 'changoevers' (number of times all cashiers shift betwen servers and backoffice), 'total working time' (sume of 'time on server' and multiplication of 'changovers' and value of 'cashier-return-time') and 'utilization' (ratio of 'total working time' and  'total time')     

#### for servers
![alt text](/readme-images/outputs-servers.png)
'total time' is multiplaction of simulation time and number of servers/ sco-servers. 'service time' is sum of times of serving customers on servers/ sco-servers.  'utilization' is ratio of 'service time' and  'total time'.



## THINGS TO TRY


## NETLOGO FEATURES



## AUTHORSHIP
Created July 2020
Tomasz Antczak 


This work was partially supported by the Ministry of Science and Higher Education (MNiSW, Poland) core funding for statutory R&D activities.

This work is licensed .....

## CREDITS AND REFERENCES
