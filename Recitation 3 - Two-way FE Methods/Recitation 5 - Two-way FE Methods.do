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
*                  csdid                 *
*                                        *
*                                        *
******************************************

// ssc install csdid, replace
// ssc install drdid, replace
// ssc install event_plot, replace
// ssc install bacondecom, replace
reghdfe Y D, abs(cohort t) //This is running a two-way fixed effect regression with cohort and time fixed effects (abs stands for "absorve" that's because the fixed effects model absorves the movement within each category)

bacondecomp Y D cohort, stub(_bac) robust ddetail

csdid Y, ivar(id) time(t) gvar(gvar) notyet // here ivar is the panel identifier (e.g. country), time is something like the 'year' or 'month' (the running variable); gvar is the variable identifying groups/cohorts , notyet requests that the model use only observations never treated and not yet treated in the control group

estat event, window(-10 10) estore(cs) // This tells Stata to store only the coefficients related to the 10 years prior and the 10 years after the treatments


event_plot cs, default_look graph_opt(xtitle("Periods since the event") ytitle("Average effect") ///
	title("csdid") xlabel(-10(1)10)) stub_lag(Tp#) stub_lead(Tm#) together
	
// what csdid does is it uses a robust methodology (optionally non-parametric, I think) to get the ATT estimate (average treatment effect on the treated) but while only considering "good" designs. By good we mean either those that identify ATT's correctly, or those that can be used for testing parallel trends. Most importatnly, it avoids estimating bad Did designs (i.e. those that use previously treated units as the control group)


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
estimates store bjs // honestly I don't know why this works, but this stores the coefficients
 event_plot, default_look graph_opt(xtitle("Days since the event") ytitle("Coefficients") xlabel(-10(1)10)) /// check the documentation if you want to edit the event_plot, there are other options :)
			

// This minn(0) option is super important it says what is the minimum number of observations that you want to require from each group? Any group below that minimum number will have its coefficient supressed 

did_imputation Y id t first_treat, horizons(0/10) pretrend(10) minn(0)
estimates store bjs 
 event_plot, default_look graph_opt(xtitle("Days since the event") ytitle("Coefficients") xlabel(-10(1)10)) ///

 
 // Just as a comparison
did_imputation Y id t first_treat, horizons(0/10) pretrend(10) minn(20) 
estimates store bjs 
 event_plot, default_look graph_opt(xtitle("Days since the event") ytitle("Coefficients") xlabel(-10(1)10)) ///
	
	
// What the did_imputation is doing is following Borusyak et al. (2021) where to deal with heterogeneity of treatment effects (in a staggered treatment scenario), the efficient robust estimator is implemented by using an "imputation" procedure, where first the unit and period fixed effects (alpha_hat_i and beta_hat_i) are fitted by regressions using unreated observations only. Second, these fixed effects are used to impute the untreated potential outcomes and therefore obtain the estimated treatment effects \tau_hat_i_t = ... for each treated observation. Finally, a weighted sum of these treatment effect estimates is taken


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

recode exp (.=-1) (-1000/-6=-6) (12/1000=12) // honestly not sure what this does

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

// bacondecomp is a tool to help us visualize which comparisons are being heavily weighted in the twoway fixed effects estimation
// use reghdfe to estimate the twoway fixed effects coefficeint for the treatment
// remember to control for per-capita income, homicide mortality, AFDC cases, state and year fixed effects (don't forget the interaction term)

reghdfe asmrs interaction pcinc asmrh cases,abs(stfips year)

// run bacondecomp on the same regression you just ran above 
bacondecomp asmrs post pcinc asmrh cases, stub(Bacon_) robust ddetail

// List the "stub" variables/tables you created
list Bacon_T Bacon_C Bacon_B Bacon_cgroup if !mi(Bacon_T)
 
// plot the asmrs lines 
xtline asmrs, overlay legend(off)
 
******************************************
*              Exercise 2                *
****************************************** 

// use csdid to calculate the corrected coefficient

csdid asmrs, ivar(stf) time(year) gvar(_nfd2) notyet // can remove the notyet option as well, but the results change a bit
estat all 
 
estat event  // Notice that the average post effect is around -8. This is significantly different from the -2.51 we saw earlier. This is because when the treatment changes the time trends (the slope of the line) then the twoway fixed effect model biases our estimates toward zero.
 
//plot the csdid plot
 
csdid_plot
  
******************************************
*              Exercise 3                *
******************************************   

//Use did_imputation to visualize the event study

 // did_imputation gives in similar results
 did_imputation asmrs stfip  year _nfd , horizons(0/27) pretrend(20) minn(0) 
 estimates store bjs 
 event_plot, default_look graph_opt(xtitle("Days since the event") ytitle("Coefficients") xlabel(-20(5)27) yline(-8.15, lcolor(red)))   // note here that I added the red horizontal line at y= -8.15 to show where the average results from the csdid fall in this plot
  
  
  
 
 




