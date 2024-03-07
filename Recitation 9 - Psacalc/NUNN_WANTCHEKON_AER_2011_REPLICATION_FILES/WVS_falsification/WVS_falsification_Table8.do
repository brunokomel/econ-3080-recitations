version 10.1
capture clear
capture log close
set mem 100m
set more off

log using "WVS_falsification_Table8.log", replace

use "WVS_falsification_dataset.dta"

*************************
*** Table 8, Cols 3-5 ***
*************************

/* Chile (1990); Norway (1990); Sweden (1990); Great Britain (1990); Northern Ireland (1990) */
* Col 3
xi: reg inter_group_trust near_dist i.s025 if africa==0 & missing(occupation)!=1 & missing(age)!=1 & missing(male)!=1 & missing(urban)!=1, cluster(near_dist) 
* Col 4
xi: reg inter_group_trust near_dist i.occupation male* age* urban_dum i.s025 if africa==0, cluster(near_dist) 
* Col 5 - Nigeria
xi: reg inter_group_trust near_dist i.occupation male* age* if africa==1, cluster(near_dist) 

log close

