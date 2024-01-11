// Demonstration of Randomize in Stata // 
/* 
By: Bruno Kömel
Date: 10 Jan 2024
*/

// Install randomize package // 
//ssc install randomize

**********************************
*                                *
*                                *
*        Rand Experiment         * 
*                                *
*                                *
**********************************

use "https://github.com/brunokomel/econ-3080-recitations/raw/main/Recitation%201%20-%20RCTs%20(Balance%20Tests)/rand_initial_sample.dta", clear


* Plan types:
/* 
	Plan type 1 = "Free plan"
	Plan type 2 = "Deductible plan"
	Plan type 3 = "Coinsurance plan"
	Plan type 4 = "Catastrophic plan" or "No Insurance"
*/

* Create means for catastrophic plan
matrix means_sd = J(11, 2, .)
local row = 1

foreach var of varlist female blackhisp age educper income1cpi hosp ghindx cholest systol mhi {
	summarize `var' if plantype == 4
	matrix means_sd[`row', 1] = r(mean)
	matrix means_sd[`row', 2] = r(sd)
	local row = `row'+1
}

count if plantype_4 == 1
matrix means_sd[11, 1] = r(N)

matrix rownames means_sd = female blackhisp age educper income1cpi hosp ghindx cholest systol mhi plantype
matrix list means_sd

#d ;
frmttable, statmat(means_sd) substat(1) varlabels sdec(4)
		   ctitle("", "Cata. mean") replace;
#d cr

* Create regression output
* Column 2: Deductible plan compared to catastrophic plan
matrix deduct_diff = J(11, 2, .)
local row = 1

foreach var of varlist female blackhisp age educper income1cpi hosp ghindx cholest systol mhi {
	reg `var' plantype_1 plantype_2 plantype_3, cl(famid)
	matrix deduct_diff[`row', 1] = _b[plantype_2]
	matrix deduct_diff[`row', 2] = _se[plantype_2]
	local row = `row'+1
}
count if plantype_2 == 1
matrix deduct_diff[11, 1] = r(N)

#d ;
frmttable, statmat(deduct_diff) varlabels sdec(4)
		   ctitle("Deduct - cata.") substat(1) merge;
#d cr

* Column 3: Coinsurance plan compared to catastrophic plan
matrix coins_diff = J(11, 2, .)
local row = 1

foreach var of varlist female blackhisp age educper income1cpi hosp ghindx cholest systol mhi {
	reg `var' plantype_1 plantype_2 plantype_3, cl(famid)
	matrix coins_diff[`row', 1] = _b[plantype_3]
	matrix coins_diff[`row', 2] = _se[plantype_3]
	local row = `row'+1
}

count if plantype_3 == 1
matrix coins_diff[11, 1] = r(N)

#d ;
frmttable, statmat(coins_diff) varlabels sdec(4)
		   ctitle("Coins - cata") substat(1) merge;
#d cr

* Column 4: Coinsurance plan compared to catastrophic plan
matrix free_diff = J(11, 2, .)
local row = 1

foreach var of varlist female blackhisp age educper income1cpi hosp ghindx cholest systol mhi {
	reg `var' plantype_1 plantype_2 plantype_3, cl(famid)
	matrix free_diff[`row', 1] = _b[plantype_1]
	matrix free_diff[`row', 2] = _se[plantype_1]
	local row = `row'+1
}

count if plantype_1 == 1
matrix free_diff[11, 1] = r(N)

#d ;
frmttable, statmat(free_diff) varlabels sdec(4)
		   ctitle("Free - cata.") substat(1) merge;
#d cr

* Column 5: Any insurance plan compared to catastrophic plan
matrix any_diff = J(11, 2, .)
local row = 1

foreach var of varlist female blackhisp age educper income1cpi hosp ghindx cholest systol mhi {
	reg `var' any_ins, cl(famid)
	matrix any_diff[`row', 1] = _b[any_ins]
	matrix any_diff[`row', 2] = _se[any_ins]
	local row = `row'+1
}

count if any_ins == 1
matrix any_diff[11, 1] = r(N)

#d ;
frmttable, statmat(any_diff) varlabels sdec(4)
		   ctitle("Any - cata.") substat(1) merge;
#d cr


**********************************
*                                *
*                                *
*        Miguel & Kremer         * 
*                                *
*                                *
**********************************

// First example: From Miguel & Kremer (ECTA, 2004) // 
* Note: You can obtain the dataset and replication code from https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/28038. The .dta file namelist is needed for this exercise. 

** Remember to set your working directory correctly using the "cd..." command

**cd "~/Documents/Pitt/Year_2/TA - Econ 3080/Recitations/Recitation 3"

* Start with Namelist data
use "https://github.com/brunokomel/econ-3080-recitations/raw/main/Recitation%201%20-%20RCTs%20(Balance%20Tests)/namelist.dta", clear 

* Each school is a distinct data point, weighted by number of pupils
	keep if visit==981 
	collapse sex elg98 stdgap yrbirth wgrp* (count) np=pupid, by (sch98v1) 

**** TABLE 1: PANEL A
bys wgrp: summ sex elg98 stdgap yrbirth [aw=np] //bysort treatment group, summarise these variables 

foreach var in sex elg98 stdgap yrbirth { 
	regress `var' wgrp1 wgrp2 [aw=np] 
} 


// Use Stata's Randomize command to generate groups // 
// ssc install randomize
randomize, groups(3) generate(grp)

*Note: We can check the balance of this grp variable as follows: 
bys grp: summ sex elg98 stdgap yrbirth [aw=np] //bysort treatment group, summarise these variables 

gen grp1 = (grp == 1) //creating dummies for each group category
gen grp2 = (grp == 2)

foreach var in sex elg98 stdgap yrbirth { 
	regress `var' grp1 grp2 [aw=np] 
} 

// Another example: sysuse nlsw88 // 
clear
sysuse nlsw88.dta //another preloaded dataset (similar to auto.dta), but from the National Longitudinal Survey of Women in 88. 

gen black = (race == 2)

randomize, groups(2) generate(grp)
bysort grp: sum age black married collgrad 

randomize, groups(2) block(black) generate(grp_alt)
bysort grp_alt: sum age black married collgrad 



******* Exercise
// Recreate Panel A in Table I in Miguel & Kremer

/// format table
use namelist.dta, clear 

keep if visit==981 
	collapse sex elg98 stdgap yrbirth wgrp* (count) np=pupid, by (sch98v1) 

label var sex "Male"
label var elg98 "Proportion girls"
label var stdgap "Grade"
label var yrbirth "Year of Birth"

matrix drop _all
mata: mata clear

*Columns 1-3
forvalues g = 1/3{

matrix mean_dep_`g' = J(4,2,.)
local i = 1	

foreach var of varlist sex elg98 stdgap yrbirth{
	
	summ `var' [aw=np] if wgrp == `g'
	matrix mean_dep_`g'[`i',1] = r(mean)
	matrix rownames mean_dep_`g' =  sex elg98 stdgap yrbirth
	local i = `i' + 1
}
frmttable, statmat(mean_dep_`g') substat(1) ctitle("","Group `g'")  varlabels merge
}

* Column 4

matrix control_diff_1 = J(4,2,.)
local row = 1

foreach var in sex elg98 stdgap yrbirth { 
	regress `var' wgrp1 wgrp2 [aw=np] 
	matrix control_diff_1[`row',1] = _b[wgrp1]
	matrix control_diff_1[`row',2] = _se[wgrp1]
	local row = `row' + 1
} 

matrix list control_diff_1

frmttable, statmat(control_diff_1) substat(1) ctitle("Group 1 - Group 3") merge

* Column 5

matrix control_diff_2 = J(4,2,.)
local row = 1

foreach var in sex elg98 stdgap yrbirth { 
	regress `var' wgrp1 wgrp2 [aw=np] 
	matrix control_diff_2[`row',1] = _b[wgrp2]
	matrix control_diff_2[`row',2] = _se[wgrp2]
	local row = `row' + 1
} 

matrix list control_diff_2

frmttable, statmat(control_diff_2) substat(1) ctitle("Group 2 - Group 3")  merge






