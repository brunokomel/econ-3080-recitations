********************************
*                              *
*                              *
*         Recitation 4         *
*                              *
*                              *
********************************


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

// Let's simplify this a bit:
keep if t > 18 & t < 30


    xtline Y, overlay legend(off)

********************************
*                              *
*             TWFE             *
*                              *
********************************

// How do we estimate the average treatment effect (ATE)?

// ssc install reghdfe

    reghdfe Y D, abs(cohort t) 

// This is running a two-way fixed effect regression with cohort and time fixed effects (abs stands for "absorve" that's because the fixed effects model absorves the movement within each category)



********************************
*                              *
*         Event-Study          *
*                              *
********************************

    // First, let's create the indicators for the leads and the lags
    // And let's say we're only interested in the 5 periods befre and after treatment

    gen rel_time2 = rel_time if abs(rel_time) < 6

    tab rel_time2, gen(period_ind) // This will create an indicator variable for each "level" of rel_time2

    // Let's rename these variables to something more intuitive (leads and lags)
    rename period_ind1 lead5 
    rename period_ind2 lead4
    rename period_ind3 lead3
    rename period_ind4 lead2
    rename period_ind5 lead1
    rename period_ind6 lag0

    forval i = 7/11 {
        local lag_suffix = `i' - 6  // Calculates the lag suffix
        rename period_ind`i' lag`lag_suffix'
    }


    rename lag0  ref 
    replace ref = 0 // this is making the year prior to treatment our reference year (omitted)

    // Let's remove missing values from the control group

    foreach var of varlist lead* lag* ref {
        replace `var' = 0 if `var' == .
    }



    tab cohort

    xtline Y if first_treat < 25 | first_treat == . & t > 18 & t < 29, overlay legend(off) // Here we can see the effects of staggered treatments


    reghdfe Y lead5 lead4 lead3 lead2 lead1 ref lag1 lag2 lag3 lag4 lag5 , absorb(cohort t)


    coefplot, keep (lead5 lead4 lead3 lead2 lead1 ref lag1 lag2 lag3 lag4 lag5) ///
    omitted vertical xlabel(, angle(vertical)) yline(0) xline(5) recast(connected) xlabel(, angle(0)) ///
    ciopts(recast(rcap) lwidth(*1) lcolor(red))   mcolor(black) lcolor(blue)  ///
    mlabposition(12) mlabgap(*2) title(Event-Study Plot)  lstyle(grid)  ///
    rename(lead5 = "-5" lead4 = "-4" lead3 = "-3" lead2 = "-2" lead1 = "-2" lead1 = "-1" ref = "0" lag1 = "1" lag2 = "2" lag3 = "3" lag4 = "4" lag5 = "5" )  ///
    addplot(scatteri -21 5 -21 6 61 6 61 5, recast(area) lwidth(none) color(gray%10) ) 

// But what do each of those commands do?

// Ask GPT 


********************************
*                              *
*           Exercise           *
*                              *
********************************

// Based on Cheng and Hoesktra (2013) [Thanks, @Causal Inference The Mixtape]

// Studies the effect of castle-doctrine statutes passed in 21 states between 2000 and 2010. 
// These statutes extended one's right to use lethal self-defense such that it was no longer limited to one's home, 
// but also to other public places.

// So this paper studies the effect of these doctrines on the (log) number of homicides.


use https://github.com/scunning1975/mixtape/raw/master/castle.dta, clear

* define global macros
global crime1 jhcitizen_c jhpolice_c murder homicide  robbery assault burglary larceny motor robbery_gun_r 
global demo blackm_15_24 whitem_15_24 blackm_25_44 whitem_25_44 //demographics
global lintrend trend_1-trend_51 //state linear trend
global region r20001-r20104  //region-quarter fixed effects
global exocrime l_larceny l_motor // exogenous crime rates
global spending l_exp_subsidy l_exp_pubwelfare
global xvar l_police unemployrt poverty l_income l_prisoner l_lagprisoner $demo $spending

// 0. Figure out what the treatment variable is

// post

// 1. Estimate the ATE of the treatment variable on log homicides.
* Make sure to use year and state fixed effects. (Hint: you should also use population weights, popwt)
* Also, you should control for region, linear trends, and other covariates that were stored as globals


xtset

label variable post "Year of treatment"
xi: xtreg l_homicide post i.year $region $xvar $lintrend  [aweight=popwt], fe vce(cluster sid)


// My preferred command
reghdfe l_homicide  post $region $xvar $lintrend  [aw = popwt], vce(cluster sid) absorb(year sid)

// 2. Now create an event-study plot for this setting.

gen ref = 0

* Event study regression with the year of treatment (lag0) as the omitted category.
reghdfe l_homicide lead9 lead8 lead7 lead6 lead5 lead4 lead3 lead2 lead1 ref lag1-lag5  $region [aweight=popwt], absorb(year sid) vce(cluster sid)

set scheme tab1

coefplot, keep(lead9 lead8 lead7 lead6 lead5 lead4 lead3 lead2 lead1 ref lag1 lag2 lag3 lag4 lag5 ) ///
	xlabel(, angle(vertical))  yline(-.5(0.25)0.5) xline(10) vertical omitted recast(connected) xlabel(, angle(0)) ///
	ciopts(recast(rcap) lwidth(*1) lcolor(gs2) ) format(%9.0f)   mcolor(gs2) lcolor(gs2) ///
	mlabposition(12) mlabgap(*2) title(Event-Study Plot)  lstyle(grid) ///
	rename(lead9 = "-9" lead8 = "-8" lead7 = "-7" lead6 = "-6"   lead5 = "-5" lead4 = "-4" lead3 = "-3" lead2 = "-2"  lead1 = "-1" ref = "0" lag1 = "1" lag2 = "2" lag3 = "3" lag4 = "4" lag5 = "5" )  ///
	addplot(scatteri -.5 10 -.5 11 .5 11 .5 10, recast(area) lwidth(none) color(grey%10) ) 




