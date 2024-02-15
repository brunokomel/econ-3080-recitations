******************************************
*                                        *
*                                        *
*              Recitation 6              *
*                                        *
*                                        *
******************************************


// Recitation 6 - Regression Discontinuity Design
/*
By: Bruno Kömel
Date: 15 Feb 2024
*/

*****************************
*                           *
*         Basic RDD         *
*                           *
*****************************

* Let's create some data to illustrate
clear
capture log close
set obs 1000 // this tells stata to generate 1000 observations when creating variables
set seed 1234567

* Generate running variable. Stata code attributed to Marcelo Perraillon. Thanks, Marcelo.
gen x = rnormal(50, 25) // Generates random values from a normal distribution with mean = 50, SD = 25
replace x=0 if x < 0 
drop if x > 100
sum x, det

* Set the cutoff at X=50. Treated if X > 50
gen D = 0
replace D = 1 if x > 50
gen y1 = 25 + 0*D + 1.5*x + rnormal(0, 20) // Note here that we are mechanically making the treatment have 0 effect 

* Potential outcome Y1 not jumping at cutoff (continuity)
twoway (scatter y1 x if D==0, msize(vsmall) msymbol(circle_hollow)) (scatter y1 x if D==1, sort  msize(vsmall) msymbol(circle_hollow)) (lfit y1 x if D==0, lcolor(red) msize(small)  lwidth(medthin) lpattern(solid)) (lfit y1 x if D==1, lcolor(red) msize(small)   lwidth(medthin) lpattern(solid)) (lfit y1 x, lcolor(dknavy) msize(small) lwidth(medthin) lpattern(dash)), xtitle(Test score (X)) xline(50) legend(off)

* Let's create an actual shift
gen y = 25 + 40*D + 1.5*x + rnormal(0, 20)

twoway (scatter y x if D==0, msize(vsmall) ) (scatter y x if D==1, sort msize(vsmall) ) (lfit y x if D==0, lcolor(red) msize(small)   lwidth(medthin) lpattern(solid)) (lfit y x if D==1, lcolor(red) msize(small)   lwidth(medthin) lpattern(solid)) (lfit y1 x, lcolor(dknavy) msize(small) lwidth(medthin) lpattern(dash)) , xtitle(Test score (X)) xline(50) legend(off)

// Quicly, let's just re-center the running variable (common practice)
gen x_center = x - 50

twoway (scatter y x_center if D==0, msize(vsmall) ) (scatter y x_center if D==1, sort msize(vsmall) ) (lfit y x_center if D==0, lcolor(red) msize(small)   lwidth(medthin) lpattern(solid)) (lfit y x_center if D==1, lcolor(red) msize(small)   lwidth(medthin) lpattern(solid)) (lfit y1 x_center, lcolor(dknavy) msize(small) lwidth(medthin) lpattern(dash)) , xtitle(Test score (X)) xline(50) legend(off)

// How can we estimate the RD coefficient?

// Simplest way is to just estimate the treatment effect with a dummy
reg y x D  , robust

// But we could also account for the fact that the slopes might be different on either side of the cutoff (DiD)
reg y c.x##D, robust

// Or we could look around the cutoff and estimate the treatment effect in a DiD fashion
reg y c.x##D if x>=40 & x<=60 , robust

//But how can we get the coefficient that exactly matches the figure?

*** Manually estimating coefficient
reg y x if D == 0
scalar cons1 = _b[_cons]
scalar b1 = _b[x]
scalar se_cons1 = _se[_cons]
scalar se_b1 = _se[x]

reg y x if D == 1
scalar cons2 = _b[_cons]
scalar b2 = _b[x]
scalar se_cons2 = _se[_cons]
scalar se_b2 = _se[x]
 
scalar rdd_coef = cons2 + b2*50 - cons1 - b1*50
scalar rdd_coef_var = (se_cons1)^2 + (50*se_b1)^2 + (se_cons2)^2 + (50*se_b2)^2
scalar rdd_se = (rdd_coef_var)^(1/2) 
scalar rdd_t = rdd_coef/rdd_se

scalar list

// But really, in practice we'll use:
rdrobust y x, c(50) p(2) kernel(triangular) // Triangular kernel is the default, but I wanted to include so you could see the options

rdrobust y x, c(50) p(1) kernel(uniform) 

rdrobust y x_center, p(1) kernel(uniform)

// To check if there was any manipulation around the cutoff:
// net install rddensity, from(https://sites.google.com/site/rdpackages/rddensity/stata) replace
// net install lpdensity, from(https://sites.google.com/site/nppackages/lpdensity/stata) replace
rddensity x, c(50) plot

****************************
*                          *
*      Nonlinearities      *
*                          *
****************************

// Careful not to confuse nonlinearity for discontinuity

drop y y1 x* D
set obs 1000
gen x = rnormal(100, 50)
replace x=0 if x < 0
drop if x > 280
sum x, det

* Set the cutoff at X=140. Treated if X > 140
* Note that we're forcing the treatment effect to be = 0
gen D = 0
replace D = 1 if x > 140
gen x2 = x*x
gen x3 = x*x*x
gen y = 10000 + 0*D - 100*x + x2 + rnormal(0, 1000)
reg y D x

scatter y x if D==0, msize(vsmall) || scatter y x ///
  if D==1, msize(vsmall) legend(off) xline(140, ///
  lstyle(foreground)) || lfit y x ///
  if D ==0, color(red) || lfit y x if D ==1, ///
  color(red) xtitle("Test Score (X)") ///
  ytitle("Outcome (Y)") 

