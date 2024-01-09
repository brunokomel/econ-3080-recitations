version 11.1
clear all
set more off
capture log close

set mem 300m
set matsize 6000

log using "Altonji_Ratios_Table4.log", replace

use "Nunn_Wantchekon_AER_2011.dta", clear

local baseline_controls "age age2 male urban_dum i.education i.occupation i.religion i.living_conditions district_ethnic_frac frac_ethnicity_in_district i.isocode"
local colonial_controls "malaria_ecology total_missions_area explorer_contact railway_contact cities_1400_dum i.v30 v33"

********************************
*** Table 4 - Altonji Ratios ***
********************************

preserve
foreach x in trust_relative trust_neighbors trust_local_council intra_group_trust inter_group_trust{

********************
*** Rows #1 & #3 ***
********************
*******
sum `x'
*******
* Full #1
xi: reg `x' ln_export_area `baseline_controls', cluster(murdock_name)
predict hat if e(sample), xb
gen beta3=_b[ln_export_area]
* Unrestricted #1
xi: reg `x' ln_export_area i.isocode if missing(hat)!=1, cluster(murdock_name)
gen beta1=_b[ln_export_area] if missing(hat)!=1
* Unrestricted #2
xi: reg `x' ln_export_area i.isocode age age2 male if missing(hat)!=1, cluster(murdock_name)
gen beta2=_b[ln_export_area] if missing(hat)!=1
* Row 1
gen diff1_3=beta3/(beta1-beta3)
* Row 3
gen diff2_3=beta3/(beta2-beta3)
drop beta*
sum diff*
drop hat
drop diff*

********************
*** Rows #2 & #4 ***
********************
* Full #2
xi: reg `x' ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name)
predict hat if e(sample), xb
gen beta5=_b[ln_export_area]
* Unrestricted #1
xi: reg `x' ln_export_area i.isocode if missing(hat)!=1, cluster(murdock_name)
gen beta1=_b[ln_export_area] if missing(hat)!=1
* Unrestricted #2
xi: reg `x' ln_export_area i.isocode age age2 male if missing(hat)!=1, cluster(murdock_name)
gen beta2=_b[ln_export_area] if missing(hat)!=1
* Row 2
gen diff1_5=beta5/(beta1-beta5)
* Row 4
gen diff2_5=beta5/(beta2-beta5)
drop beta*
sum diff*
drop hat
drop diff*
}

log close


