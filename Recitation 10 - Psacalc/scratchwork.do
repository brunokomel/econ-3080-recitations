
program nunn_want

	
	use $inputecon\Nunn_and_Wantchekon_2011.dta, clear
	
	egen group=group(isocode)
	drop isocode
	rename group isocode
	foreach var in trust_relative trust_neighbors trust_local_council intra_group_trust inter_group_trust
	
foreach var in trust_relative {
	
//preserve
	
	global baseline_controls "age age2 male urban_dum i.education i.occupation i.religion i.living_conditions district_ethnic_frac frac_ethnicity_in_district i.isocode"
	global colonial_controls "malaria_ecology total_missions_area explorer_contact railway_contact cities_1400_dum i.v30 v33"

	xi: reg `var' ln_export_area $baseline_controls `colonial_controls' ln_init_pop_density, cluster(murdock_name)
	predict hat if e(sample)
	drop if hat ==.
	global beta_tilde = _b[ln_export_area]
	global r_tilde = e(r2)
	global se_tilde = _se[ln_export_area]
	
	* Unrestricted #1
	xi: reg `var' ln_export_area i.isocode, cluster(murdock_name)
	global beta_hat = _b[ln_export_area]
	global r_hat = e(r2)
	
	sum `var'
	global yvar = r(Var)
	
	reg ln_export_area i.isocode
	predict xhat, resid
	sum xhat
	global xvar =r(Var)
	drop xhat
	
	reg ln_export_area i.isocode `baseline_controls' `colonial_controls' ln_init_pop_density
	predict xhat, resid
	sum xhat
	global taux =r(Var)
	drop xhat
	
	//append_to_file "NunnWant" 0 1 1 
	//restore
	}
	
		

end


// Unrestricted 
xi: reg trust_relatives ln_export_area i.isocode, cluster(murdock_name)
	global beta_dot = _b[ln_export_area]
	global r_dot = e(r2)

xi: reg trust_relatives ln_export_area $baseline_controls $colonial_controls ln_init_pop_density, cluster(murdock_name)
predict hat if e(sample)
	drop if hat ==.
	global beta_tilde = _b[ln_export_area]
	global r_tilde = e(r2)
	global se_tilde = _se[ln_export_area]
	

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

global r_col3 = $r_tilde + $r_tilde - $r_dot


	use $inputfilename\econ_results.dta, clear
	drop if sign(beta_dot)~=sign(beta_tilde)
	drop if taux==.
	keep if randomized==0
	keep if fits_stability==1
	gen l1=abs(beta_dot)
	gen l2=abs(beta_tilde)
	global errbar = 1.64
	gen temp1=abs(beta_tilde)
	gen not_reject=temp1<1.96*se_tilde
	drop temp1
	drop id
	egen id = fill(1 2 3 4)
	sum id

	local obs_count = r(N)
	gen beta_max = .
	forvalues id_count = 1/`obs_count' {
		foreach var in beta_dot beta_tilde r_dot r_tilde yvar xvar taux {
			sum `var' if id==`id_count'
			local `var'=r(mean)
		}

		psacalci `beta_dot' `beta_tilde' `r_dot' `r_tilde' `yvar' `xvar' `taux' beta, rmax(1) delta(1)
		replace beta_max=r(output) if id==`id_count'	
	}

	gen rejzero_max=sign(beta_max)==sign(beta_tilde)
	
	replace rejzero_max=. if l2>l1
	replace rejzero_max = . if not_reject==1
	gen matchconf_max = beta_max>beta_tilde -$errbar*se_tilde & beta_max<beta_tilde+$errbar*se_tilde
	
************************************************************

	
	forvalues i=2/1001 {
	
		local j=(`i'-1)*.05
		
		gen rmax_temp=r_tilde+`j'*(r_tilde-r_dot)
		replace rmax_temp=1 if rmax_temp>1
		forvalues id_count=1/`obs_count' {
		sum rmax_temp if id==`id_count'
		local rmax_value = r(mean)

		foreach var in beta_dot beta_tilde r_dot r_tilde yvar xvar taux {
			sum `var' if id==`id_count'
			local `var'=r(mean)
		}
		di `rmax_value'
		psacalci `beta_dot' `beta_tilde' `r_dot' `r_tilde' `yvar' `xvar' `taux' beta, rmax(`rmax_value') delta(1)
		replace beta_`i'=r(output) if id==`id_count'
}
		replace beta_`i' = beta_tilde if beta_dot==beta_tilde
		gen rejzero_`i'=sign(beta_`i')==sign(beta_tilde)
		replace rejzero_`i'=. if l2>l1
		replace rejzero_`i'=. if not_reject==1
		gen matchconf_`i' = beta_`i'>beta_tilde -$errbar*se_tilde & beta_`i'<beta_tilde+$errbar*se_tilde
		drop rmax_temp
}		


// Unrestricted 
xi: reg trust_neighbors ln_export_area i.isocode, cluster(murdock_name)
	global beta_dot = _b[ln_export_area]
	global r_dot = e(r2)

xi: reg trust_neighbors ln_export_area $baseline_controls $colonial_controls ln_init_pop_density, cluster(murdock_name)
predict hat if e(sample)
	drop if hat ==.
	global beta_tilde = _b[ln_export_area]
	global r_tilde = e(r2)
	global se_tilde = _se[ln_export_area]
	

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