* Polynomial estimation
reg y D x x2 x3
predict yhat // Running this "predit" command after a regression stores the y-hat values

scatter y x if D==0, msize(vsmall) || scatter y x ///
  if D==1, msize(vsmall) legend(off) xline(140, ///
  lstyle(foreground)) ylabel(none) || line yhat x ///
  if D ==0, color(red) sort || line yhat x if D==1, ///
  sort color(red) xtitle("Test Score (X)") ///
  ytitle("Outcome (Y)") 
  
capture drop y yhat
gen y = 10000 + 0*D - 100*x +x2 + rnormal(0, 1000)
reg y D##c.(x x2 x3)
predict yhat

scatter y x if D==0, msize(vsmall) || scatter y x ///
  if D==1, msize(vsmall) legend(off) xline(140, ///
  lstyle(foreground)) ylabel(none) || line yhat x ///
  if D ==0, color(red) sort || line yhat x if D==1, ///
  sort color(red) xtitle("Test Score (X)") ///
  ytitle("Outcome (Y)") 
  
rdrobust y x, c(140) 
rdbwselect y x , c(140)
rdplot y x, c(140)


****************************
*                          *
*         Exercise         *
*                          *
****************************


// Paper "Do Voters Affect or Elect Policies? Evidence from the U. S. House" by 
// Lee, David S. ; Moretti, Enrico ; Butler, Matthew J.
// link: https://pitt.primo.exlibrisgroup.com/discovery/fulldisplay?docid=cdi_crossref_primary_10_1162_0033553041502153&context=PC&vid=01PITT_INST:01PITT_INST&lang=en&search_scope=MyInst_and_CI&adaptor=Primo%20Central&tab=Everything&query=any,contains,Do%20Voters%20Affect%20or%20Elect%20Policies%3F%20Evidence%20from%20the%20U.%20S.%20House&offset=0


use https://github.com/scunning1975/mixtape/raw/master/lmb-data.dta, clear

scatter score lagdemvoteshare 

// ssc install estout

* Replicating Table 1 of Lee, Moretti and Butler (2004)
// In this analysis, we want to look at the effects around the cutoff
// we're regressing the score of the policy on a dummy for democrat won in the prior period
// The score is a measure of how much a policy is aligned with the democratic agenda. (higher means more democrat)
// the variable democrat is just an indicator for whether a democrat won in the prior period

// Here "eststo" stores the estimation you're running under some name, here "r1"
eststo r1: reg score lagdemocrat    if lagdemvoteshare>.48 & lagdemvoteshare<.52, cluster(id) 

// we're regressing the score of the policy on a dummy for democrat won in this eriod
eststo r2: reg score democrat       if lagdemvoteshare>.48 & lagdemvoteshare<.52, cluster(id)

// here we're regressing whether a democrat won this period on whether they won last period
eststo r3: reg democrat lagdemocrat if lagdemvoteshare>.48 & lagdemvoteshare<.52, cluster(id)

// Then we can use "esttab" to compile the estimates we stored (this appends the estimates sequentially on the right)
esttab r1 r2 r3 , se sfmt(3) b( 3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
keep( lagdemocrat democrat ) ///
scalars("N Observations")   
// So this table is what we're going to work towards from now on.


// To do:

* 1. Use all the data to estimate the effects (on the score for the election period), 
* not just around the cutoff and see how the results compare

// What if we use all the data? Not just around the cutoff?

reg score democrat, cluster(id)


* 2. Control for the running variable and see how that affects the resutls

// Let's try controlling for the running variable?
// Also, let's recenter the running variable
gen demvoteshare_c = demvoteshare - 0.5

reg score democrat demvoteshare_c, cluster(id)


* 3. Allow the running variable to have a different coefficient on either side of the discontinuity

// What if we let the running variable vary on either side of the discontinuity?



// notice that c.demvoteshare_c creates an interaction between a contunious variable and a dummy variable

// the xi: allows us to convert categorical variables to dummy variables

xi: reg score i.democrat*demvoteshare_c, cluster(id)
// or reg score lagdemocrat##c.demvoteshare_c, cluster(id) 

* 4. Use a quadratic transformation of the runing variable to account for potential nonlinearities

// What if we use a quadratic?
gen demvoteshare_sq = demvoteshare_c^2

xi: reg score democrat##c.(demvoteshare_c demvoteshare_sq), cluster(id)


* 5. Re-do step 4, but this time considering only observations within 5% of the running variable cutoff, which is 50%

// let's try using a 5pp window now

xi: reg score democrat##c.(demvoteshare_c demvoteshare_sq) if lagdemvoteshare>.45 & lagdemvoteshare<.55, cluster(id)


* 6. Use rdrobust and rdplot to check if the results in the paper are close to what they should be (assuming the non-parametric method gives the correct answer)

rdrobust score demvoteshare, c(0.5)
rdplot score demvoteshare, c(0.5)

* 7. Use rddensity to check if there was any manipulation around the cutoff.

rddensity lagdemvoteshare, c(0.5) plot


/// Another way to plot:
*ssc install cmogram
cmogram score lagdemvoteshare, cut(0.5) scatter line(0.5) qfitci

cmogram score lagdemvoteshare, cut(0.5) scatter line(0.5) lfit
 
cmogram score lagdemvoteshare, cut(0.5) scatter line(0.5) lowess