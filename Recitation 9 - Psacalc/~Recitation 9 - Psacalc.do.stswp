**************************************
*                                    *
*                                    *
*           Recitation 9             *
*                                    *
*                                    *
**************************************

// Date: 3/6/24
// By: Bruno Kömel

// We'll be using data from 

// Unobservable Selection and Coefficient Stability: Theory and Evidence
// By Emily Oster (2019)
// https://doi.org/10.1080/07350015.2016.1227711

help psacalc

// psacalc -- Calculate treatment effects and relative degree of selection under proportional selection of observables and unobservables

// In all of this, the key is to focus on the values of delta. 
// If delta is very small (below 1), then it would be very easy for unobservables to bias the estimated coefficient down to 0. if delta is very big (above 1), then it would be relatively difficult for there to exist unobservables that would depress the coefficient down to 0. If delta is right at one, then you'll gain more information by monitoring R^2. If R^2 is low, with a delta = 1, then you probably have relatively bad selection.

********************************
*                              *
*         Proportional         *
*                              *
********************************

quietly {
	clear
	local cov_x_w1=.2
	local varc1=1
	local varw=10
	local delta=1
	local cov_x_c1=((`delta'*`varc1'*`cov_x_w1')/`varw')


	matrix B = [1, `cov_x_w1', `cov_x_c1'\ `cov_x_w1', `varw', 0\ `cov_x_c1',0,`varc1' ]

	matlist B
	
	
	corr2data X W1 C1, n(30000) cov(B) means(1,1,1) // This creates a dataset with a specified correlation structure
	set seed 25813495
	gen y_error=rnormal()

	local beta=0

	gen Y = `beta'*X+W1+C1
	}
	
		
reg Y X
	
reg Y X C1 // you can see that if we include C1 in the regression, the coefficient on X doesn't change much
psacalc beta X, delta(1) //Note here that psacalc fixes the problem
psacalc delta X  // Note that delta = 1, but we know that the coefficient is biased. We could notice that there is evide nce of biased by looking at the low R^2.
	
reg Y X W1 // But when we include the variable with high variance, the coefficient goes away
psacalc beta X // Again, psacalc gives the right answer (but it was easier this time)
psacalc delta X // Here, however, we have delta = 1, but very high R^2, so selection is probably not an issue.
	
reg Y X C1 W1
psacalc beta X


// What if we change some stuff? How does psacalc do?

quietly {
	clear
	local cov_x_w1=.2
	local varc1=1
	local varw=10
	local delta=3 // change the delta to 3
	local cov_x_c1=((`delta'*`varc1'*`cov_x_w1')/`varw')


	matrix B = [1, `cov_x_w1', `cov_x_c1'\ `cov_x_w1', `varw', 0\ `cov_x_c1',0,`varc1' ]

	matlist B
	
	
	corr2data X W1 C1, n(30000) cov(B) means(1,1,1) 
set seed 25813495
	gen y_error=rnormal()

	local beta=10 // change the coefficient on X to be 10

	gen Y = `beta'*X+W1+C1
	}
	
		
reg Y X
	
reg Y X C1 // again, you can see that if we include C1 in the regression, the coefficient on X doesn't change much
psacalc beta X //Note here that psacalc does not fix the problem
psacalc delta X // and it also doesn't give us the right delta (it should be 1/3 here), but it does say that delta would have to be really high (2.385) to make the coefficient = 0. So we can be comfortable that even if there is bias, it wouldn't kill the treatment effect. 
	
	// But if we know the answer, we can fix it to be perfect:
psacalc beta X, delta(0.3333333)
psacalc delta X, beta(10)
	
	
	
reg Y X W1 // But when we include the variable with high variance, the coefficient is pretty close to right
psacalc beta X // psacalc does a pretty good job here, but we didn't really need it anyway
psacalc delta X // . Delta is supposed to be 3, but again this would lead us to conclude that we would need massive selection to make the treatment effect = 0.
	
	// But if we know the answer, we can fix it (of course):
psacalc delta X, beta(10)
	
********************************
*                              *
*       Not Proportional       *
*                              *
********************************
	
// But what if the degree of selection is not proportional?	
	
clear
capture log close
set obs 1000 // this tells stata to generate 1000 observations when creating variables
set seed 824 // #Kobe

gen educ = rgamma(7.5,1)

gen c = rnormal(5, 1) + educ
replace c=0 if c < 0

gen w = rnormal(10, 10)*educ
replace w=0 if w < 0 

reg educ c
scalar cb = _b[c]

reg educ w
scalar wb = _b[w]

scalar delta = wb/cb
scalar delta_inv = cb/wb

gen z = rnormal(1, 2)

twoway (hist educ) (hist c , color(orange)) (hist w, color(green) ) , legend(order(1 "educ" 2 "x" 3 "w" ))

gen y = 10 + 30*educ + 1.5*c + 3*w + rnormal(0,1)

reg y educ 

reg y educ c


psacalc beta educ // psacalc beta is pretty much useless here
psacalc delta educ // and it doesn't really help with the delta, but this does show that we would not need large selection (only 0.07220) in order to make the coefficient = 0. So omitted variables may be a real issue here. (and it is)


reg y educ w

psacalc beta educ
psacalc delta educ // 7.5 is not the inverse of the delta that we got above, but it is way larger than 1, so we conclude it's unlikely that selection on unobservables would nullify the result.

di delta_inv

// You can also bootsrap stuff if you'd like
bs r(delta), rep(100): psacalc delta educ, model(reg y educ c)
bs r(beta), rep(100): psacalc beta educ, model(reg y educ c)

/// Last thing, you can select a variable for which you always control

reg y educ c z

psacalc beta educ, mcontrol(z)

/// Another example of the code, just to show that it works with xtreg and areg
clear

webuse nlswork 
xtset idcode

xtreg ln_w grade age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure c.tenure#c.tenure 2.race not_smsa south, fe

psacalc beta south

areg ln_w grade age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure c.tenure#c.tenure 2.race not_smsa south, absorb(idcode)

psacalc beta south


********************************
*                              *
*      Empirical Example       *
*                              *
********************************

use "/Users/brunokomel/Documents/Pitt/Year_2/TA - Econ 3080/Recitations/Recitation 11 - Psacalc/Recitation 11 Handout/Nunn_Wantchekon_AER_2011.dta", clear


egen group=group(isocode)
drop isocode
rename group isocode
	
global baseline_controls "age age2 male urban_dum i.education i.occupation i.religion i.living_conditions district_ethnic_frac frac_ethnicity_in_district i.isocode"

global colonial_controls "malaria_ecology total_missions_area explorer_contact railway_contact cities_1400_dum i.v30 v33"

	
// Unrestricted 

xi: reg trust_relatives ln_export_area $baseline_controls $colonial_controls ln_init_pop_density, cluster(murdock_name)
predict hat if e(sample)
	drop if hat ==.
	global beta_tilde = _b[ln_export_area]
	global r_tilde = e(r2)
	global se_tilde = _se[ln_export_area]
	

xi: reg trust_relatives ln_export_area i.isocode, cluster(murdock_name)
	global beta_dot = _b[ln_export_area]
	global r_dot = e(r2)


sum trust_relatives
	global yvar = r(Var)
	
	reg ln_export_area i.isocode
	predict xhat, resid
	sum xhat
	global xvar =r(Var)
	drop xhat
	
	reg ln_export_area i.isocode $baseline_controls $colonial_controls ln_init_pop_density
	predict xhat, resid
	sum xhat
	global taux =r(Var)
	drop xhat


psacalci $beta_dot $r_dot  $beta_tilde $r_tilde $yvar $xvar $taux beta, rmax(0.975) delta(1)

psacalci $beta_dot $r_dot  $beta_tilde $r_tilde $yvar $xvar $taux beta, rmax(.25) delta(1)


xi: reg trust_relatives ln_export_area $baseline_controls $colonial_controls ln_init_pop_density, cluster(murdock_name)

psacalc beta ln_export_area 
psacalc delta ln_export_area // delta is very small so it would not take a lot of selection on unobservables to make the treatment effect = 0

*********** Row 2
drop hat

xi: reg trust_neighbors ln_export_area $baseline_controls $colonial_controls ln_init_pop_density, cluster(murdock_name)
predict hat if e(sample)
	drop if hat ==.
	global beta_tilde = _b[ln_export_area]
	global r_tilde = e(r2)
	global se_tilde = _se[ln_export_area]
	

// Unrestricted 
xi: reg trust_neighbors ln_export_area i.isocode, cluster(murdock_name)
	global beta_dot = _b[ln_export_area]
	global r_dot = e(r2)



sum trust_relatives
	global yvar = r(Var)
	
	reg ln_export_area i.isocode
	predict xhat, resid
	sum xhat
	global xvar =r(Var)
	drop xhat
	
	reg ln_export_area i.isocode $baseline_controls $colonial_controls ln_init_pop_density
	predict xhat, resid
	sum xhat
	global taux =r(Var)
	drop xhat


psacalci $beta_dot $r_dot  $beta_tilde $r_tilde $yvar $xvar $taux beta, rmax(0.4) delta(1)

psacalci $beta_dot $r_dot  $beta_tilde $r_tilde $yvar $xvar $taux beta, rmax(.363) delta(1)
