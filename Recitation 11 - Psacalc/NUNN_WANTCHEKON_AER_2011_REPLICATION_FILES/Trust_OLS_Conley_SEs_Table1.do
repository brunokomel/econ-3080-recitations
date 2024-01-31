version 11.1
clear all
set more off
capture log close

set mem 300m
set matsize 6000

log using "Trust_OLS_Conley_SEs_Table1.log", replace

use "Nunn_Wantchekon_AER_2011.dta", clear

local baseline_controls "age age2 male urban_dum i.education i.occupation i.religion i.living_conditions district_ethnic_frac frac_ethnicity_in_district i.isocode"
local colonial_controls "malaria_ecology total_missions_area explorer_contact railway_contact cities_1400_dum i.v30 v33"

****************************************
*** Table 1 - Conley Standard Errors ***
****************************************

gen cutoff1=5	/* Closer than cutoff = 1, further = 0 */
gen cutoff2=5
gen constant=1

drop if missing(centroid_lat)==1
drop if missing(centroid_long)==1
drop if missing(trust_neighbors)==1
for @ in any age male urban_dum education occupation religion living_conditions district_ethnic_frac frac_ethnicity_in_district isocode: drop if missing(@)==1

foreach x in exports ln_exports export_area export_pop ln_export_area ln_export_pop{
quietly{
preserve
drop if missing(`x')==1
xi: reg `x' `baseline_controls'
predict `x'_resid if e(sample), resid
xi: reg trust_neighbors `baseline_controls'
predict trust_neighbors_resid if e(sample), resid
}
x_ols centroid_lat centroid_long cutoff1 cutoff2 trust_neighbors_resid constant `x'_resid, coord(2) xreg(2)
restore
}

*** Note: Full method below - running this takes days and gives the same SEs (to the third decimal place) ***

** Number of variables: 1 constant + 1 slave export var + 15 country fes + 6 controls + 9 education fes + 25 occupation fes + 17 religion fes + 4 living condition fes  
*xi i.education, prefix(_E)
*xi i.occupation, prefix(_O)
*xi i.religion, prefix(_R)
*xi i.living_conditions, prefix(_L)
*xi i.isocode, prefix(_I)

*local created_dummies "_Eeducation_1 _Eeducation_2 _Eeducation_3 _Eeducation_4 _Eeducation_5 _Eeducation_6 _Eeducation_7 _Eeducation_8 _Eeducation_9 _Ooccupatio_1 _Ooccupatio_2 _Ooccupatio_3 _Ooccupatio_4 _Ooccupatio_5 _Ooccupatio_6 _Ooccupatio_7 _Ooccupatio_8 _Ooccupatio_9 _Ooccupatio_10 _Ooccupatio_11 _Ooccupatio_12 _Ooccupatio_13 _Ooccupatio_14 _Ooccupatio_15 _Ooccupatio_16 _Ooccupatio_18 _Ooccupatio_19 _Ooccupatio_20 _Ooccupatio_21 _Ooccupatio_22 _Ooccupatio_23 _Ooccupatio_24 _Ooccupatio_25 _Ooccupatio_995 _Rreligion_2 _Rreligion_3 _Rreligion_4 _Rreligion_5 _Rreligion_6 _Rreligion_7 _Rreligion_10 _Rreligion_11 _Rreligion_12 _Rreligion_13 _Rreligion_14 _Rreligion_15 _Rreligion_360 _Rreligion_361 _Rreligion_362 _Rreligion_363 _Rreligion_995 _Lliving_co_2 _Lliving_co_3 _Lliving_co_4 _Lliving_co_5 _Iisocode_2 _Iisocode_3 _Iisocode_4 _Iisocode_5 _Iisocode_6 _Iisocode_7 _Iisocode_8 _Iisocode_9 _Iisocode_10 _Iisocode_11 _Iisocode_12 _Iisocode_13 _Iisocode_14 _Iisocode_15 _Iisocode_16"
*local narrow_baseline_controls "age age2 male urban_dum district_ethnic_frac frac_ethnicity_in_district"

*x_ols centroid_lat centroid_long cutoff1 cutoff2 trust_neighbors constant ln_export_area `created_dummies' `narrow_baseline_controls', coord(2) xreg(78)

log close
