version 11.1
clear all
set more off
capture log close

set mem 300m
set matsize 6000

log using "Channels_Tables9_10.log", replace

use "Nunn_Wantchekon_AER_2011.dta", clear

local baseline_controls "age age2 male urban_dum i.education i.occupation i.religion i.living_conditions district_ethnic_frac frac_ethnicity_in_district i.isocode"
local colonial_controls "malaria_ecology total_missions_area explorer_contact railway_contact cities_1400_dum i.v30 v33"

***************
*** Table 9 ***
***************

*************************************************
*** Test #1: Local Council Trust (Cols 1 & 2) ***
*************************************************

/* Controlling for Performance & Corruption (FEs) */
xi: cgmreg trust_local_council ln_export_area i.local_council_performance i.corrupt_local_council i.council_listen `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name district)
** Point estimate without additional control(s) **
xi: cgmreg trust_local_council ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density if missing(local_council_performance)~=1 & missing(corrupt_local_council)~=1 & missing(council_listen)~=1, cluster(murdock_name district)

/* Controlling for All - Add public goods */
xi: cgmreg trust_local_council ln_export_area school_present electricity_present piped_water_present sewage_present health_clinic_present i.local_council_performance i.corrupt_local_council i.council_listen `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name district)
** Point estimate without additional control(s) **
xi: cgmreg trust_local_council ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density if missing(local_council_performance)~=1 & missing(corrupt_local_council)~=1 & missing(council_listen)~=1 & missing(school_present)!=1 & missing(electricity_present)!=1 & missing(piped_water_present)!=1 & missing(sewage_present)!=1 & missing(health_clinic_present)!=1, cluster(murdock_name district)

** Need to get number of clusters (CGM does not report this properly) ***
/* Controlling for Performance & Corruption (FEs) */
xi: reg trust_local_council ln_export_area i.local_council_performance i.corrupt_local_council i.council_listen `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name)
xi: reg trust_local_council ln_export_area i.local_council_performance i.corrupt_local_council i.council_listen `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(district)
/* Controlling for All - Add public goods */
xi: reg trust_local_council ln_export_area school_present electricity_present piped_water_present sewage_present health_clinic_present i.local_council_performance i.corrupt_local_council i.council_listen `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name)
xi: reg trust_local_council ln_export_area school_present electricity_present piped_water_present sewage_present health_clinic_present i.local_council_performance i.corrupt_local_council i.council_listen `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(district)

*********************************************
*** Test #2: Inter-Group Trust (Cols 3-5) ***
*********************************************

/*** Controlling for slave export exposure of those in the town ***/
xi: cgmreg inter_group_trust ln_export_area townvill_nonethnic_mean_exports `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name district)
predict hat if e(sample), xb
** Point estimate without additional control(s) **
xi: cgmreg inter_group_trust ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density if missing(hat)!=1, cluster(murdock_name district)
drop hat

/*** Controlling for slave export exposure of those in the district ***/
xi: cgmreg inter_group_trust ln_export_area district_nonethnic_mean_exports `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name district)
predict hat if e(sample), xb
** Point estimate without additional control(s) **
xi: cgmreg inter_group_trust ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density if missing(hat)!=1, cluster(murdock_name district)
drop hat

/*** Controlling for slave export exposure of those in the region ***/
xi: cgmreg inter_group_trust ln_export_area region_nonethnic_mean_exports `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name district)
predict hat if e(sample), xb
** Point estimate without additional control(s) **
xi: cgmreg inter_group_trust ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density if missing(hat)!=1, cluster(murdock_name district)
drop hat

** Need to get number of clusters (CGM does not report this properly) ***
*** Village ***
xi: reg inter_group_trust ln_export_area townvill_nonethnic_mean_exports `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name)
xi: reg inter_group_trust ln_export_area townvill_nonethnic_mean_exports `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(district)
*** District ***
xi: reg inter_group_trust ln_export_area district_nonethnic_mean_exports `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name)
xi: reg inter_group_trust ln_export_area district_nonethnic_mean_exports `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(district)

*** Region ***
xi: reg inter_group_trust ln_export_area region_nonethnic_mean_exports `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name)
xi: reg inter_group_trust ln_export_area region_nonethnic_mean_exports `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(district)


********************************************************
*** Table 10: Test #3: Internal vs. External Factors ***
********************************************************

*** Relatives Trust ***
xi: cgmreg trust_relatives ln_export_area loc_ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(loc_murdock_name murdock_name)
predict hat if e(sample), xb
** Point estimate without additional control(s) **
xi: cgmreg trust_relatives ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density if missing(hat)!=1, cluster(loc_murdock_name murdock_name)
drop hat

*** Neighbors Trust ***
xi: cgmreg trust_neighbors ln_export_area loc_ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(loc_murdock_name murdock_name)
predict hat if e(sample), xb
** Point estimate without additional control(s) **
xi: cgmreg trust_neighbors ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density if missing(hat)!=1, cluster(loc_murdock_name murdock_name)
drop hat

*** Trust Local Council ***
xi: cgmreg trust_local_council ln_export_area loc_ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(loc_murdock_name murdock_name)
predict hat if e(sample), xb
** Point estimate without additional control(s) **
xi: cgmreg trust_local_council ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density if missing(hat)!=1, cluster(loc_murdock_name murdock_name)
drop hat

*** Intra Group Trust ***
xi: cgmreg intra_group_trust ln_export_area loc_ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(loc_murdock_name murdock_name)
predict hat if e(sample), xb
** Point estimate without additional control(s) **
xi: cgmreg intra_group_trust ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density if missing(hat)!=1, cluster(loc_murdock_name murdock_name)
drop hat

*** Inter Group Trust ***
xi: cgmreg inter_group_trust ln_export_area loc_ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(loc_murdock_name murdock_name)
predict hat if e(sample), xb
** Point estimate without additional control(s) **
xi: cgmreg inter_group_trust ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density if missing(hat)!=1, cluster(loc_murdock_name murdock_name)
drop hat

** Need to get number of clusters (CGM does not report this properly) ***
*** Relatives Trust ***
xi: reg trust_relatives ln_export_area loc_ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name)
xi: reg trust_relatives ln_export_area loc_ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(loc_murdock_name)
*** Neighbors Trust ***
xi: reg trust_neighbors ln_export_area loc_ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name)
xi: reg trust_neighbors ln_export_area loc_ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(loc_murdock_name)
*** Trust Local Council ***
xi: reg trust_local_council ln_export_area loc_ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name)
xi: reg trust_local_council ln_export_area loc_ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(loc_murdock_name)
*** Intra Group Trust ***
xi: reg intra_group_trust ln_export_area loc_ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name)
xi: reg intra_group_trust ln_export_area loc_ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(loc_murdock_name)
*** Inter Group Trust ***
xi: reg inter_group_trust ln_export_area loc_ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(murdock_name)
xi: reg inter_group_trust ln_export_area loc_ln_export_area `baseline_controls' `colonial_controls' ln_init_pop_density, cluster(loc_murdock_name)

log close

