**************************************
*                                    *
*                                    *
*           Recitation 13            *
*                                    *
*                                    *
**************************************

// Date: 4/11/24
// By: Bruno Kömel

// Examples and explanations from: https://github.com/mcaceresb/


// ssc install honestDiD ,  all
// ssc install staggered 
// ssc install pretrends


**************************************
*                                    *
*             PreTrends              *
*                                    *
**************************************

// https://github.com/mcaceresb/stata-pretrends#readme

// The pretrends package provides tools for power calculations for pre-trends tests, and visualization of possible violations of parallel trends. Calculations are based on Roth (2022).

// The basic idea is that if we are relying on a pre-trends test to verify the parallel trends assumption, we'd like that test to have power to detect relevant violations of parallel trends. To assess the power of a pre-trends test, we can calculate its ex ante power: how big would a violation of parallel trends need to be such that we would detect it some specified fraction (say 80%) of the time? This is similar to the minimal detectable effect (MDE) size commonly reported for RCTs. Alternatively, we can calculate how likely we would be to detect a particular hypothesized violation of parallel trends. The pretrends package provides methods for doing these calculations, as well as for visualizing potential violations of parallel trends on an event-study plot.

// We first load the dataset used by He and Wang (2017).


use "https://media.githubusercontent.com/media/mcaceresb/stata-pretrends/main/data/workfile_AEJ.dta", clear

reghdfe l_poor_reg_rate Lead_D4_plus Lead_D3 Lead_D2 D0 Lag_D1 Lag_D2 Lag_D3_plus, absorb(v_id year) cluster(v_id) dof(none)

// The package has two subcommands:
// 1. power
// 2. delta() option

// The power sub-command calculates the slope of a linear violation of parallel trends that a pre-trends test would detect a specified fraction of the time. (By detect, we mean that there is any significant pre-treatment coefficient.)

// Alternatively, the user can specify a hypothesized violations of parallel trends—the package then creates a plot to visualize the results, and reports various statistics related to the hypothesized difference in trend. The user can specify a hypothesized linear pre-trend via the slope() option, or provide an arbitrary violation of parallel trends via the delta() option.

pretrends power 0.5, pre(1/3) post(4/7)

return list
// In the command above, the option pre(1/3) tells the package that the pre-treatment event-study coefficients are in positions 1 through 3 in our regression results. (The package assumes that the period before the event-study is normalized to zero and omitted from the regression.) Likewise, the option post(4/7) tells the package that the post-treatment coefficients are in positions 4 through 7.

// The results tell us that if there were a linear pre-trend with a slope of about 0.05, then we would find a significant pre-trend only half the time. (Note that the result of the pretrends power subcommand is a magnitude, and thus is always positive.) If we want wanted a different power threshold, say 80%, we would change power 0.5 to power 0.8 in the command above.

// The package's second function enables power analyses and visualization given the results of an event-study and a user-hypothesized violation of parallel trends. We illustrate this using the linear trend against which pre-tests have 50 percent power, computed above. (This is just for illustration; we encourage researchers to conduct power analysis for violations of parallel trends they deem to be relevant in their context.) We run the command:

