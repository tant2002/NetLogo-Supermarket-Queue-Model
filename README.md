# NetLogo_SupermarketQueueModel
 Simulation data driven model of queue system of typical supermarket's checkout zone. 

![alt text](/readme-images/model-interface.png)
![alt text](/readme-images/model-pitch3D.png)
## WHAT IS IT?
This is a complex model was for simulatation queue system of tipical supermarket's checkout zone. As opposed to traditional models based on queue theory, it let simulate and examine complex system with non-stationary characteristics i.e.  dynamically changed intensity  of customers arrival,  servers availability and / or service time distribution. 
Th mimmic proces accuratly, the model can be driven with historical data  containing  transactions intensities,  proportions of various basket sizes,  and  cashiers avalability in time. It let to examine various servers (checkouts) configurations in terms of quntity ond type (service and selfsevice). The model was created with an agent approach (ABS - Agent Based Simulation) however it also meets the  DES (Discret Events Simulation)  model definition.  

## HOW IT WORKS
System let simulate basic chracteristics of queue system in checkouts zone of tipical supermarket:  
### customer arrival patern
Depending on the settings, customer arrival can be simulated as: HPP (Homogenous Poisson Process) or NHPP (None-Homogenous Poisson Process). In first case, interarrival rate are sampled according to exponetial distribution with given and constant lambda ( = 1 /  arrival rate). In second case intensity function Lambda(t) is designated as an interpolation between the calibration points which historical data of  transactions counts for each full hour +/- 30 minuts.
### service time patern
Service time cold be drawn simply according theoretical (exponetial) distribution or designated in more comlex way in several steps.  Firsty basket-size of each customer is drown  on the basis empirical distrubutions, then service time  is calculated as the sum of the transaction and break times separatly for service and self-service servers (checkouts). The transaction times are generated according to power regression model equetion just like the break times for self-service. The break times for service checkouts – simply randomly sampled. The parameters for this models was estimated according to historical transactional data out of grocery supermarkets located in a large city in Southern Poland.    
### number of available servers
The number of servers (both service and self-service) is given as parameters. However the avialability of servers customers depends,  like in real supermarket,   on avialability cashiers.   

### queue discipline
First In First Served (FIFS) for both types of server. 
### number of queues



See description in article "Data-driven simulation modeling of the checkout process in supermarkets: Insights for decision support in retail operations"

