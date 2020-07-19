# NetLogo_SupermarketQueueModel
 Queue model of supermarket's checkout zone ABM

![alt text](/readme-images/model-interface.png)
## WHAT IS IT?

This a complex model for simulaton queues in supermarkets with service and selfservice checkout.  It can use sets of data extracted out of POS (Point of Sale) tranactional data to mimic queue system. As opposed to traditional models based on queue theory it let simulate and examine complex queue system with dynamicly changed parmaeters. The  

## HOW IT WORKS


## HOW TO USE IT
Depend on user decision the model can be rune with mode that use POS data or with inputs generated randomly. 
### POS data input files
The files contains data generated out POS transaction files. For purpose of study, transactional data that was taken from supermarket loceted in southern Poland. The date was extracted out with special procedures. Please note    
#### customer-arrival-input-file-store1.csv
This file contain data that are necessary to generate arrivals of customers to checkouts in supermarket. It's assumed that arrivals of cusstomers follows poisson process (non homogenous) and expected value of arrived customers in each hour is close to number of transaction in each hour.  
In the model expected value of arrivals (lambda function of poisson process) is equel to the linear interploatin between calibration points. The calibration points are number of transaction (transaction count) for each hour. This data can be extracted out of POS data.  The data in file contain following fields (columns):
"timestamp" - full hour + 30 min ,
"customer-transaction-count" - number of transactions within time window full hour + full hour + 1.  
#### customer-basket-payment-input-file-store1.csv
This file contain data which are necessary to dice basket size and method of payment of customers. Although the drawing of the payment method does not  affect curently on the  the model, it can be used for future extensions. The structure of is as follow:
"timestamp" - full hour + 30 min , the rest of fields countain count of transactions for each basket size (articles in transaction ) and method of payment within time window full hour, full hour + 1. Names of this fields are decoded as follow:   0 + basket size,  for method of payment cash , 1000 + basket size for non-cash methods of payment: "1"
,"2", "3", ...,"1001, "1002", "1003"... .
#### cashier-arrival-input-file-store1.csv
This file contains workschedule of cashiers. It determines number of cashiers that arrive to work in each full-hour of simulation. Please note that length shift (time cashier spent in store) is determinated by parameter 'cashier-work-time' (see description bellow). The structure of the file is as follow: "timestamp" - full hour of cashier's arrival to store, "number-of-cashiers" - number of cashiers that arrive to store on particular time. 
### Parameters
![alt text](/readme-images/model-parameters.png)

## THINGS TO TRY


## NETLOGO FEATURES



## AUTHORSHIP
Created July 2020
Tomasz Antczak 


This work was partially supported by the Ministry of Science and Higher Education (MNiSW, Poland) core funding for statutory R&D activities.

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

## CREDITS AND REFERENCES
