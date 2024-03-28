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
*             did_imputation             *
*                                        *
*                                        *
******************************************

xtline Y, overlay legend(off)

// ssc install did_imputation

did_imputation Y id t first_treat, horizons(0/10) pretrend(10) // This tells Stata to do the imputation methodology where Y is the outcome avriable, id is the unique unit id, t is the running time variable, and first_treat indicates the first date that the specific unit was treated
estimates store bjs 
 event_plot, default_look graph_opt(xtitle("Days since the event") ytitle("Coefficients") xlabel(-10(1)10)) /// check the documentation if you want to edit the event_plot, there are other options :)
			

// This minn(0) option is super important it says what is the minimum number of observations that you want to require from each group? Any group below that minimum number will have its coefficient supressed 

did_imputation Y id t first_treat, horizons(0/10) pretrend(10) minn(0)
estimates store es 
 event_plot, default_look graph_opt(xtitle("Days since the event") ytitle("Coefficients") xlabel(-10(1)10)) ///

 
 // Just as a comparison
did_imputation Y id t first_treat, horizons(0/10) pretrend(10) minn(20) 
estimates store bjs 
 event_plot, default_look graph_opt(xtitle("Days since the event") ytitle("Coefficients") xlabel(-10(1)10)) ///
	
	
// What the did_imputation is doing is following Borusyak et al. (2021) where to deal with heterogeneity of treatment effects (in a staggered treatment scenario), the efficient robust estimator is implemented by using an "imputation" procedure, where first the unit and period fixed effects (alpha_hat_i and beta_hat_i) are fitted by regressions using unreated observations only. Second, these fixed effects are used to impute the untreated potential outcomes and therefore obtain the estimated treatment effects \tau_hat_i_t = ... for each treated observation. Finally, a weighted sum of these treatment effect estimates is taken."


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

//Use did_imputation to visualize the event study

// First use a time horizon of -20 and +20 (so 20 years on either side). Store these results.

 // did_imputation gives in similar results
 did_imputation asmrs stfip  year _nfd , horizons(0/20) pretrend(20) minn(0) 
 estimates store es1 
 event_plot, default_look graph_opt(xtitle("Years since the event") ytitle("Coefficients") xlabel(-20(5)20) )   
 
// Secondly, use a time horizon of -10 and +10 (so 10 years on either side). Store these results.

   did_imputation asmrs stfip  year _nfd , horizons(0/10) pretrend(10) minn(0) 
 estimates store es2 
 event_plot, default_look graph_opt(xtitle("Years since the event") ytitle("Coefficients") xlabel(-10(5)10) )   
  
  // Tabulate these results so they look nice.
	esttab es1 es2


	

	

**********************************
*                                *
*                                *
*             Tables             *
*            Exercise            *
*                                *
*                                *
**********************************

eststo clear

use https://github.com/scunning1975/mixtape/raw/master/card.dta, clear

// You may find it helpful to create a global for the controls.

global controls_ed exper black south married smsa

* 1. Run an OLS regression of log wages (lwage) on education (educ) controlling for experience (exper), race (black), region (south), marital status (married), and smsa 
* Store your estimates to put it on a table

* OLS estimate of schooling (educ) on log wages
eststo ols: reg lwage  educ  $controls_ed

// The stuff below is not important
* First stage regression of schooling (educ) on all covariates and the college and the county variable
reg educ nearc4 $controls_ed

* Reduced form
reg lwage nearc4 $controls_ed

* F test on the excludability of college in the county from the first stage regression.
test nearc4

* 2. Use proximity to school (nearc4) as an instrument for the education (educ) and find the 2SLS estimate of the effect of schooling (educ) on log wages using "college in the county" as an instrument for schooling
eststo iv: ivreg2 lwage (educ=nearc4) $controls_ed, first 

* 3. Use the JIVE estimator to estimate the coefficient on education (same as part 2)
eststo jive: jive lwage (educ= nearc4) $controls_ed, robust 

* 4. Put your results in a table and export them to latex

global latex "/Users/brunokomel/Library/CloudStorage/Dropbox/Apps/Overleaf/Recitation - Tables"
cd "${latex}"

esttab ols iv jive using "table2.tex",  sfmt(4) b(3) se(2) keep(educ)  label   ///
star(* 0.10 ** 0.05 *** 0.01) booktabs ///
varlabel(educ "Education") mtitles("OLS" "IV" "JIVE") scalars("N Observations") ///
fragment replace

* Plot the coefficients as if you were to present these results

coefplot (ols, aseq(OLS) label(OLS))  (iv, aseq(IV)label(IV)) (jive, aseq(JIVE) label(JIVE))  , xline(0) vertical keep(educ)  ciopts(recast(rcap)) aseq swapnames

