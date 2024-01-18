version 11.1
clear all
capture log close
set more off

use "Asiabarometer_falsification_dataset.dta", clear

log using "Asiabarometer_falsification_Table7.log", replace

***************************
*** Table 7, Cols 3 & 4 ***
***************************

xi: reg trust_local_govt distance_coast i.COUNTRY if missing(age)!=1 & missing(male)!=1 & missing(education)!=1 & missing(religion)!=1, cluster(distance_coast)
xi: reg trust_local_govt distance_coast age* male i.education i.religion i.COUNTRY, cluster(distance_coast)

log close




