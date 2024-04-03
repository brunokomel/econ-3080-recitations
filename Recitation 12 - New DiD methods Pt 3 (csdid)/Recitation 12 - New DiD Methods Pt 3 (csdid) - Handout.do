**************************************
*                                    *
*                                    *
*           Recitation 11            *
*                                    *
*                                    *
**************************************

// Date: 3/28/24
// By: Bruno Kömel

// Examples from: https://asjadnaqvi.github.io/DiD/docs/code/06_06_did_imputation/

clear

local units = 30
local start = 1
local end 	= 60

local time = `end' - `start' + 1
local obsv = `units' * `time'
set obs `obsv'

egen id	   = seq(), b(`time')  
egen t 	   = seq(), f(`start') t(`end') 	

sort  id t
xtset id t


set seed 20211222

gen Y 	   		= 0		// outcome variable	
gen D 	   		= 0		// intervention variable
gen cohort      = .  	// treatment cohort
gen effect      = .		// treatment effect size
gen first_treat = .		// when the treatment happens for each cohort
gen rel_time	= .     // time - first_treat

levelsof id, local(lvls) //randomly assigning observations into cohorts
foreach x of local lvls {
	local chrt = runiformint(0,5)	
	replace cohort = `chrt' if id==`x'
}

levelsof cohort , local(lvls)  
foreach x of local lvls {
	
	local eff = runiformint(2,10)
		replace effect = `eff' if cohort==`x'
			
	local timing = runiformint(`start',`end' + 20)	// 
	replace first_treat = `timing' if cohort==`x'
	replace first_treat = . if first_treat > `end'
		replace D = 1 if cohort==`x' & t>= `timing' 
}

replace rel_time = t - first_treat
replace Y = id + t + cond(D==1, effect * rel_time, 0) + rnormal()

xtline Y, overlay legend(off) // Here we can see the effects of staggered treatments

gen gvar = first_treat
recode gvar (. = 0)


******************************************
*                                        *
*                                        *
*            Naive Event-Study           *
*                                        *
*                                        *
******************************************

gen pre_10 = (rel_time == -10)
gen pre_9 = (rel_time == -9)
gen pre_8 = (rel_time == -8)
gen pre_7 = (rel_time == -7)
gen pre_6 = (rel_time == -6)
gen pre_5 = (rel_time == -5)
gen pre_4 = (rel_time == -4)
gen pre_3 = (rel_time == -3)
gen pre_2 = (rel_time == -2)
gen pre_1 = (rel_time == -1)
gen post_0 = (rel_time == 0)
gen post_1 = (rel_time == 1)
gen post_2 = (rel_time == 2)
gen post_3 = (rel_time == 3)
gen post_4 = (rel_time == 4)
gen post_5 = (rel_time == 5)
gen post_6 = (rel_time == 6)
gen post_7 = (rel_time == 7)
gen post_8 = (rel_time == 8)
gen post_9 = (rel_time == 9)
gen post_10 = (rel_time == 10)


replace post_0 = 0

reghdfe Y pre* post*, abs(id t) 

gen rel_time2 = rel_time 
replace rel_time2 = 0 if rel_time == .

eststo es1: reghdfe Y pre_* post_*, abs(id t) ,if (gvar == 0 | gvar == 24) & (rel_time2 > -11 & rel_time2 < 11 )


event_plot es1, default_look graph_opt(xtitle("Periods since the event") ytitle("Average effect") ///
	title("Naive Event Study") xlabel(-10(1)10)) stub_lag(post_#) stub_lead(pre_#) together

	
eststo es2: reghdfe Y pre_* post_*, abs(id t) ,if  (rel_time2 > -11 & rel_time2 < 11 )


event_plot es2, default_look graph_opt(xtitle("Periods since the event") ytitle("Average effect") ///
	title("Naive Event Study") xlabel(-10(1)10)) stub_lag(post_#) stub_lead(pre_#) together

******************************************
*                                        *
*                                        *
*                  csdid                 *
*                                        *
*                                        *
******************************************

// ssc install csdid, replace
// ssc install drdid, replace
// ssc install event_plot, replace
// ssc install bacondecom, replace
reghdfe Y D, abs(id t) //This is running a two-way fixed effect regression with cohort and time fixed effects (abs stands for "absorve" that's because the fixed effects model absorves the movement within each category)

csdid Y, ivar(id) time(t) gvar(gvar) notyet // here ivar is the panel identifier (e.g. country), time is something like the 'year' or 'month' (the running variable); gvar is the variable identifying groups/cohorts , notyet requests that the model use only observations never treated and not yet treated in the control group

estat event, window(-10 10) estore(cs) // This tells Stata to store only the coefficients related to the 10 years prior and the 10 years after the treatments


event_plot cs, default_look graph_opt(xtitle("Periods since the event") ytitle("Average effect") ///
	title("csdid") xlabel(-10(1)10)) stub_lag(Tp#) stub_lead(Tm#) together

	
// OR for a different event study plot
csdid Y, ivar(id) time(t) gvar(gvar) notyet 

estat event, window(-10 10) 

csdid_plot , title("Event-Study")
	
// what csdid does is it uses a robust methodology (optionally non-parametric, I think) to get the ATT estimate (average treatment effect on the treated) but while only considering "good" designs. By good we mean either those that identify ATT's correctly, or those that can be used for testing parallel trends. Most importatnly, it avoids estimating bad Did designs (i.e. those that use previously treated units as the control group)


// guide for plotting these together: https://github.com/borusyak/did_imputation/blob/main/five_estimators_example.do
event_plot  es2 cs, default_look ciplottype(rcap) noautolegend graph_opt(xtitle("Periods since the event") ytitle("Average effect") ///
	title("Event Study Comparison") xlabel(-10(1)10) legend(order(1 "Naive" 3 "Callaway-Sant'Anna") rows(3) region(style(none)) ) ) ///
	 stub_lag(post_# Tp# ) stub_lead(pre_# Tm#) together 
	

******************************
*      Another example       *
******************************

use https://friosavila.github.io/playingwithstata/drdid/mpdta.dta, clear

    //Estimation of all ATTGT's using Doubly Robust IPW (DRIPW) estimation method
	
csdid lemp lpop , ivar(countyreal) time(year) gvar(first_treat) method(dripw)
	
estat event, window(-3 3) estore(cs)
csdid_plot , title("Event-Study")

event_plot cs, default_look graph_opt(xtitle("Periods since the event") ytitle("Average effect") ///
	title("csdid") xlabel(-3(1)3)) stub_lag(Tp#) stub_lead(Tm#) together

******************************************
*                                        *
*                                        *
*            In-Class Example            *
*                                        *
*                                        *
******************************************

*From Andrew Goodman-Bacon

 use"https://raw.githubusercontent.com/LOST-STATS/LOST-STATS.github.io/master/Model_Estimation/Data/Event_Study_DiD/bacon_example.dta", clear

******************************************
*                                        *
*             Data Cleaning              *
*                                        *
****************************************** 
 
// Just a reminder of how to get the ATE:
// ssc install reghdfe, replace
reghdfe asmrs post, abs(stfips year) //Instead of regressing on the interaction, you could regress on the "post" variable and get the same result (because of the TWFE)
 
gen nfd_missing=_nfd
 
gen exp=year-_nfd
*make sure untreated units are included
*but get no dummies (by giving them "-1")

recode exp (.=-1) (-1000/-6=-6) (12/1000=12) // This will convert all missing values to -1, all values between -1000 and -6 to be -6, and all values between 12 and 1000 to be 12.

char exp[omit] -1
xi i.exp, pref(_T) // xi provides a convenient way to convert categorical variables to dummy or indicator variables when you fit a model. pref() sets the prefix of the string


// Now the event study specification
reghdfe asmrs _Texp_1-_Texp_5 _Texp_7-_Texp_19 pcinc asmrh cases,abs(stfips year) //excluding period 6 as the ommitted period


// And now let's change this _nfd variable so we can use it in our csdid command:
gen _nfd2=_nfd
replace _nfd2=0 if _nfd==.



******************************************
*              Exercise 1                *
******************************************   


// use csdid to calculate the corrected coefficient (create a window going from 6 periods before to 10 periods after)



//plot the csdid plot


// Create a Naive event study estimator for this setting, and plot it alongside the csdid results





// Tabulate these results so they look nice.












