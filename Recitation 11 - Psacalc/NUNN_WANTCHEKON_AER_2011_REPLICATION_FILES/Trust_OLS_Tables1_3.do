version 11.1
clear all
set more off
capture log close

set mem 300m
set matsize 6000

log using "Trust_OLS_Tables1_3.log", replace

use "Nunn_Wantchekon_AER_2011.dta", clear

global baseline_controls "age age2 male urban_dum i.education i.occupation i.religion i.living_conditions district_ethnic_frac frac_ethnicity_in_district i.isocode"
global colonial_controls "malaria_ecology total_missions_area explorer_contact railway_contact cities_1400_dum i.v30 v33"

********************************
*** Table 1: Trust Neighbors ***
********************************

*** Slave exports only ***
xi: reg trust_neighbors exports `baseline_controls', cluster(murdock_name)
xi: cgmreg trust_neighbors exports `baseline_controls', cluster(murdock_name district)
*** Slave exports/land area ***
xi: reg trust_neighbors export_area `baseline_controls', cluster(murdock_name)
xi: cgmreg trust_neighbors export_area `baseline_controls', cluster(murdock_name district)
*** slave exports/historic pop ***
xi: reg trust_neighbors export_pop `baseline_controls', cluster(murdock_name)
xi: cgmreg trust_neighbors export_pop `baseline_controls', cluster(murdock_name district)
*** ln slave exports ***
xi: reg trust_neighbors ln_exports `baseline_controls', cluster(murdock_name)
xi: cgmreg trust_neighbors ln_exports `baseline_controls', cluster(murdock_name district)
*** ln slave exports/land area ***
xi: reg trust_neighbors ln_export_area `baseline_controls', cluster(murdock_name)
xi: cgmreg trust_neighbors ln_export_area `baseline_controls', cluster(murdock_name district)
*** ln slave exports/historic pop ***
xi: reg trust_neighbors ln_export_pop `baseline_controls', cluster(murdock_name)
xi: cgmreg trust_neighbors ln_export_pop `baseline_controls', cluster(murdock_name district)

/* Regressions to get number of clusters info (since CGM ado file does not handle this properly) */
*** Slave exports only ***
xi: reg trust_neighbors exports `baseline_controls', cluster(murdock_name)
xi: reg trust_neighbors exports `baseline_controls', cluster(district)
*** Slave exports/land area ***
xi: reg trust_neighbors export_area `baseline_controls', cluster(murdock_name)
xi: reg trust_neighbors export_area `baseline_controls', cluster(district)
*** slave exports/historic pop ***
xi: reg trust_neighbors export_pop `baseline_controls', cluster(murdock_name)
xi: reg trust_neighbors export_pop `baseline_controls', cluster(district)
*** ln slave exports ***
xi: reg trust_neighbors ln_exports `baseline_controls', cluster(murdock_name)
xi: reg trust_neighbors ln_exports `baseline_controls', cluster(district)
*** ln slave exports/land area ***
xi: reg trust_neighbors ln_export_area `baseline_controls', cluster(murdock_name)
xi: reg trust_neighbors ln_export_area `baseline_controls', cluster(district)
*** ln slave exports/historic pop ***
xi: reg trust_neighbors ln_export_pop `baseline_controls', cluster(murdock_name)
xi: reg trust_neighbors ln_export_pop `baseline_controls', cluster(district)


***********************************
*** Table 2: All Trust Measures ***
***********************************

