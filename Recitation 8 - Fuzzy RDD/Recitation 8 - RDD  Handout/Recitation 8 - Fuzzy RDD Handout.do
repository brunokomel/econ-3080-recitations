**************************************
*                                    *
*                                    *
*            Recitation 8            *
*                                    *
*                                    *
**************************************

// Date: 2/28/23
// By: Bruno Kömel

global recitation "~/Documents/Pitt/Year_2/TA - Econ 3080/Recitations/Recitation 8 - Fuzzy RDD"
cd "${recitation}"

// Thanks to https://evalf20.classes.andrewheiss.com/example/rdd-fuzzy/#fuzzy-parametric-estimation for this
import delimited "tutoring_program_fuzzy.csv", clear 

//Here's the setting:
* Students take an entrance exam at the beginning of the school year
* If they score 70 or below, they are enrolled in a free tutoring program
* BUT we have some non-compliers. Both always takers and never takers.
* Students take an exit exam at the end of the year

// So, let's take a look at what we have:
xi: twoway scatter i.tutoring_text entrance_exam, xline(70, lcolor(red)) 
// The first thing that we can notice is that the cutoff is not strict. There are observations on both sides of the cutoff that fall in either category.

// Next, we should try to get an idea of how many people are in each group (compliers, non-compliers, etc)
// Let's generate a dummy for the "treatment," which would have been assigned if we had a sharp RDD
gen below_cutoff = 0
replace below_cutoff = 1 if entrance_exam <= 70	

tab tutoring, gen(tutoring)

bysort below_cutoff tutoring2: sum tutoring2


// Let's see if we can find some discontinuity in the plots?
twoway (scatter exit_exam entrance_exam if tutoring2 == 1 ) ///
	(scatter exit_exam entrance_exam if tutoring2 == 0) ///
	(lfitci  exit_exam entrance_exam if tutoring2 == 1& entrance_exam <= 70 , ciplot(rline) color(red)) ///
	(lfitci  exit_exam entrance_exam if tutoring2 == 1& entrance_exam > 70 , ciplot(rline) color(red)) ///
	(lfitci  exit_exam entrance_exam if tutoring2 == 0& entrance_exam <= 70 ,  ciplot(rarea) color(green)) ///
	(lfitci  exit_exam entrance_exam if tutoring2 == 0& entrance_exam > 70 , ciplot(rarea) color(green)), /// 
	legend(lab(1 "With Tutoring") lab(2 "No Tutoring") lab(4 "Tutoring Below Fit.") ///
	lab(6 "Tutoring Above Fit.") lab(8 "No Tut. Below Fit.") lab(10 "No Tut. Above Fit."))

	
// Next, just so we can get an idea of how many compliers, and non-compliers we have, let's plot this differently. 
// Here I want to see the probability of receiving tutoring for the different socres that people received, using bins of 5 points each.

///forvalues i = 25(5)95{
///	local j = `i'+5
///	gen entrance_score_`i'_`j' =0
///	replace entrance_score_`i'_`j' = 1 if entrance_exam > `i' & entrance_exam <= `i'+5
///}

// To use the twoway bar command, we need to create a categorical variable for each score bin
gen entr_score_cat =0

forvalues i = 25(5)95{
	replace entr_score_cat = `i'/5 - 5 if entrance_exam > `i' & entrance_exam <= `i'+5
}

gen cat1=(inrange(entrance_exam,51,55))

// And add a label so it looks slightly better
forvalues i = 25(5)95{
	label define entr_score_cat_lab `=`i'/5 - 5' "`=`i'+1' - `=`i'+5'" , add	
}


// I want to highlight what we're doing here, because it's not trivial.
// Using the index `i' inside the loop tells stata to use whatever value of `i' is currently "running" in the loop.
// But what if you want a lagged index value? Or one with a lead?
// Then you need to use `= `i' + 1' . Where you're basically running a small equation inside the ` ' 


label values entr_score_cat entr_score_cat_lab

// And to get the probability, we need to generate a "frequency" by taking the mean of the dummy variable over the number of observarions in each category
egen frequency = mean(tutoring2), by(entr_score_cat)

graph bar tutoring2, over(entr_score_cat, gap(100)) outergap(*1.2) ytitle("Probability of Receiving Tutoring")

