# NetLogo_SupermarketQueueModel
 Queue model of supermarket's checkout zone ABM

![alt text](/readme-images/model-interface.png)
## WHAT IS IT?

This a complex model for simulaton queues in supermarkets with service and selfservice checkout.  It can use sets of data extracted out of POS (Point of Sale) tranactional data to mimic queue system in Store. As opposed to traditional models based on queue theory it let simulate and examine complex queue system with dynamicly changed parmaeters. 

## HOW IT WORKS


## HOW TO USE IT
Depend on user decision the model can be rune with mode that use POS data or with inputs generated randomly. 
### POS data input files
The files contains data generated out POS transaction files. For purpose of study, transactional data that was taken from supermarket loceted in southern Poland. The date was extracted out with special procedures.   
#### customer-arrival-input-file-store1.csv
This file contain data that are necessary to generate arrivals of customers to checkouts in supermarket. It's assumed that arrivals of cusstomers follows poisson process (non homogenous) and expected value of arrived customers in each hour is close to number of transaction in each hour.  
In the model expected value of arrivals (lambda function of poisson process) is equel to the linear interploatin between calibration points. The calibration points are number of transaction (transaction count) for each hour. This data can be extracted out of POS data.  The file contain following fields:
"timestamp" - full hour + 30 min ,
"customer-transaction-count" - number of transactions within time window full hour + full hour + 1.  
#### customer-basket-payment-input-file-store1.csv
This file contain data which are necessary to dice basket size and 
"timestamp" - full hour + 30 min ,
"1"
"2"
"3" 
....
"1001
"1002"
"1003"
.....
## THINGS TO TRY


## NETLOGO FEATURES



## AUTHORSHIP
Created July 2020
Tomasz Antczak 


This work was partially supported by the Ministry of Science and Higher Education (MNiSW, Poland) core funding for statutory R&D activities.

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

## CREDITS AND REFERENCES
