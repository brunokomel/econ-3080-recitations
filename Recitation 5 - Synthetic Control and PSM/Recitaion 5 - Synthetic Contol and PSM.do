******************************************
*                                        *
*                                        *
*              Recitation 5              *
*                                        *
*                                        *
******************************************

/* 
By: Bruno Kömel
Date: 8 Feb 2024
*/


******************************************
*                                        *
*           Synthetic Control            *
*                                        *
******************************************


// Synthetic Control: thanks to Abadie, Diamond, and Hainmueller (2010)
set scheme gg_tableau

* Estimation 1: Texas model of black male prisoners (per capita) 
use https://github.com/scunning1975/mixtape/raw/master/texas.dta, clear
//ssc install synth, replace
//ssc install mat2txt, replace 

global wd "/Users/brunokomel/Documents/Pitt/Year 3/TA - Econ 3080/econ-3080-recitations/Recitation 5 - Synthetic Control and PSM"

cd "$wd"

* tsset statefip year  // for some reason we don't need to do this. The data somehow knows that statefip is the state ID and that year is the period. But if you ever need to "declare the dataset as a panel" you can use this command tsset


// Make sure you create these paths in your own computer
// You are going to need a directory with the folders, "data" "Figures" "inference"

cd "$wd/data"

#delimit; 
synth   bmprate  
            bmprate(1990) bmprate(1991) bmprate(1992) bmprate(1988)
            alcohol(1990) aidscapita(1990) aidscapita(1991) 
            income ur poverty black(1990) black(1991) black(1992) 
            perc1519(1990)
            ,       
        trunit(48) trperiod(1993) unitnames(state) 
        mspeperiod(1985(1)1993) resultsperiod(1985(1)2000)
        keep("synth_bmprate.dta") replace fig;
        mat list e(V_matrix);

#delimit cr

cd "$wd/Figures"

graph save Graph synth_tx.gph, replace
		
// A couple of things to highlight here: 
// '#delimit' is a command that changes the "delimiter" from the standard carriage return (i.e. pressing "Enter") to somethign else. Here '#delimit;' changes the delimiter to ';'

// Next the command synth
// First we list the outcome variable (bmprison)
// then we list the variables on which we want to match. 5 details to note:

// 1. The authors tell us to control for pre-treatment outcomes to "soak up heterogeneity" thus we control for "bmprison(1990)" etc.

// 2. We can choose to match on the entire pre-treatment average "income" without specifying a year

// 3. Or, you can choose to match on particular years "aidscapita(1990)"

// 4. trunit() indicates which unit ID marks the treatment unit (similarly unitnames tells stata where to get the names for each unit)

// 5. trperiod() indicates when the treatment unit is treated

// Note here that the option mspeperiod lists the pre-intervention time periods over which the Mean Squared Prediction Error (MSPE) should be minimized 

// THEN, the command generously creates a dataset that we use below, but we have to use the "keep()" option, and tell the command where to store the data
// AND the command will generate the plot we saw (we can also store that somewhere)

// The stored dataset tells you two things:
// 1. what weight was assigned to each state (control unit)
// 2. The outcome values for the treated and the synthetic control for each period
		


* Plot the gap in predicted error
use "$wd/data/synth_bmprate.dta", clear
keep _Y_treated _Y_synthetic _time
drop if _time==.
rename _time year
rename _Y_treated  treat
rename _Y_synthetic counterfact
gen gap48=treat-counterfact
sort year
* Plot the gap in predicted error
use "$wd/data/synth_bmprate.dta", clear
keep _Y_treated _Y_synthetic _time
drop if _time==.
rename _time year
rename _Y_treated  treat
rename _Y_synthetic counterfact
gen gap48=treat-counterfact
sort year

