# NetLogo_SupermarketQueueModel
 Queue model of supermarket's checkout zone ABM

![alt text](/readme-images/model-interface.png)
## WHAT IS IT?

This a complex model for simulaton queues in supermarkets with service and selfservice checkout.  It can use sets of data extracted out of POS (Point of Sale) tranactional data to mimic queue system. As opposed to traditional models based on queue theory it let simulate and examine complex queue system with dynamicly changed parmaeters. The  

## HOW IT WORKS


## HOW TO USE IT
Depend on user decision, the model can be run with mode that use POS data or with inputs generated randomly according to theoretical distributions. To drive model with POS data  the values, parameters "customer-arrival-proces", "customer-basket-payment", "cashier-arrival" need to be set on relevant values (see section Parameters bellow) and input files (see section POS data input files) need to be provide.  
### POS data input files
The files contains data generated out POS transactions data. As example, transactional data out of supermarket loceted in southern Poland was provide. The date was extracted out with special procedures. Please note data range of each file need to be coherent.    
#### customer-arrival-input-file-store1.csv
This file contain data that are necessary to generate arrivals of customers to checkouts in supermarket. It's assumed that arrivals of cusstomers follows poisson process (non homogenous) and expected value of arrived customers in each hour is close to number of transaction in each hour.  
In the model expected value of arrivals (lambda function of poisson process) is equel to the linear interploatin between calibration points. The calibration points are number of transaction (transaction count) for each hour. This data can be extracted out of POS data.  The data in file contain following fields (columns):
"timestamp" - full hour + 30 min , "customer-transaction-count" - number of transactions within time window <full hour, full hour + 1>.  
#### customer-basket-payment-input-file-store1.csv
This file contain data which are necessary to dice basket size and method of payment of customers. Although the drawing of the payment method does not  affect curently on the  the model, it can be used for future extensions. The structure of is as follow:
"timestamp" - full hour + 30 min , the rest of fields countain count of transactions for each basket size (articles in transaction ) and method of payment within time window full hour, full hour + 1. Names of this fields are decoded as follow:   0 + basket size,  for method of payment cash , 1000 + basket size for non-cash methods of payment: "1"
,"2", "3", ...,"1001, "1002", "1003"... .
#### cashier-arrival-input-file-store1.csv
This file contains workschedule of cashiers. It determines number of cashiers that arrive to work in each full-hour of simulation. Please note that length shift (time cashier spent in store) is determinated by parameter 'cashier-work-time' (see description bellow). The structure of the file is as follow: "timestamp" - full hour of cashier's arrival to store, "number-of-cashiers" - number of cashiers that arrive to store on particular time. 
### Parameters
![alt text](/readme-images/model-parameters.png)
#### simulation-start-day
In standard case simlation start date and time is determinated by the earliest date/time in input fieles or , in case inputs generated randomly according theoretical distributions,  the start date is 01-01-0001 00:00:01. The parameter simulation-start-day parameter let to shift starting of simulation by selected number of days. 
#### simulation-end-day
In standard case simlation end date and time is determinated by the latest date/time in input fieles. In case inputs generated randomly according theoretical distributions,  the end date and time is  01-01-0001 00:00:01 + simulation-end-day value. 
#### customer-arrival-proces
This parameter determine customer arrivals to the system: value "HPP" means homogenous poisson process with lambda value taken out of "customer-arrival-mean-rate" parameter; value "NHPP (POS)" means non-homogenous poisson process with lamda function determineted by calibration points in customer-arrival-input-file-store1.csv input file. 
#### customer-arrival-mean-rate
see description of "customer-arrival-proces" parameter
#### max-customers
In case ofcustomer arrivals with "HPP" this parameter can be use to limit capacity of system in terms of number of customers. 
#### customer-basket-payment
This parameter indicate the way of determination basket size and payment method. Value "Poisson\Binomial" means: basket size is drawn with poisson distribution and  parameter lambda equel to parameter  "customer-basket-mean-size";  payment method with binomial distribution and probanility value out of parameter "customer-cash-payment-rate".  
"ECDF (POS)" value means that basket size and method of payment is drawn according to empirical distributions determinated for each hour of simulation out of POS data (file customer-basket-payment-input-file-store1.csv)
#### customer-basket-mean-size
see description of "customer-basket-payment" parameter 
#### customer-cash-payment-rate
see description of "customer-basket-payment" parameter 
#### customer-picking-line-strategy
It determine the strategy picking line by the customer. Followed possibility are available: 0 the line is picked randomly, using a uniform distribution; 1 - the line with the lowest number of customers is picked, 2 - the line with the lowest number of items in all baskets in this line is picked; 3 the line with the lowest mean service time-implied expected waiting time is picked, i.e.the expected waiting time for each queue is calculated using the number of customers and the mean service time for service and self-service checkouts; 4 the line with the lowest power regression-implied expected waiting time is picked, i.e., the expected waiting time for each queue is calculated using the number of customers and the expected service and break times.
#### cashier-arriaval
The parameter determine availability of cashiers in  store. The value "constant number" mean that constant number of cashiers  
"workschedule (POS)"

## THINGS TO TRY


## NETLOGO FEATURES



## AUTHORSHIP
Created July 2020
Tomasz Antczak 


This work was partially supported by the Ministry of Science and Higher Education (MNiSW, Poland) core funding for statutory R&D activities.

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

## CREDITS AND REFERENCES
