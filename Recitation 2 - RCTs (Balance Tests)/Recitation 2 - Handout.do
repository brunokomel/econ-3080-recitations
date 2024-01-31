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

foreach var of varlist * {
di "`var'" _col(20) "`: var l `var''" _col(50)  "`: val l `var''"
}


* Create means for catastrophic plan
matrix means_sd = J(11, 2, .) // this creates an empty matrix with eleven rows and two columns
local row = 1

foreach var of varlist female blackhisp age educper income1cpi hosp ghindx cholest systol mhi {
	summarize `var' if plantype == 4
	matrix means_sd[`row', 1] = r(mean)
	matrix means_sd[`row', 2] = r(sd)
	local row = `row'+1
}
                    
// the for loop above fills in the matrix

count if plantype_4 == 1
matrix means_sd[11, 1] = r(N) // here we're filling in the final element of the matrix with the number of observations

matrix rownames means_sd = female blackhisp age educper income1cpi hosp ghindx cholest systol mhi plantype
matrix list means_sd

#d ;
frmttable, statmat(means_sd) substat(1) varlabels sdec(4)
		   ctitle("", "Cata. mean") replace;
#d cr
                    
// With this last chunk of code, we're formatting the table. statmat(.) calls the matrix to use, 
//                    substat(1) means that each element will have one additional statistic that will be placed below it
//                    varlabels tells stata to use the labels matching the variable names
//                    sdec(4) tells stata to use 4 decimal points
//                    ctitle(. , . ) gives titles to each column
//                   replace tells stata to replace whatever table it had stored most recently. 
//                    Another option is "merge" (see below), which joins the current output with the most recently output table


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


******* Exercise
// Recreate Column 3 in table 1.3 from Mastering Metrics













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

foreach var of varlist * {
di "`var'" _col(20) "`: var l `var''" _col(50)  "`: val l `var''"
}

* Each school is a distinct data point, weighted by number of pupils
	keep if visit==981 
	collapse sex elg98 stdgap yrbirth wgrp* (count) np=pupid, by (sch98v1) 

	
// This will collapse the data and take the means of 'sex', 'elg98', etc. 
//and take the count of 'pupid' and store it in a variable called 'np'
	
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

 
 // using block(.) is a way to ensure that the sample is perfectly balanced on the variables on which you block
 
 
******* Exercise
// Recreate Panel A in Table I in Michel & Kremer

/// format table

use "https://github.com/brunokomel/econ-3080-recitations/raw/main/Recitation%201%20-%20RCTs%20(Balance%20Tests)/Miguel%20and%20Kremer/namelist.dta", clear 

keep if visit==981 
	collapse sex elg98 stdgap yrbirth wgrp* (count) np=pupid, by (sch98v1) 

label var sex "Male"
label var elg98 "Proportion girls"
label var stdgap "Grade"
label var yrbirth "Year of Birth"


matrix drop _all
mata: mata clear 

forvalues g = 1/3{

matrix mean_dep_`g' = J(4,2,.)
local i = 1


foreach var of varlist sex elg98 stdgap yrbirth{
    
    sum `var' [aw = np] if wgrp == `g'
    matrix mean_dep_`g'[`i',1] = r(mean)
    matrix rownames mean_dep_`g' = sex elg98 stdgap yrbirth 
    local i = `i' + 1
    
}

frmttable using "Table1.tex", statmat(mean_dep_`g') substat(1) ctitle("", "Group `g'") varlabels merge
    
}

******* Exercise
// Recreate Columns 1-3 in Table IX in Michel & Kremer

/// format table

use "https://github.com/brunokomel/econ-3080-recitations/raw/main/Recitation%201%20-%20RCTs%20(Balance%20Tests)/Miguel%20and%20Kremer/results/table9a.dta", clear 


foreach var of varlist * {
di "`var'" _col(20) "`: var l `var''" _col(50)  "`: val l `var''"
}

** Column 1 (Together)
**** TABLE 9, COLUMN 1	
#d ;
	sum prs [aw=obs] if  (t1~=. & elg98~=. & sch98v1~=. & mk96_s~=. & p1~=. & Istd2~=. & pop1_3km_updated~=.) ;
	regress prs t_any elg98 p1 mk96_s Y98sap* sap* Istd* Isem* [aw=obs] 
    if (t1~=. & elg98~=. & sch98v1~=. & mk96_s~=. & p1~=. & Istd2~=. & pop1_3km_updated~=.), 
    robust cluster(sch98v1) ;
#d cr

** Columns 2-3