cd "$wd/data"
#delimit ; 
	twoway (line gap48 year,lp(solid)lw(vthin)lcolor(black)), yline(0, lpattern(shortdash) lcolor(black)) 
    xline(1993, lpattern(shortdash) lcolor(black)) xtitle("",si(medsmall)) xlabel(#10) 
    ytitle("Gap in black male prisoner prediction error", size(medsmall)) legend(off); 
    #delimit cr
    save synth_bmprate_48.dta, replace
	
	
// But how do we calculate the p-value???
	
// Here we do that weird thing where we assign the treatment to every state and reestimate the model and then we rank some stuff. (See The Mixtape ch. 10 for more context)	

// This loop cycles through each state and estimates the model and saves the data associated with each model indo a bmcrate_'i'.dta file where 'i' is one of the state FIPS codes

* Inference 1 placebo test  
#delimit; 
set more off; 
use https://github.com/scunning1975/mixtape/raw/master/texas.dta, replace;
global statelist  1 2 4 5 6 8 9 10 11 12 13 15 16 17 18 20 21 22 23 24 25 26 27 28 29 30 31 32  33 34 35 36 37 38 39 40 41 42 45 46 47 48 49 51 53 55; 

cd "$wd/data" ;

foreach i of global statelist {; 
synth   bmprison  
        bmprison(1990) bmprison(1992) bmprison(1991) bmprison(1988) 
        alcohol(1990) aidscapita(1990) aidscapita(1991)  
        income ur poverty black(1990) black(1991) black(1992)  
        perc1519(1990) 
        ,        
            trunit(`i') trperiod(1993) unitnames(state)  
            mspeperiod(1985(1)1993) resultsperiod(1985(1)2000) 
            keep(synth_bmprate_`i'.dta) replace; 
            matrix state`i' = e(RMSPE); /* check the V matrix*/ 
};
foreach i of global statelist {; 
matrix rownames state`i'=`i'; 
matlist state`i', names(rows); 
};

#delimit cr


 foreach i of global statelist {
    use synth_bmprate_`i' ,clear
    keep _Y_treated _Y_synthetic _time
    drop if _time==.
    rename _time year
    rename _Y_treated  treat`i'
    rename _Y_synthetic counterfact`i'
    gen gap`i'=treat`i'-counterfact`i'
    sort year 
    save synth_gap_bmprate`i', replace
    }
use synth_gap_bmprate48.dta, clear
sort year //sorting Texas only, for some reason
save placebo_bmprate48.dta, replace



// And below we merge all of them together
foreach i of global statelist {
        merge year using synth_gap_bmprate`i' 
        drop _merge 
        sort year 
    save placebo_bmprate.dta, replace 
    }
    

** Inference 2: Estimate the pre- and post-RMSPE and calculate the ratio of the
*  post-pre RMSPE   
set more off

foreach i of global statelist {

    use synth_gap_bmprate`i', clear
    gen gap3=gap`i'*gap`i' // here we square the "gaps"
    egen postmean=mean(gap3) if year>1993
    egen premean=mean(gap3) if year<=1993
    gen rmspe=sqrt(premean) if year<=1993
    replace rmspe=sqrt(postmean) if year>1993
    gen ratio=rmspe/rmspe[_n-1] if 1994 //This creates the ratio of post/pre RMSPE
    gen rmspe_post=sqrt(postmean) if year>1993
    gen rmspe_pre=rmspe[_n-1] if 1994
    mkmat rmspe_pre rmspe_post ratio if 1994, matrix (state`i')
}	
	
	
* show post/pre-expansion RMSPE ratio for all states, generate histogram
    foreach i of global statelist {
        matrix rownames state`i'=`i'
        matlist state`i', names(rows)
                                    }
							
						
// This is a bizarre way of accomplishing whatever we're doing. But this operation "\" row joins the matrices on either side
#delimit ; 
matrix state=state1\state2\state4\state5\state6\state8\state9\state10\state11\state12\state13\state15\state16\state17\state18\state20\state21\state22\state23\state24\state25\state26\state27\state28\state29\state30\state31\state32\state33\state34\state35\state36\state37\state38\state39\state40\state41\state42\state45\state46\state47\state48\state49\state51\state53\state55; 
#delimit cr

cd "$wd/inference"
* ssc install mat2txt
    mat2txt, matrix(state) saving(rmspe_bmprate.txt) replace
    insheet using rmspe_bmprate.txt, clear
    ren v1 state
    drop v5
    gsort -ratio
    gen rank=_n
    gen p=rank/46
    export excel using rmspe_bmprate, firstrow(variables) replace
    import excel rmspe_bmprate.xlsx, sheet("Sheet1") firstrow clear
	drop if missing(rmspe_pre) | missing(rmspe_post) 
	drop if ratio == 1 // This is my attempt at correcting some error from the author
    histogram ratio, bin(20) frequency fcolor(navy) lcolor(black) ylabel(0(2)10) xtitle("Post/pre RMSPE ratio") xlabel(0(1)20)
* Show the post/pre RMSPE ratio for all states, generate the histogram.
    list rank p if state==48
	
	
* Inference 3: all the placeboes on the same picture
use "$wd/data/placebo_bmprate.dta", replace
* Picture of the full sample, including outlier RSMPE
#delimit;   
twoway 
(line gap1 year ,lp(solid)lw(vthin)) 
(line gap2 year ,lp(solid)lw(vthin)) 
(line gap4 year ,lp(solid)lw(vthin)) 
(line gap5 year ,lp(solid)lw(vthin))
(line gap6 year ,lp(solid)lw(vthin)) 
(line gap8 year ,lp(solid)lw(vthin)) 
(line gap9 year ,lp(solid)lw(vthin)) 
(line gap10 year ,lp(solid)lw(vthin)) 
(line gap11 year ,lp(solid)lw(vthin)) 
(line gap12 year ,lp(solid)lw(vthin)) 
(line gap13 year ,lp(solid)lw(vthin)) 
(line gap15 year ,lp(solid)lw(vthin)) 
(line gap16 year ,lp(solid)lw(vthin)) 
(line gap17 year ,lp(solid)lw(vthin))
(line gap18 year ,lp(solid)lw(vthin)) 
(line gap20 year ,lp(solid)lw(vthin)) 
(line gap21 year ,lp(solid)lw(vthin)) 
(line gap22 year ,lp(solid)lw(vthin)) 
(line gap23 year ,lp(solid)lw(vthin)) 
(line gap24 year ,lp(solid)lw(vthin)) 
(line gap25 year ,lp(solid)lw(vthin)) 
(line gap26 year ,lp(solid)lw(vthin))
(line gap27 year ,lp(solid)lw(vthin))
(line gap28 year ,lp(solid)lw(vthin)) 
(line gap29 year ,lp(solid)lw(vthin)) 
(line gap30 year ,lp(solid)lw(vthin)) 
(line gap31 year ,lp(solid)lw(vthin)) 
(line gap32 year ,lp(solid)lw(vthin)) 
(line gap33 year ,lp(solid)lw(vthin)) 
(line gap34 year ,lp(solid)lw(vthin))
(line gap35 year ,lp(solid)lw(vthin))
(line gap36 year ,lp(solid)lw(vthin))
(line gap37 year ,lp(solid)lw(vthin)) 
(line gap38 year ,lp(solid)lw(vthin)) 
(line gap39 year ,lp(solid)lw(vthin))
(line gap40 year ,lp(solid)lw(vthin)) 
(line gap41 year ,lp(solid)lw(vthin)) 
(line gap42 year ,lp(solid)lw(vthin)) 
(line gap45 year ,lp(solid)lw(vthin)) 
(line gap46 year ,lp(solid)lw(vthin)) 
(line gap47 year ,lp(solid)lw(vthin))
(line gap49 year ,lp(solid)lw(vthin)) 
(line gap51 year ,lp(solid)lw(vthin)) 
(line gap53 year ,lp(solid)lw(vthin)) 
(line gap55 year ,lp(solid)lw(vthin)) 
(line gap48 year ,lp(solid)lw(thick)lcolor(black)), /*treatment unit, Texas*/
yline(0, lpattern(shortdash) lcolor(black)) xline(1993, lpattern(shortdash) lcolor(black))
xtitle("",si(small)) xlabel(#10) ytitle("Gap in black male prisoners prediction error", size(small))
    legend(off);
#delimit cr

************ Exercise *************
// Repeat the analysis using black male incarceration rate rather than black male total counts.

// Back to using bmprison. Perform placebo-date falsification, choosing 1989 as the treatment date and 1992 as the end of the sample to check if the model shows the same treatment effect you found above.


******************************************
*                                        *
*                  PSM                   *
*                                        *
******************************************

// Let's do this together:

// Here we're going to consider data about a job training program that took place in the 70s (1975 is before the treatment, and 1978 is after).

// The data comes from an experiment, but we'll use it to verify the estimate from PSM

use https://github.com/scunning1975/mixtape/raw/master/nsw_mixtape.dta, clear

// To get the experimental treatment effect, we can just compare the means between treated and control groups
su re78 if treat == 1
gen y1 = r(mean)
su re78 if treat==0
gen y0 = r(mean)
gen ate = y1-y0
su ate
di 6349.144 - 4554.801
* ATE is 1794.34 

** Alternatively, we can run a regression
reg re78 treat
* ATE is 1794.34 


// But how can we use PSM here?
// Let's bring in another dataset, the Current Population Survey (CPS)

* Now merge in the CPS controls from footnote 2 of Table 2 (Dehejia and Wahba 2002)

drop if treat==0 // Notice that we're dropping the experimental control group because we're going to create a new control group from the CPS that "looks like" the treatment group from the experiment


append using https://github.com/scunning1975/mixtape/raw/master/cps_mixtape.dta

// And let's generate some variables so we can match the observations based pn observable characteristics
gen agesq=age*age
gen agecube=age*age*age
gen edusq=educ*edu
gen u74 = 0 if re74!=.
replace u74 = 1 if re74==0
gen u75 = 0 if re75!=.
replace u75 = 1 if re75==0
gen interaction1 = educ*re74
gen re74sq=re74^2
gen re75sq=re75^2
gen interaction2 = u74*hisp


teffects psmatch (re78) (treat age agesq agecube educ edusq marr nodegree black hisp re74 re75 u74 u75 interaction1, logit), atet  nn(5) gen(pstub_cps)

// Notice that we get pretty close


// teffects is the function
// psmatch is the matching method we're going to use
// (re78) is the outcome variable
// (treat varlist) : treat is the treatment variable, and varlist is the list of variables on which we are "matching", or variables that we are using to predic treatment assignment in thre treatment model

// , logit specifies the kind of treament model to use 
// atet specifies that we want the average treatment effect on the treated (rather than the ate on the population) [** This is actually super important. Rview common support assumption in the Causal Inference Mixtape Book]

// nn(5) specifies that we want the control group to be made up of the 5 nearest neighbors (closest propensity scores) to each treated observation
// gen(.) is going to create a list of variables that show which are the 5 nearest neighbors