pretrends  , pre(1/3) post(4/7) slope(`r(slope)')
// Where does this `r(slope)' come from?
// return list

//  The dashed blue line shows what we'd expect the coefficients to look like on average conditional on not finding a significant pre-trend if in fact that truth was the hypothesized red line.
pretrends  , pre(1/3) post(4/7) slope(1)

return list
matlist r(results)

// * r(Power) The probability that we would find a significant pre-trend under the hypothesized pre-trend. (This is 0.50, up to numerical precision error, by construction in our example.) Higher power indicates that we would be likely to find a significant pre-treatment coefficient under the hypothesized trend.

// * r(BF) (Bayes Factor) The ratio of the probability of "passing" the pre-test under the hypothesized trend relative to under parallel trends. The smaller the Bayes factor, the more we should update our prior in favor of parallel trends holding (relative to the hypothesized trend) if we observe an insignificant pre-trend.

// * r(LR) (Likelihood Ratio) The ratio of the likelihood of the observed coefficients under the hypothesized trend relative to under parallel trends. If this is small, then observing the event-study coefficient seen in the data is much more likely under parallel trends than under the hypothesized trend.

// * r(results) The data used to make the event plot. Note the column meanAfterPretesting, which is also plotted. The basic idea of this column is that if we only analyze our event-study conditional on not finding a significant pre-trend, we are analyzing a selected subset of the data. The meanAfterPretesting column tells us what we'd expect the coefficients to look like conditional on not finding a significant pre-trend if in fact the true pre-trend were the hypothesized trend specified by the researcher.


// Lastly: nonlinear violations of pre-trends
mata st_matrix("deltaquad", 0.024 * ((-4::3) :- (-1)):^2)
pretrends, pre(1/3) post(4/7)   deltatrue(deltaquad) coefplot

**************************************
*                                    *
*             HonestDiD              *
*                                    *
**************************************

// https://github.com/mcaceresb/stata-honestdid

* Install here coefplot, ftools, reghdfe, plot scheme
local github https://raw.githubusercontent.com
ssc install coefplot,      replace
ssc install ftools,        replace
ssc install reghdfe,       replace
net install scheme-modern, replace from(`github'/mdroste/stata-scheme-modern/master)
set scheme modern

* Load data
local mixtape https://raw.githubusercontent.com/Mixtape-Sessions
use `mixtape'/Advanced-DID/main/Exercises/Data/ehec_data.dta, clear
l in 1/5

* Keep years before 2016. Drop the 2016 cohort
keep if (year < 2016) & (missing(yexp2) | (yexp2 != 2015))

* Create a treatment dummy
gen byte D = (yexp2 == 2014)
gen `:type year' Dyear = cond(D, year, 2013)

* Run the TWFE spec
reghdfe dins b2013.Dyear, absorb(stfips year) cluster(stfips) noconstant

// Look at this new way of specifying event-studies:
// the b2013.Dyear term tells stata to treat the observations in variable 'Dyear' that have a value of 2013 as the "base" (hence the b). This means that stata will omit those observations from the regression (this is akin to setting the time*treatment indicator variable to be equal to 1). so b2013.Dyear tells stata to treat Dyear as a factor variable, and use 2013 as the omitted category.

local plotopts ytitle("Estimate and 95% Conf. Int.") title("Effect on dins")
coefplot, vertical yline(0) ciopts(recast(rcap)) xlabel(,angle(45)) `plotopts'


// Now honestdid

honestdid, pre(1/5) post(7/8) mvec(0.5(0.5)2)

// honestdid, pre(1 2 3 4 5) post(7 8) mvec(0.5(0.5)2) // yields the same results.

honestdid, coefplot cached

local plotopts xtitle(Mbar) ytitle(95% Robust CI)
honestdid, cached coefplot `plotopts'

// But how do we interpret this?
// In all the cases in the plot, the honestdid shows a robust conf. interval for different values of M. 
// We see that the "breakdown value" for a significant effect is ≈2, which  means that the significant result is robust to allowing for violations of parallel trends up to twice as big as the max. violation in the pre-treatment period.


// On the other hand, instead of looking at the magniture of the violation of the parallel trends, one could consider the slope of the difference in coefficients across consecutive periods.

local plotopts xtitle(M) ytitle(95% Robust CI)
honestdid, pre(1/5) post(6/7) mvec(0(0.01)0.05) delta(sd) omit coefplot `plotopts'
// We're specifying that here by adding the delta(sd) part of the command,

// Here we see that the breakdown value for a significant effect is ≈ 0.03, meaning that we can reject a null effect unless we are willing to allow for the linear extrapolation across consecutive periods to be off by more than 0.03 percentage points.

// The above command looks at the period immidiately after tretment. To impose restrictions over the average effect:

matrix l_vec = 0.5 \ 0.5
local plotopts xtitle(Mbar) ytitle(95% Robust CI)
honestdid, l_vec(l_vec) pre(1/5) post(6/7) mvec(0(0.5)2) omit coefplot `plotopts'


**************************************
*                                    *
*             Staggered              *
*                                    *
**************************************

// https://github.com/mcaceresb/stata-staggered#readme

// The staggered package computes the efficient estimator for settings with randomized treatment timing, based on the theoretical results in Roth and Sant'Anna (2023). If units are randomly (or quasi-randomly) assigned to begin treatment at different dates, the efficient estimator can potentially offer substantial gains over methods that only impose parallel trends. The package also allows for calculating the generalized difference-in-differences estimators of Callaway and Sant'Anna (2020) and Sun and Abraham (2020) and the simple-difference-in-means as special cases. 

// The data contains a balanced panel of police officers in Chicago who were randomly given a procedural justice training on different dates.

* load the officer data
use https://github.com/mcaceresb/stata-staggered/raw/main/test/pj_officer_level_balanced.dta, clear


* Calculate efficient estimator for the simple weighted average
staggered complaints, i(uid) t(period) g(first_trained) estimand(simple)

* Calculate efficient estimator for the cohort weighted average
staggered complaints, i(uid) t(period) g(first_trained) estimand(cohort)

* Calculate efficient estimator for the calendar weighted average
staggered complaints, i(uid) t(period) g(first_trained) estimand(calendar)

* Calculate event-study coefficients for the first 24 months (month 0 is
* instantaneous effect)
staggered complaints, i(uid) t(period) g(first_trained) estimand(eventstudy) eventTime(0/23)

tempname CI b
mata st_matrix("`CI'", st_matrix("r(table)")[5::6, .])
mata st_matrix("`b'",  st_matrix("e(b)"))
matrix colnames `CI' = `:rownames e(thetastar)'
matrix colnames `b'  = `:rownames e(thetastar)'
coefplot matrix(`b'), ci(`CI') vertical yline(0)


staggered complaints, i(uid) t(period) g(first_trained) estimand(eventstudy simple) eventTime(0/4) num_fisher(500)


* Calculate Callaway and Sant'Anna estimator for the simple weighted average
staggered complaints, i(uid) t(period) g(first_trained) estimand(simple) cs

* Calculate Sun and Abraham estimator for the simple weighted average
staggered complaints, i(uid) t(period) g(first_trained) estimand(simple) sa
