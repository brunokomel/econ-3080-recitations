********************************************
*                                          *
*                                          *
*              Recitation 4                *
*                                          *
*                                          *
********************************************
// script by: Bruno Kömel (kinda)

* Remember to change your directories
global data  "/Users/brunokomel/Documents/Pitt/Year_2/TA - Econ 3080/Recitations/Recitation 4/Recitation 4 - Handout/Data"
global working  "/Users/brunokomel/Documents/Pitt/Year_2/TA - Econ 3080/Recitations/Recitation 4/Recitation 4 - Handout/Working"

set scheme gg_tableau

clear all
set more off
eststo clear
capture version 13

cd "${data}"

/* Import data */ 
*I honestly don't know how this works
infile SHEET CHAIN CO_OWNED STATE SOUTHJ CENTRALJ NORTHJ PA1 PA2      ///
       SHORE NCALLS EMPFT EMPPT NMGRS WAGE_ST INCTIME FIRSTINC BONUS  ///
       PCTAFF MEALS OPEN HRSOPEN PSODA PFRY PENTREE NREGS NREGS11     ///
       TYPE2 STATUS2 DATE2 NCALLS2 EMPFT2 EMPPT2 NMGRS2 WAGE_ST2      ///
       INCTIME2 FIRSTIN2 SPECIAL2 MEALS2 OPEN2R HRSOPEN2 PSODA2 PFRY2 ///
       PENTREE2 NREGS2 NREGS112 using "public.dat", clear

/* Label the state variables and values */
label var STATE "State"
label define state_labels 0 "PA" 1 "NJ"
label values STATE state_labels

/* Calculate FTE employement */
gen FTE  = EMPFT  + 0.5 * EMPPT  + NMGRS
label var FTE  "FTE employment before"
gen FTE2 = EMPFT2 + 0.5 * EMPPT2 + NMGRS2
label var FTE2 "FTE employment after"

gen dif = FTE - FTE2

/* Calculate means */
tabstat FTE FTE2, by(STATE) stat(mean semean)

****
// Editing the data so we can match the paper
expand 2 //This creates a dublciate of each observation and it appends it to the bottom of the dataset

gen id = _n //Since the data is compiled with one observation per "sheet" or store, I want to separate them between prior and post treatment

gen after = 1 if id > _N/2  // creating the "after" treatment indicator
replace after = 0 if id <= _N/2

tab STATE, gen(state) // this will create indicator variables for each state

rename state2 nj // naming one variable after New Jersey

gen njafter = after*nj // creating an interaction term

gen fte = FTE // I don't like capital letters and I want this new "fte" variable to disagreggate the FTE and FTE2 variables into different observations

replace fte = FTE2 if after ==1 

cd "$working"

save working_data, replace


** Now we can do Diff-in-Diff analyses:

reg fte nj after njafter, robust // The traditional specification

reg fte njafter nj after, cluster(SHEET) // Clustering Standard Errors by store

reg diff nj after nj#after, robust // An alternative way to run this regression

reg dif nj after njafter, robust // A little cleaner way to do the same thing as above

//ssc install diff
diff fte, t(nj) p(after)


preserve 

use working_data
qui reg fte nj after njafter, robust

collapse (mean) fte, by(nj after)
save working_data_did, replace

twoway (connected fte after if nj ==1, color(blue)) (connected fte after if nj ==0, color(red)), xline(0.5)  ///
  legend(label(1 NJ - Treatment) label(2 PA - Control)) 
save working_data_did, replace
  
restore

// So what can we do????














/// Difference-in-differences Exercise /// 

use "https://github.com/brunokomel/econ-3080-recitations/raw/main/Recitation%202%20-%20DiD/panel101.dta", clear 
//reference: slides by Torres-Reyna @ https://www.princeton.edu/~otorres/DID101.pdf

tab year //from 1990 to 1999 
tab country //7 countries

// 1. Create a "post" variable which is equal to 1 if the observation takes place on or after 1994 (careful with missing values)

// 2. Create a treated variable which is equal to 1 for countries 4, 5, 6, and 7.


// 3. Create a variable for the interaction term

// 4. Estimate the DiD coefficient using the 'diff' command

// 5. Estimate the DiD coefficient using the regression command

//  6. Repeat part 5, but this time use the '##' option.

// 7. Plot the DiD coefficeint as we did earlier, using the twoway command. (Be sure to usee preserve & restore)