## HOW TO USE IT
Depend on user decision, the model can be run with mode that use POS data or with inputs generated randomly according to theoretical distributions. To drive model with POS data  the values, parameters "customer-arrival-process", "customer-basket-payment", "cashier-arrival" need to be set on relevant values (see section Parameters bellow) and input files (see section POS data input files) need to be provide.  
### POS data input files
As example, the files contains historical data generated out POS (Point of Sale)  transactions data from supermarket located in southern Poland was provide. The date was extracted out with special procedures. Please note data range of all files need to be coherent. Files are in time series format and need NetLogo Time extension - see https://github.com/NetLogo/Time-Extension to be instaled in local enviroment of NetLogo. 
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
Value in days (1 day = 3600 ticks). In standard case simulation start date and time is determined by the earliest date/time in input fields or , in case inputs generated randomly according theoretical distributions,  the start date is 01-01-0001 00:00:01. The parameter simulation-start-day parameter let to shift starting of simulation by selected number of days. 
#### simulation-end-day
Value in days (1 day = 3600 ticks). In standard case simulation end date and time is determined by the latest date/time in input fields. In case inputs generated randomly according theoretical distributions,  the end date and time is  01-01-0001 00:00:01 + simulation-end-day value. 
#### customer-arrival-proces
This parameter determine customer arrivals to the system: value "HPP" means Homogenous Poisson Process with lambda value taken out of "customer-arrival-mean-rate" parameter; value "NHPP (POS)" means Non-Homogenous Poisson Process with lambda function determined by calibration points in customer-arrival-input-file-store1.csv input file. 
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
#### customer-picking-line-strategy
It determine the strategy picking line by the customer. Followed possibility are available: 0 the line is picked randomly, using a uniform distribution; 1 - the line with the lowest number of customers is picked, 2 - the line with the lowest number of items in all baskets in this line is picked; 3 the line with the lowest mean service time-implied expected waiting time is picked, i.e.the expected waiting time for each queue is calculated using the number of customers and the mean service time for service and self-service checkouts; 4 the line with the lowest power regression-implied expected waiting time is picked, i.e., the expected waiting time for each queue is calculated using the number of customers and the expected service and break times.
#### cashier-arrival
The parameter determine availability of cashiers in  store. The value "constant number" means that constant number of cashiers is determine by parameter "number-of-cashiers" from the beginning till end of simulation. The value "workschedule (POS)" mean that cashiers number is determine be workschedule defined in file "cashier-arrival-input-file-store1.csv" and parameter "cashier-work-time". Note that value "number-of-cashiers" greater than 0 add  cashiers to the quantities defined in "cashier-arrival-input-file-store1.csv" in whole period of simulation.
#### cashier-work-time
Value in minutes (ticks). See description of "cashier-arrival" parameter and "cashier-arrival-input-file-store1.csv" input file.
#### number-of-cashiers
See description of "cashier-arrival" parameter and "cashier-arrival-input-file-store1.csv" input file.
#### cashier-max-line
This parameter determine behaviour of cashiers in the system. In case average queue length in store exceed this value the available cashier trigger to go from backoffice to checkout (server).   
#### cashier-min-line 
This parameter determine behaviour of cashiers in the system. In case average queue length in store is less than this value the cashier close checkout (server). Note that,  cashier will remain in checkout until last customer from current queue will be served. Closed checkout means no new customer can join to the line assign to checkout. 
#### cashier-return-time
Value in minutes (ticks). This parameter determine time the cashier need to switch from backoffice to checkout. In other words: it takes "cashier-return-time"  minutes to go from backoffice to checkout and open it. 
#### number-of-servers
It determine number of checkouts that are available to be open on the store. 
#### single-queue?
It determine organisation of queues. Swith on mean single queue to all servers (checkouts), Swith off mean separate queue to each open checkouts.  
#### other parameters
distance-in-queue, distance-queue-server, distance-server-server, distance-sco-sco-h, distance-sco-sco-v determines spatial distances between customers in queues, servers, sco-servers, servers and customers. Although the spatial parameter do not  affect currently on the  model, they can be used for future extensions. 
### Plots
#### customers arrived cunt 
![alt text](/readme-images/plot-customers-arrived-count.png)
The plot shows number of customers arrived to the system within every minute of simulation.
#### customers served count
![alt text](/readme-images/plot-customers-served-count.png)
The plot shows number of customers that complete transaction within every minute of simulation. Data are presented in summarised form and with distinction between customers served on service (servers) and self-service (SCO-servers) checkouts.   
#### mean queue times
![alt text](/readme-images/plot-mean-queue-times.png)
The plot shows mean queue (waiting) time within every hour of simulation. Data are presented in summarised form and with distinction between customers served on service (servers) and self-service (SCO-servers) checkouts.
#### P(queue time > 5 )
![alt text](/readme-images/plot-probability.png)
The plot shows rate of customers that need to wait in queue more than 5 minutes (ticks). This is only for overview. To calculate  probability, results from many experiments need to be analysed.  
#### cashiers count 
![alt text](/readme-images/plot-cashiers-count.png)
The plot number of cashiers that are in system within every minute of simulaion. 
### Aggregated statistics
#### for customers 
![alt text](/readme-images/outputs-customers.png)
Statistics shows number of customers, percentage of customers, mean queue (waiting) time, mean queue (waiting) time only for customers that need to wait and probability (rate) of customers that have to wait more than 5 minutes (ticks). Data are presented for all customers and with distinction for service (servers) sel-service (SCO-server) checkouts.    
#### for cashiers
![alt text](/readme-images/outputs-cashiers.png)



## THINGS TO TRY


## NETLOGO FEATURES



## AUTHORSHIP
Created July 2020
Tomasz Antczak 


This work was partially supported by the Ministry of Science and Higher Education (MNiSW, Poland) core funding for statutory R&D activities.

This work is licensed .....

## CREDITS AND REFERENCES
