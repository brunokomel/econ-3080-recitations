**************************************
*                                    *
*                                    *
*            Recitation 9            *
*                                    *
*                                    *
**************************************

// Date: 3/22/23
// By: Bruno Kömel

use https://github.com/scunning1975/mixtape/raw/master/judge_fe.dta, clear
 
global judge_pre judge_pre_1 judge_pre_2 judge_pre_3 judge_pre_4 judge_pre_5 judge_pre_6 judge_pre_7 judge_pre_8
global demo black age male white 
global off      fel mis sum F1 F2 F3 F M1 M2 M3 M 
global prior priorCases priorWI5 prior_felChar  prior_guilt onePrior threePriors
global control2     day day2 day3  bailDate t1 t2 t3 t4 t5 t6
global control3 possess robbery DUI1st drugSell aggAss
global control4  $control3 $demo $prior $off

* Naive OLS
* minimum controls
eststo olsa: reg guilt jail3 $control2, robust
* maximum controls
eststo olsb: reg guilt jail3 $control2 $control4 , robust

* First stage
reg jail3 $judge_pre $control2, robust
reg guilt jail3 $control2 $control4 , robust


** Instrumental variables estimation
* 2sls main results
* minimum controls
eststo iva: ivreg2 guilt (jail3= $judge_pre) $control2, robust first
* maximum controls
eststo ivb: ivreg2 guilt (jail3= $judge_pre) $control2 $control4  , robust first

* JIVE main results
* jive can be installed using: net from https://www.stata-journal.com/software/sj6-3/
* net install st0108

* net install st0108 // This didn't work for me, so try the line below
* findit jive and install the st018.pkg 

* minimum controls
eststo jivea: jive guilt (jail3= $judge_pre) $control2, robust
	estadd local conts "Basic"
* maximum controls
eststo jiveb: jive guilt (jail3= $judge_pre) $control2 $control4 , robust
	estadd local conts "Full"

global latex "/Users/brunokomel/Library/CloudStorage/Dropbox/Apps/Overleaf/Recitation - Tables"
cd "${latex}"

// Using this method we get pretty close results!
esttab olsa olsb using "table1.tex",  sfmt(4) b(3) se(2) keep(jail3)  label noobs compress ///
prehead("\centering") posthead("\hline \\ \multicolumn{2}{c}{\textbf{Panel A: OLS}}\\\\ [-1ex]") ///
fragment replace

esttab iv* using "table1.tex",  sfmt(4) b(3) se(2) keep(jail3)  label noobs nomtitles booktabs nonumbers compress /// 
posthead("\hline \\ \multicolumn{2}{c}{\textbf{Panel B: 2SLS}}\\\\ [-1ex] ") ///
fragment append

 
esttab jive* using "table1.tex",  sfmt(4) b(3) se(2) keep(jail3)  label scalars("N Observations" "conts Controls") nomtitles booktabs nonumbers  compress /// 
posthead("\hline \\ \multicolumn{2}{c}{\textbf{Panel C: JIVE}}\\\\ [-1ex] ") ///
fragment append

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
/// booktabs apparently helps format it

// noobs tells stata not to show the normal Observation count
// compress : I don't know exactly what it does, but the tables look bad without it
// posthead is some LaTex stuff that I don't really understand, but I copy and edit as I need it
// append here is the key that forces these estimates into the table we previously created, and called "using ..."
// nonumbers takes out the column numbers, which we don't need because we already have them in the table above

// Here is the link to my overleaf file so you can see how I created things

// https://www.overleaf.com/read/dccpcfspcjyw


coefplot ols* iv* jive*, xline(0) 

coefplot (olsa, aseq(OLS - Basic) label(OLS - Basic)) (olsb, aseq(OLS - Full) label(OLS - Full)) (iva, aseq(IV - Basic)label(IV - Basic)) (ivb, aseq(IV - Full) label(IV - Full)) (jivea, aseq(JIVE - Basic) label(JIVE - Basic)) (jiveb, aseq(JIVE - Full) label(JIVE - Full)) , xline(0) vertical keep(jail3)  ciopts(recast(rcap)) aseq swapnames


// Above, you can see that I use aseq() and swapnames. Those are optional, but they define the labels on the 
// x axis.
// ciopts allows you to change the confidenece interval options. rcap gives it the little feet

**********************************
*                                *
*                                *
*            Exercise            *
*                                *
*                                *
**********************************

eststo clear

use https://github.com/scunning1975/mixtape/raw/master/card.dta, clear

// You may find it helpful to create a global for the controls.

* 1. Run an OLS regression of log wages (lwage) on education (educ) controlling for experience (exper), race (black), region (south), marital status (married), and smsa 
* Store your estimates to put it on a table


* 2. Use proximity to school (nearc4) as an instrument for the education (educ) and find the 2SLS estimate of the effect of schooling (educ) on log wages using "college in the county" as an instrument for schooling


* 3. Use the JIVE estimator to estimate the coefficient on education (same as part 2)

* 4. Put your results in a table and export them to latex


* 5. Plot the coefficients as if you were to present these results
