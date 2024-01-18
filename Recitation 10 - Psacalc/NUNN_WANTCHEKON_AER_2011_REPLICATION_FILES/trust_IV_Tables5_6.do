version 11.0

set more off
capture clear
clear mata
capture log close
clear matrix
set mem 300m
set matsize 6000

log using "trust_IV_Tables5_6.log", replace

use "Nunn_Wantchekon_AER_2011.dta", clear

local baseline_controls "age age2 male urban_dum i.education i.occupation i.religion i.living_conditions district_ethnic_frac frac_ethnicity_in_district i.isocode"
local colonial_controls "malaria_ecology total_missions_area explorer_contact railway_contact cities_1400_dum i.v30 v33"

/*
***********************************************************************
*** Code for Clustering by Hand - there is no canned package for IV ***
***********************************************************************
quietly xi: ivreg trust_relatives (ln_export_area=distsea) `baseline_controls' `colonial_controls', cluster(murdock_name)
matrix vc1 = e(V)
quietly xi: ivreg trust_relatives (ln_export_area=distsea) `baseline_controls' `colonial_controls', cluster(district)
matrix vc2 = e(V)

quietly gen bc3=murdock_name+"_"+district
quietly xi: ivreg trust_relatives (ln_export_area=distsea) `baseline_controls' `colonial_controls', cluster(bc3)
quietly matrix vc=vc1+vc2-e(V)
quietly gen se=sqrt(vc[1,1])
tab se
quietly drop se
***********************************
*/

*********************************************************************
*** Table 5: Controlling for pre-colonial population density only ***
*********************************************************************
foreach x of varlist trust_relatives trust_neighbors trust_local_council intra_group_trust inter_group_trust{
sum `x'	/* Just so we know which variable in loop */
xi: ivreg `x' (ln_export_area=distsea) `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name) 
/* First stage F-stat */
xi: reg ln_export_area distsea `baseline_controls' `colonial_controls' ln_init_pop_density if missing(`x')~=1, cluster(murdock_name)
test distsea==0

*** Doing the 2-way clustering by hand ***
xi: ivreg `x' (ln_export_area=distsea) `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name)
matrix vc1 = e(V)
xi: ivreg `x' (ln_export_area=distsea) `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(district)
matrix vc2 = e(V)

quietly gen bc3=murdock_name+"_"+district
quietly xi: ivreg `x' (ln_export_area=distsea) `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(bc3)
quietly matrix vc=vc1+vc2-e(V)
quietly gen se=sqrt(vc[1,1])
tab se
quietly drop se bc3
}

*****************************************************************************************************************
*** Table 6: Controlling for reliance on fishing & distance to Saharan (with pre-colonial population density) ***
*****************************************************************************************************************
foreach x of varlist trust_relatives trust_neighbors trust_local_council intra_group_trust inter_group_trust{
sum `x'	/* Just so we know which variable in loop */
xi: ivreg `x' (ln_export_area=distsea) `baseline_controls' `colonial_controls' ln_init_pop_density fishing dist_Saharan_node dist_Saharan_line, cluster(murdock_name) 
/* First stage F-stat */
xi: reg ln_export_area distsea `baseline_controls' `colonial_controls' ln_init_pop_density fishing dist_Saharan_node dist_Saharan_line if missing(`x')~=1, cluster(murdock_name)
test distsea==0

*** Doing the 2-way clustering by hand ***
xi: ivreg `x' (ln_export_area=distsea) `baseline_controls' `colonial_controls' ln_init_pop_density fishing dist_Saharan_node dist_Saharan_line, cluster(murdock_name)
matrix vc1 = e(V)
xi: ivreg `x' (ln_export_area=distsea) `baseline_controls' `colonial_controls' ln_init_pop_density fishing dist_Saharan_node dist_Saharan_line, cluster(district)
matrix vc2 = e(V)

quietly gen bc3=murdock_name+"_"+district
quietly xi: ivreg `x' (ln_export_area=distsea) `baseline_controls' `colonial_controls' ln_init_pop_density fishing dist_Saharan_node dist_Saharan_line, cluster(bc3)
quietly matrix vc=vc1+vc2-e(V)
quietly gen se=sqrt(vc[1,1])
tab se
quietly drop se bc3
}

log close





