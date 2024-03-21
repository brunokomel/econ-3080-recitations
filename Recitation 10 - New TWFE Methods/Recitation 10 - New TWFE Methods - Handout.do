**************************************
*                                    *
*                                    *
*           Recitation 10            *
*                                    *
*                                    *
**************************************

// Date: 3/21/24
// By: Bruno Kömel

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
	local chrt = runiformint(0,2)	// This defines the number of cohorts
	replace cohort = `chrt' if id==`x'
}

levelsof cohort , local(lvls)  
foreach x of local lvls {
	
	local eff = runiformint(2,10) // Creates a random treatment effect between 2 and 10
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
*              bacondecomp               *
*                                        *
*                                        *
******************************************

// ssc install bacondecomp, replace
reghdfe Y D, abs(cohort t) //This is running a two-way fixed effect regression with cohort and time fixed effects (abs stands for "absorb" that's because the fixed effects model absorves the movement within each category)

bacondecomp Y D cohort, stub(Bacon_) robust ddetail

// Notice that we don't need to include the time variable. This is because we converted the dataset to a panel with the xtset command.

// So the way the bacondecomp command works is that you call the outcome and then the treatment and cohort variables, then you have come options. stub() will create variables with the decomposition results
// and ddetail will provide additional details

// List the "stub" variables/tables you created
list Bacon_T Bacon_C Bacon_B Bacon_cgroup if !mi(Bacon_T)
 


 
******************************************
*                                        *
*                                        *
*               stackedev                *
*                                        *
*                                        *
******************************************


use https://github.com/joshbleiberg/stacked_event/raw/main/state_policy_effect.dta, clear

drop ref pre* post*

tab rel, gen(rel_)

rename rel_1 pre7
rename rel_2 pre6
rename rel_3 pre5
rename rel_4 pre4
rename rel_5 pre3
rename rel_6 pre2
rename rel_7 pre1
rename rel_8 post0
rename rel_9 post1
rename rel_10 post2
rename rel_11 post3
rename rel_12 post4
rename rel_13 post5

// label variable pre8 "Pre 8"
label variable pre7 "Pre 7"
label variable pre6 "Pre 6"
label variable pre5 "Pre 5"
label variable pre4 "Pre 4"
label variable pre3 "Pre 3"
label variable pre2 "Pre 2"
label variable pre1 "Pre 1"
label variable post0 "Base Year"
label variable post1 "Post 1"
label variable post2 "Post 2"
label variable post3 "Post 3"
label variable post4 "Post 4"
label variable post5 "Post 5"


replace post0 = 0

// Run the stacked event study
stackedev outcome  pre7 pre6 pre5 pre4 pre3 pre1 pre2 post0 post1 post2 post3 post4 post5 , cohort(treat_year) time(year)  never_treat(no_treat) unit_fe(state) clust_unit(state) covariates(cov)

// Notice that this command is pretty much a regression command. All you have to specify is are the cohort, time, never treated, unit fixed effects, cluster unit, and desired covariates (separately from the leads and lags)

event_plot, default_look graph_opt(xtitle("Periods since the event") ytitle("Average effect") xlabel(-8(1)5) ///
		title("stackedev")) stub_lag(post#) stub_lead(pre#)  together 




******************************************
*                                        *
*                                        *
*            In-Class Example            *
*                                        *
*                                        *
******************************************

*From Andrew Goodman-Bacon

 use"https://raw.githubusercontent.com/LOST-STATS/LOST-STATS.github.io/master/Model_Estimation/Data/Event_Study_DiD/bacon_example.dta", clear

 *****************************************
*                                        *
*             Data Cleaning              *
*                                        *
****************************************** 
 

gen treated=_nfd!=.
 
reg asmrs i.treated##i.post

 
gen interaction=post*treated

reg asmrs interaction post treated 


xtreg asmrs i.treated##i.post i.year, i(stfips)  fe // This is saying run a fixed effects model "fe" using i(sstfips) as the fixed effect. In order to add the second FE use i.year (note you could flip the two, and do i.stfips and wirte i(year) after the comma)
 

 tab year, gen(Y) //tabluates and generates dummy variables for the years
 tab stfip, gen(st)  //tabluates and generates dummy variables for the states
 
 // ssc install reghdfe, replace
 reghdfe asmrs interaction, abs(stf year) // This is a much nicer command, with prettier  output
 reg asmrs inter  st2-st49 Y2-Y33 //again, an alternative, but it looks horrible
 
 
reghdfe asmrs post, abs(stfips year) //Instead of regressing on the interaction, you could regress on the "post" variable and get the same result
 
gen nfd_missing=_nfd
 
gen exp=year-_nfd
*make sure untreated units are included
*but get no dummies (by giving them "-1")

recode exp (.=-1) (-1000/-6=-6) (12/1000=12) // This will convert all missing values to -1, all values between -1000 and -6 to be -6, and all values between 12 and 1000 to be 12.

char exp[omit] -1
xi i.exp, pref(_T) // xi provides a convenient way to convert categorical variables to dummy or indicator variables when you fit a model. pref() sets the prefix of the string

reghdfe asmrs _Texp_1-_Texp_5 _Texp_7-_Texp_19 pcinc asmrh cases,abs(stfips year) //excluding period 6 as the ommitted period


gen coef=.
gen se=. 

forvalues i=1(1)5{
	
	replace coef=_b[_Texp_`i'] if _Texp_`i'==1
	
	replace se=_se[_Texp_`i'] if _Texp_`i'==1
	
}


forvalues i=7(1)19{
	
	replace coef=_b[_Texp_`i'] if _Texp_`i'==1
	
	replace se=_se[_Texp_`i'] if _Texp_`i'==1
	
}

g ci_top = coef+1.96*se //Storing the coefficients and their standard errors for a coefficient plot
g ci_bottom = coef - 1.96*se

*foreach var of varlist ci_top ci_bottom coef{
*	replace `var'=0 if exp==-1
*}

preserve 

keep exp coef ci* se 
duplicates drop 

// Don't worry too much about this first plot
scatter coef ci* exp, c(l l l) cmissing(y n n) msym(i i i) lcolor(gray gray gray) lpattern (solid dash dash) lwidth(thick medthick medthick) ///
yline(0, lcolor(black)) xline(-1,lcolor(black)) ///
subtitle("Years Relative to Divorce Reform", size(small)) xlabel(-5(5)10,labsize(small)) ///
legend(off) /// 
graphregion(color(white)) ytitle("Suicides per 1m Women") xtitle("Years Relative to Divorce Reform", ) xlabel(-5(1)12) yline(-3.08,lcolor(red) lwidth(thick)) 


//This is the one we're interested in
    twoway (scatter  coef  exp , lcolor(blue))  (rcap  ci_top ci_bot exp, lcolor(blue)) , yline(0,lcolor(black black black))  ///
  subtitle("",  j(left) pos(11)) xlabel(-7(1)10, labsize(small)) xtitle("Years Relative to Divorce Reform", ) yscale(range(-15(1)5)) ylabel(-15(5)5,nogrid angle(horizontal) labsize(small)) ///
  legend(off) graphregion(color(white)) saving("x",replace) ytitle("Suicides per 1m Women") xline(-1,lcolor(black)) xlabel(-5(1)12) yline(-3.08,lcolor(red) lwidth(thick)) 

restore 
  
** some more data cleaning   
gen first_treat=_nfd-1969
 
replace first_treat=0 if _nfd==. & treated==0
 
 
gen _nfd2=_nfd
replace _nfd2=0 if _nfd==.
  
******************************************
*              Exercise 1                *
****************************************** 

// Apply bacondecomp to this setting


 


 
******************************************
*              Exercise 2                *
****************************************** 

// Apply stackedev to this setting

