///////////////////////////
// Introduction to Stata // 
///////////////////////////

* By: Bruno Kömel 
* Date: 10 Jan 2024

** Directories

pwd

cd "~/Documents/Pitt/Year 3/TA - Econ 3080/econ-3080-recitations/Recitation 0 - Intro to Stata"

** Importing data from github (or local machine)
import excel "https://github.com/brunokomel/econ-3080-recitations/raw/main/Recitation%200%20-%20Intro%20to%20Stata/metrics_fall_2023_grades.xlsx", clear

browse


** Initialising dataset ** 
clear //clears data loaded in system, if any  
sysuse auto //loads toy automobile dataset already installed in Stata; for a normal dataset (.dta), "use xyz.dta, replace"


** Structure of Stata Datasets ** 
browse //each observation is a row and each variable is a column 

* Types of variables * 
browse make //string variable 
browse headroom //continuous variable 
browse foreign //categorical variable 

* Missing values *
browse rep78 if rep78 == . //5 observations with no repair record 


** Elements of syntax ** 
summarize price weight //command to display summary statistics 
sum price weight //some commands can be abbreviated, the limit to shortening tends to be about 3 characters 

sum price mpg headroom if foreign == 1 //summary statistics only for foreign makes 
sum price mpg headroom if foreign == 0 //summary statistics only for non-foreign makes 

sum price, detail //the "detail" option gives more moments and parameter values   

bysort foreign: sum price mpg headroom //does the same as above, "bysort" tells Stata to sort by foreign first, then run sum by foreign 


** Commenting ** 
//tab1 price //commenting out a single line 
*tab1 price //does the same thing 

/* Commenting out a block 
tab1 price if foreign == 1 & rep78 != . 
tab1 price if foreign == 0 & rep78 == .  
*/

** Logging output **
log using intro_stata.txt, text replace //opening log file; specifying filename, file format, and replace allows Stata to overwrite old files
tab2 rep78 foreign 
log off //turn off log file temporarily; note log is still open and you'd have to close it before opening a new log file 
tab1 rep78 
log on  //turn on log file 
tab1 foreign, missing
log close //close log file 


** Working with variables ** 
browse make headroom trunk weight length //opens data browser to view these variables 

order foreign price make //defines the order of columns in data browse 
browse

sort rep78 //sort in ascending order of rep78
browse rep78 price make 

duplicates tag gear_ratio, generate(gear_ratio_tag) //generates variable giving information on number of obs with same gear ratio
tab gear_ratio_tag 
sort gear_ratio_tag 
browse make gear_ratio_tag

gen price_thou = price/1000 //gives price in thousands 
replace price_thou = price_thou * 1.15 if foreign == 1 //calculates new price with import tax for foreign cars 

gen honda = strpos(make,"Honda") //binary variable if make is Honda or not 
gen space_pos = strpos(make," ") //gives position of whitespace in make 
gen brand = substr(make,1,space_pos) //brand of car
gen model = substr(make,space_pos,.) //model of car 

egen mprice_rep = mean(price), by(rep78) //calculates mean price in each repair category 

label define repairtimes 1 "One" 2 "Two" 3 "Three" 4 "Four" 5 "Five" //defining label
gen rep78_new = rep78 //copying the same variable to work on so I don't disturb the original data 
label values rep78_new repairtimes //assigning label 
browse rep78_new //notice that the browser shows labels in cells 

preserve //preserve and restore allows you a "pocket" to make changes to the dataset without disrupting the workflow of the do-file 

collapse mprice_rep, by(rep78) //collapse mean prices by repair category 
save mprice_rep.dta, replace 

sysuse auto, clear //opening original auto dataset again 
merge m:1 rep78 using mprice_rep.dta //note that Stata tells you which observations have been successfully matched or not. This information is captured in the variable _merge, to prevent this variable from being created, use option "nogen"

restore 

* Why we want to check for missing values?
gen var1 = . 
replace var1 = 1 if _n > 10
gen var2 = 0 
replace var2 = 1 if var1 > 1 

** Summary Statistics **
sum price mpg trunk weight length //basic summary statistics 

tab rep78 foreign //cross tabulation 

pwcorr price mpg headroom trunk weight length //table of pairwise correlations among variable list 


** Graphs and diagrams ** 
graph twoway scatter weight length 
graph save wl, replace 
graph twoway scatter price mpg 
graph save pm, replace 
graph combine wl.gph pm.gph //combining above two graphs on single diagram 

graph twoway (scatter price mpg) (lfit price mpg) //overlaying scatterplot and regression line 

hist price, freq //empirical dist of price 

graph box price //boxplot of price

graph bar price, by(foreign) //bar graph of mean price by foreign category 


** Hypothesis testing ** 
ttest weight, by(foreign) //domestic cars weigh significantly more 
return list 
power twomeans `r(mu_1)' `r(mu_2)', sd(`r(sd_1)') //calculates sample size for detecting above effect 


** Regression ** 
reg price weight rep78 foreign //regression of price as a function of weight, rep78 and foreign 
reg price weight rep78#foreign //using full set of interactions, note some categories have zero obs 

reg price weight rep78 foreign 
vif //high VIF suggests presence of multicollinearity 
estat hettest //low p-value suggests presence of heteroskedasticity 
gen sample_reg = e(sample) //constructs dummy variable equal to 1 if obs included in regression 


** Loops ** 
foreach v of varlist weight rep78 foreign { //gives you three regressions 
	reg price `v' //v is a local, and to call a local, use `'
}

forvalues i = 1/5 { 
	reg price weight foreign if rep78 == `i'
}

local i = 1
while `i' <= 5 { 
	reg price weight foreign if rep78 == `i'
	local i = `i' + 1 //adds 1 to the local's value 
}

levelsof rep78, local(levels) //constructing a local named "levels" that captures each unique value of rep78
foreach i of local levels { 
	reg price weight foreign if rep78 == `i'
}

* Note: The last three loops do the same thing, but the approach is slightly different. In particular, the levelsof approach works well when the unique values are not in a running sequence e.g. 1, 3, 5, 6, 8


** Common errors ** 
unique make //this command would tell me how many unique values of the variable make there are, but if you haven't used "ssc install unique", this will result in an error "command unique is unrecognized"

gen make_new = make + 2 //make is a string variable, so you can't add 2 to it. This will result in a "type mismatch" error. 

gen newvar = . //generating a new variable with all missing observations 
reg price newvar weight //a regression cannot be executed because one of the variables contains all missing values, so there are no observations that can be used for the regression. This results in a "no observations" error 


** Other useful functions of Stata ** 

* Postestimation results retrieval * 
reg price weight foreign 
ereturn list //tells you the captured postestimation results 
matrix list e(b) //displays vector containing estimated coefficients 
disp e(b)[1,1] //displays first element of the above vector 


* Run quietly * 
quietly reg price weight foreign //stata runs this, and postestimation results are kept, but output is not displayed. Useful when running many regressions 

* Collapse *
preserve 

collapse (mean) price weight foreign (median) m_price = price, by(rep78) //collapses dataset into summary statistics 

restore 




























