**************************************
*                                    *
*                                    *
*           Recitation 13            *
*                                    *
*                                    *
**************************************

// Date: 4/21/23
// By: Bruno Kömel (ish)

***************************************
*                                     *
*                                     *
*                Lasso                *
*                 for                 *
*              Prediction             *
*                                     *
*                                     *
***************************************

webuse fakesurvey, clear

describe

// Our goal is going to be to try to select variables that predict the response to question 104 

// But how can we assess the importance of the other 160 questions?
// We can use Lasso to assess which variables are useful predictors and which are not

// Since we have a ton of variables, let's use the "vl" commands to help us clean the data (define groups of variables)

vl set , categorical(4) uncertain(19) dummy 



// categorical(4) tells stata that variables with 4 or fewer unique values should be asssigned to the categorical group
// variables with more than 4 unique values should be assigned to the continuous groups
// The uncertain(#) option omits the uncertain groups. Since we have uncertain(19), then the command would put into the vluncertain category, any variable that had between 4 + 1 and 19 unique values (4+1 comes from the categorical(4) command)
// The dummy option creates dummy variables for the categorical variables that are binary

// the command stores the variables in the macros "vlcategorical" and "vlcontinuous"
display "$vlcontinuous"

// Then to see what was categorized as uncertain:
vl list vluncertain

// And to move the variables to the right place
vl move (q18 q35 q63 q93 q103 q111 q112 q120 q132 q157) vlcontinuous
vl move (q104 q106 q107) vlother //put variables that we don't want in the model 

// Then let's define some sets of variables that we can use in the problem
vl create demographics = (gender q3 q4 q5) //define demographics set of variables
vl create factors = vldummy + vlcategorical //define factors as the set of variables containing vldummy and vlcategory 
vl modify factors = factors - demographics //removing the set of demographic variables 
vl substitute idemographics = i.demographics //creating a set of binary variables from the categorical variables in demographics 
vl substitute ifactors = i.factors //creating a set of binary variables from the categorical variables in factors 
di "$ifactors"



// Then, we should split our data into two groups. We'll create a training dataset (which we use to come up with our model) and a testing dataset, which we'll use to test the prediction model we came up with.

splitsample , generate(sample) nsplit(2) rseed(1234)

tab sample

// Now we're finally ready to do use the lasso command.
lasso linear q104  ($idemographics) $ifactors $vlcontinuous if sample == 1, rseed(1234)

// I think by default, Lasso fits 23 models using random values of lambda
// Model 19 Had the largest out of sample R-squared and the smallest cross validation mean prediction error
// So the model with lambda = .168 may be the best for prediction

cvplot

// We can see that the CV function is minimized when lambda = 0.17

eststo cv

lassoknots , display (nonzero osr2 bic) // This outputs information on all the models that were fits

// We may want to choose the model with lowest BIC (here model 14)

lassoselect id = 14

cvplot

// We can see that the cross validation funciton is higher for model 14, (lambda =27). But model 24 has fewer coefficients (28 rather than 49). 

eststo minBIC

// What if we used an adaptive Lasso model instead?

lasso linear q104 ($idemographics) $ifactors $vlcontinuous if sample == 1, selection(adaptive) rseed(1234)

// Now stata ran 2 lasso models, and chose the model ID = 79 because it had the lowest CV mean prediction error (this is the procedure called adaptive lasso, first you find the CV solution, then by chanding the weights on the coefficients you find another lasso that selects a model with fewer variables)

eststo adaptive

// Then, if we want to look at the variables selected, we can use:
lassocoef cv minBIC adaptive, sort(coef, standardized) nofvlabel

// Note here that the "standardized" option means  that the variables with the largest standardized coeficients are listed first (those are the most important variables)

lassogof cv minBIC adaptive, over(sample) postselection // to assess the goodness of fit 

// Note that the minBIC model has the lowest MSE and second highest R-squared


***************************************
*                                     *
*                                     *
*                Lasso                *
*                 for                 *
*              Inference              *
*                                     *
*                                     *
***************************************

// Notice that we haven't talked at all about standard errors?
// Lasso selects variables and estimates cofficients, but it does not concern itself with statistical significance
// What we're going to do is extend Lasso, and do inference on a set of variables of interest. The remaining variables will be treated as control variables and we will not be able to make inferences about these control variables.  

// For continuous variabels we have the following methods:
* doregress: Double selection 
* poregress: Partialing out 
* xporegress: Cross-fit partialing out

// For binary variables we have:
* dslogit
* pologit
* xpoligit 

// We can also do IV regressions with poivregress or xpoivregress

// Interpretation of coefficients is the same

webuse cattaneo2, clear
// Let's look at effect of mother's education and smoking habits on birthweight
describe

// The interactions between variables may be important as well, so we'll include those
// But by the time we include all interactions, we get 104 covariates\
// Good news is that with lasso, we don't need to worry about overfitting the model. 
// Because he control variables we specify are potential control variables. It'll be up to (Ted) Lasso to select the important ones.

vl set 
vl substitute order = i.order##(c.mage#c.fedu c.mage##c.monthslb c.fedu##c.fedu)
vl substitute married = i.mmarried#(c.mage##c.mage)

dsregress bweight i.msmoke medu, ///
controls(i.foreign i.alcohol##i.prenatal1 $married $order)

// Notice 2 things. There were 104 total "eligible" control variables, but lasso selected 15 of them. 
// Second, the result here is that the more a mother smokes, the less the baby weighs (also mother's education is not significant)

// Now say that we think that mother's education is endogenous. Then we could use the cross-fit partialling out method:

xpoivregress bweight i.msmoke (medu = $medu), controls(i.foreign i.alcohol##i.prenatal1 $married $order) // where $medu refers to a set of instruments for mother's education but we don't have that in this data, I just wanted to give an example :) 

//if we wanted instead to fit a model for low birth weight using the binary variable (lbweight) as the outcome, we could use a double-selection lasso logistic regression (or partialling out, but we just did that)

dslogit lbweight i.msmoke medu, controls(i.foreign i.alcohol##i.prenatal1 $married $order)


*********************************
*.            Extra             *
*********************************

// Lasso for Inference // 
use https://www.stata-press.com/data/r16/lassoex, clear

dsregress y d1 d2, controls(x1-x100 i.(f1-f30)) //using double selection method 
disp "`e(controls_sel)'"
local ds `e(controls_sel)'

lasso linear d1 x1-x100 i.(f1-f30), selection(plugin)
disp e(allvars_sel)
local d1 `e(allvars_sel)'

lasso linear d2 x1-x100 i.(f1-f30), selection(plugin)
disp e(allvars_sel)
local d2 `e(allvars_sel)'

lasso linear y x1-x100 i.(f1-f30), selection(plugin) //the last three lassos execute the double selection method "by hand"
disp e(allvars_sel)
local y `e(allvars_sel)'

poregress y d1 d2, controls(x1-x100 i.(f1-f30)) //selection using the partialing out procedure 
disp "`e(controls_sel)'"

xporegress y d1 d2, controls(x1-x100 i.(f1-f30)) //selection using the cross-fit partialling out procedure 
disp "`e(controls_sel)'"