twoway (bar frequency  entr_score_cat,  xline(8.5, lwidth(thick) lcolor(red)) xlabel(0(1)14,valuelabel alternate) barwidth(0.8)  ytitle("Probability of Receiving Tutoring") xtitle("Entrance Exam Score") )

// The key here is that some students above the cut-off receive tutoring, and some below the cut-off do not

// Next, let's recenter our running variable
gen entrance_centered = entrance_exam - 70

// recall we've generated below_cutoff

// Let's pretend this is a sharp RDD scenario:
// first let's label some stuff
label variable exit_exam "Exit Exam"
label variable tutoring2 "Received Tutoring"

// And let's store our regressions to create a nice table 
eststo OLS: reg exit_exam entrance_centered tutoring2 if (entrance_centered >= -10 & entrance_centered <=10)
	estadd scalar BW = 10
// In this case we'd estimate an effect of 11.48
// Note that I want to keep track of the size of the bandwidth for each of these regressions

/// ssc install ivreg2
/// ssc install ranktest

eststo IV: ivreg2 exit_exam entrance_centered ( tutoring2 = below_cutoff )  if (entrance_centered >= -10 & entrance_centered <=10), robust 
	estadd scalar BW = 10
// Now the coefficeint dropped to 9.74. This is the effect on compliers in the bandwidth (which we chose)

eststo RDrob: rdrobust exit_exam entrance_centered, fuzzy(tutoring2) c(0)
	estadd scalar BW = e(h_r)
// And here it's pretty close to the 2sls	
// Note that you do not need to specify an insrtument with rdrobust.
	

global latex "/Users/brunokomel/Library/CloudStorage/Dropbox/Apps/Overleaf/Recitation - Tables"
cd "${latex}"

// Using this method we get pretty close results!
esttab OLS IV RDrob using "table1.tex",  sfmt(4) b(3) se(2) keep(tutoring2 RD_Estimate) varlabel(RD_Estimate "Received Tutoring (Non-Parametric)") label mtitles("OLS" "2SLS" "RD Robust") scalars("N Observations" "BW Bandwidth Choice") fragment replace

/// Here, esttab will tell stata to compile your table
/// using creates, or overwrites, a .tex file where your table will go (it'll go to the working directory)
/// sfmt(x) will tell stata to show x characters after the decimal point for the "general table values" (catch-all)
/// b(x) will tell stata to show x characters after the decimal point for the BETA coefficients
/// se(x) will tell stata to show x characters after the decimal point for the STANDARD ERROS
/// varlabel(z " Z " ) tells stata to label, on the table, the variable z as " Z "
/// label tells stata to use the labels of the variables that have labels
/// mtitles("Col 1 " "Col 2" ...) assigns column titles to each of the estimates that you stored and appended
/// scalars("X Name of X you want" ...) tells stata to output the stored scalar/local "X" and give it the name that you want 
/// fragment tells stata that there will be more esttab's coming to append a table, and it removes some automatic things (like star captions)
/// replace will automatically save over the table that you previously created


**********************************
*                                *
*                                *
*            Exercise            *
*                                *
*                                *
**********************************

// From Vincent Ponz and Clemente Tricaud's papper "Expressive Voting and its Cost: Evidence from Runoffs With Two or Three Candidates"
// Econometrica 2018
//https://www.econometricsociety.org/publications/econometrica/2018/09/01/expressive-voting-and-its-cost-evidence-runoffs-two-or-three
cd "${recitation}"

use analysis.dta, clear

// Let's simplify by only keeping the stuff we're going to use
keep  prop_registered_turnout_R2 running treatment assignment prop_registered_blanknull_R2 prop_registered_candvotes_R2 year prop_registered_votes_cand3_R1

rename prop_registered_votes_cand3_R1 running_uncentered
rename prop_registered_turnout_R2 turnout
rename prop_registered_blanknull_R2 blanknull
rename prop_registered_candvotes_R2 candvotes


// To do:
**** 1. Replicate and generate table 3, then add a panel below using the 2sls estimates
**** Careful to add each of the estimates in there (number of obs, pvalues, etc)
**** And output the data to a .tex file
**** 2. AND run a 4th analysis, this time controlling for a dummy variable for the year


**** 3. Run the same 4 analyses, but this time using ivreg2, and using a bandwidth of 0.02

