*** Relatives Trust ***
xi: cgmreg trust_relatives ln_export_area `baseline_controls', cluster(murdock_name district)
*** Neighbors Trust ***
xi: cgmreg trust_neighbors ln_export_area `baseline_controls', cluster(murdock_name district)
*** Trust Local Council ***
xi: cgmreg trust_local_council ln_export_area `baseline_controls', cluster(murdock_name district)
*** Intra Group Trust ***
xi: cgmreg intra_group_trust ln_export_area `baseline_controls', cluster(murdock_name district)
*** Inter Group Trust ***
xi: cgmreg inter_group_trust ln_export_area `baseline_controls', cluster(murdock_name district)

/* Regressions to get number of clusters info  (since CGM ado file does not handle this properly) */
*** Relatives Trust ***
xi: reg trust_relatives ln_export_area `baseline_controls', cluster(murdock_name)
xi: reg trust_relatives ln_export_area `baseline_controls', cluster(district)
*** Neighbors Trust ***
xi: reg trust_neighbors ln_export_area `baseline_controls', cluster(murdock_name)
xi: reg trust_neighbors ln_export_area `baseline_controls', cluster(district)
*** Trust Local Council ***
xi: reg trust_local_council ln_export_area `baseline_controls', cluster(murdock_name)
xi: reg trust_local_council ln_export_area `baseline_controls', cluster(district)
*** Intra Group Trust ***
xi: reg intra_group_trust ln_export_area `baseline_controls', cluster(murdock_name)
xi: reg intra_group_trust ln_export_area `baseline_controls', cluster(district)
*** Inter Group Trust ***
xi: reg inter_group_trust ln_export_area `baseline_controls', cluster(murdock_name)
xi: reg inter_group_trust ln_export_area `baseline_controls', cluster(district)


********************************************************
*** Table 3: All Trust Measures, Additional Controls ***
********************************************************

*** Relatives Trust ***
xi: cgmreg trust_relatives ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name district)
*** Neighbors Trust ***
xi: cgmreg trust_neighbors ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name district)
*** Trust Local Council ***
xi: cgmreg trust_local_council ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name district)
*** Intra Group Trust ***
xi: cgmreg intra_group_trust ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name district)
*** Inter Group Trust ***
xi: cgmreg inter_group_trust ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name district)

/* Regressions to get number of clusters info  (since CGM ado file does not handle this properly) */
*** Relatives Trust ***
global baseline_controls "age age2 male urban_dum i.education i.occupation i.religion i.living_conditions district_ethnic_frac frac_ethnicity_in_district i.isocode"
global colonial_controls "malaria_ecology total_missions_area explorer_contact railway_contact cities_1400_dum i.v30 v33"

xi: areg trust_relatives ln_export_area $baseline_controls $colonial_controls ln_init_pop_density, cluster(murdock_name) 

use "Nunn_Wantchekon_AER_2011.dta", clear
xi: reg trust_relatives ln_export_area $baseline_controls $colonial_controls ln_init_pop_density, cluster(murdock_name)
scalar b1 = _b[ln_export_area]

xi: reg trust_relatives ln_export_area $baseline_controls  ln_init_pop_density, cluster(murdock_name)
scalar b2 = _b[ln_export_area]

scalar bt = b1/(b2-b1)
display  bt

scalar list

scalar tilde_r2 = e(r2)
scalar r_max = 1.3*tilde_r2

egen nisocode = group(isocode)

psacalc beta ln_export_area, rmax(.154) mcontrol(ln_init_pop_density )

psacalc beta ln_export_area, rmax(.16953028)


psacalc beta ln_export_area,  rmax(.16953028) model(xi: reg trust_relatives ln_export_area $baseline_controls $colonial_controls ln_init_pop_density, cluster(murdock_name))

*** Neighbors Trust ***
xi: reg trust_neighbors ln_export_area $baseline_controls $colonial_controls ln_init_pop_density, cluster(murdock_name)

psacalc beta ln_export_area, rmax(0.273)

psacalc beta ln_export_area, rmax(0.203)

xi: reg trust_neighbors ln_export_area $baseline_controls $colonial_controls ln_init_pop_density, cluster(murdock_name)
scalar b1 = _b[ln_export_area]

xi: reg trust_neighbors ln_export_area $baseline_controls  ln_init_pop_density, cluster(murdock_name)
scalar b2 = _b[ln_export_area]

scalar bt = b1/(b2-b1)
display  bt


psacalc beta ln_export_area, rmax(0.210)

xi: reg trust_neighbors ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(district)
*** Trust Local Council ***
xi: reg trust_local_council ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name)
xi: reg trust_local_council ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(district)
*** Intra Group Trust ***
xi: reg intra_group_trust ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name)
xi: reg intra_group_trust ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(district)
*** Inter Group Trust ***
xi: reg inter_group_trust ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name)
xi: reg inter_group_trust ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(district)

*************************************************
*** OLS: Magnitudes - for discussion in paper ***
*************************************************
*** Relatives Trust ***
xi: reg trust_relatives ln_export_area $baseline_controls, beta
*** Intra Group Trust ***
xi: reg intra_group_trust ln_export_area `baseline_controls', beta
*** Neighbors Trust ***
xi: reg trust_neighbors ln_export_area `baseline_controls', beta
*** Inter Group Trust ***
xi: reg inter_group_trust ln_export_area `baseline_controls', beta
*** Trust Local Council ***
xi: reg trust_local_council ln_export_area `baseline_controls', beta

********************************************************
*** Variance Decomposition - for discussion in paper ***
********************************************************
preserve
for @ in any trust_neighbors ln_export_area murdock_name age age2 male urban_dum education occupation religion living_conditions district_ethnic_frac frac_ethnicity_in_district isocode: drop if missing(@)==1
/* None */
xi: reg trust_neighbors i.isocode, cluster(murdock_name)
/* Slave Trade Only */
xi: reg trust_neighbors ln_export_area i.isocode, cluster(murdock_name)
/* Other Characteristics */
xi: reg trust_neighbors age age2 male urban_dum i.education i.occupation i.religion i.living_conditions district_ethnic_frac frac_ethnicity_in_district i.isocode, cluster(murdock_name)
/* Both */
xi: reg trust_neighbors ln_export_area age age2 male urban_dum i.education i.occupation i.religion i.living_conditions district_ethnic_frac frac_ethnicity_in_district i.isocode, cluster(murdock_name)
restore

log close
