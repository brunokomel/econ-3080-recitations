version 11.1
clear all
set more off
capture log close

set mem 300m
set matsize 6000

log using "Falsification_tests_within_Africa_Tables7_8.log", replace

use "Nunn_Wantchekon_AER_2011.dta", clear

local baseline_controls "age age2 male urban_dum i.education i.occupation i.religion i.living_conditions district_ethnic_frac frac_ethnicity_in_district i.isocode"
local colonial_controls "malaria_ecology total_missions_area explorer_contact railway_contact cities_1400_dum i.v30 v33"

*******************************************
** Table 7: Local Council, Columns 1 & 2 **
*******************************************
xi: reg trust_local_council distsea i.isocode if missing(religion)!=1 & missing(urban_dum)!=1 & missing(male)!=1 & missing(age)!=1, cluster(murdock_name)
xi: reg trust_local_council distsea age age2 male urban_dum i.religion i.isocode, cluster(murdock_name)

***********************************************
** Table 8: Inter-group trust, Columns 1 & 2 **
***********************************************
xi: reg inter_group_trust distsea i.isocode if missing(occupation)!=1 & missing(urban_dum)!=1 & missing(male)!=1 & missing(age)!=1, cluster(murdock_name)
xi: reg inter_group_trust distsea age age2 male urban_dum i.occupation i.isocode, cluster(murdock_name)

log close



