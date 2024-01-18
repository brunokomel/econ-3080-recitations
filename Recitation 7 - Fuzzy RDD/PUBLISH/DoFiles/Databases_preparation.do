clear all
set matsize 11000
set maxvar 20000

** Name: Databases_preparation.do
** Date Created: 02/20/2018 by Vincent Pons (vpons@hbs.edu)
** Last Updated: 05/16/2018

* Data In: [database_elections & political_orientations & campaign_expenditures & INSEE_departement_population & newspaper_circulation_departement & radio_audience_departement & TV_audience_region & dropouts_press_Factiva]
* Data Out: [analysis & dropouts_press]

* Purpose of do-file: Prepare databases used to generate results

* Organization :
/* 
*** PART I *** Complete the elections database with data on candidates, reshape and keep elections relevant for the analysis
*** PART II *** Work on the population and media databases
*** PART III *** Merge elections database with the population and media databases
*** PART IV *** Create additional variables for the analysis
*** PART V *** Work on the database of press articles covering instances of candidates dropping out
*/

* Setting file path

cd "${data}"

**********************************************
*** PART I *** Complete the elections database
**********************************************

clear
use "Original\database_elections", clear

** Ranking of each candidate in each round
forvalues i=1/2 {
gsort id_unique -nb_votes_cand_R`i'
bysort id_unique: gen ranking_cand_R`i'=_n if nb_votes_cand_R`i'!=.
label variable ranking_cand_R`i' "candidate's ranking, round `i'"
}

gsort year id_unique ranking_cand_R1

** We rank candidates who received exactly the same number of votes based on their age 
** We give the best rank to the oldest, following the spirit of the voting rule which, in case of a tie in the second round, declares the older candidate the winner
* 1st round
replace ranking_cand_R1=1 if last_name_cand=="FRANCINA" & id_unique==1074052012
replace ranking_cand_R1=2 if last_name_cand=="ESCOUBES" & id_unique==1074052012

replace ranking_cand_R1=4 if last_name_cand=="REVEL" & id_unique==2012142011
replace ranking_cand_R1=3 if last_name_cand=="CROS-CHAYRIGUES" & id_unique==2012142011

replace ranking_cand_R1=1 if last_name_cand=="BERTHET" & id_unique==2078322011
replace ranking_cand_R1=2 if last_name_cand=="BRILLAULT" & id_unique==2078322011

replace ranking_cand_R1=3 if last_name_cand=="LACALMETTE" & id_unique==1049032002
replace ranking_cand_R1=4 if strpos(last_name_cand , "BOUILLERIE")!=0 & id_unique==1049032002

replace ranking_cand_R1=3 if last_name_cand=="WILMOTTE" & id_unique==1059122012
replace ranking_cand_R1=4 if last_name_cand=="BAUDOUX" & id_unique==1059122012

replace ranking_cand_R1=1 if last_name_cand=="MME TAVERNIER MARIE-ODILE ET M. VERCRUYSSE JEAN-MARIE" & id_unique==2061182015
replace ranking_cand_R1=2 if last_name_cand=="MME JOSSET ELISABETH ET M. MARTING LAURENT" & id_unique==2061182015

replace ranking_cand_R1=3 if last_name_cand=="MME CAVASSE MARTINE ET M. GUICHARD CHRISTOPHE" & id_unique==2026112015
replace ranking_cand_R1=2 if last_name_cand=="MME GUILLEMINOT KARINE ET M. PIENIEK PIERRE" & id_unique==2026112015

replace ranking_cand_R1=3 if strpos(last_name_cand , "BARROUQUERE")!=0 & id_unique==2065012015
replace ranking_cand_R1=2 if last_name_cand=="M. DELASALLE GILLES ET MME PADIOLEAU REINE" & id_unique==2065012015

replace ranking_cand_R1=3 if last_name_cand=="DAHMANE" & id_unique==2052302011
replace ranking_cand_R1=2 if last_name_cand=="MOUGEL" & id_unique==2052302011

replace ranking_cand_R1=3 if last_name_cand=="MANSARD" & id_unique==2089292011
replace ranking_cand_R1=4 if last_name_cand=="BOUCHIER" & id_unique==2089292011

replace ranking_cand_R1=1 if last_name_cand=="LADRANGE" & id_unique==2089402011
replace ranking_cand_R1=2 if last_name_cand=="FERRAND" & id_unique==2089402011

replace ranking_cand_R1=3 if last_name_cand=="GAUBERT" & id_unique==2012412011
replace ranking_cand_R1=4 if last_name_cand=="EDDARRAZ" & id_unique==2012412011


* 2nd round
replace ranking_cand_R2=1 if political_label_cand=="UDI" & id_unique==2061032015
replace ranking_cand_R2=2 if political_label_cand=="SOC" & id_unique==2061032015

** Merge the elections database with the orientations database to give each candidate one of six orientations we defined, based on their political labels
merge m:1 year political_label_cand using "Original\political_orientations"
tab political_label if _merge==1
*36 candidates who have no political label
drop _merge

order political_orientation_cand, after(political_label_cand)

** Merge with the campaign expenditures database 
merge 1:1 id_unique last_name_cand first_name_cand using "Original\campaign_expenditures", force
drop _merge

** Reshape to get one observation per race
gen j=ranking_cand_R1
reshape wide last_name_cand first_name_cand political_label_cand political_orientation_cand nb_votes_cand_R1 nb_votes_cand_R2 ///
prop_registered_votes_cand_R1 prop_registered_votes_cand_R2 prop_voters_votes_cand_R1 prop_voters_votes_cand_R2 ranking_cand_R1 ranking_cand_R2 ///
tot_expenditures_cand tot_contributions_cand party_contributions_cand personal_contributions_cand donations_cand ///
natural_advantages_cand acccount_balance_cand, i(id_unique) j(j)

** Change the way candidates variables are numbered
forvalues i=1/29 {
foreach var in nb_votes prop_registered_votes prop_voters_votes ranking {
ren `var'_cand_R1`i' `var'_cand`i'_R1
ren `var'_cand_R2`i' `var'_cand`i'_R2
}
}

** Drop missing campaign expenditures variables for candidates below the 3rd
forvalues i=4/29 {
foreach var in tot_expenditures_cand tot_contributions_cand party_contributions_cand personal_contributions_cand donations_cand natural_advantages_cand acccount_balance_cand {
drop `var'`i'
}
}

** Drop elections that had only one round, elections with less than 3 candidates in the first round and elections where the 2nd and 3rd are ex-aequo
drop if nb_registered_R2==.
drop if nb_votes_cand3_R1==.
drop if nb_votes_cand3_R1==nb_votes_cand2_R1

dis _N
* 7,257

** Order variables 
foreach i in 2 1 {
order nb_registered_R`i' nb_abstention_R`i' prop_registered_abstention_R`i' nb_turnout_R`i' prop_registered_turnout_R`i' nb_blanknull_R`i' ///
prop_registered_blanknull_R`i' prop_voters_blanknull_R`i' nb_candvotes_R`i' prop_registered_candvotes_R`i' prop_voters_candvotes_R`i' ///
nb_blank_R`i' prop_registered_blank_R`i' prop_voters_blank_R`i' nb_null_R`i' prop_registered_null_R`i' prop_voters_null_R`i', first
}
order year election_type region_code departement_code constituency_code canton_code id_district id_unique, first

gsort year id_unique 

** Label variables
forvalues i=1/29 {
label var last_name_cand`i' "candidate `i''s last name"
label var first_name_cand`i' "candidate `i''s first name"
label variable political_label_cand`i' "candidate `i''s political label"
label variable political_orientation_cand`i' "candidate `i''s political orientation"
forvalues j=1/2 {
label variable nb_votes_cand`i'_R`j' "# votes received by candidate `i', round `j'"
label variable prop_registered_votes_cand`i'_R`j' "% registered citizens who voted for candidate `i', round `j'"
label variable prop_voters_votes_cand`i'_R`j' "% voters who voted for candidate `i', round `j'"
label variable ranking_cand`i'_R`j' "candidate `i''s ranking, round `j'"
}
}
forvalues i=1/3 {
label variable tot_expenditures_cand`i' "candidate `i''s total campaign expenditures, both rounds"
label variable tot_contributions_cand`i' "total contributions received by candidate `i', both rounds"
label variable party_contributions_cand`i' "contributions received from candidate `i''s party, both rounds"
label variable personal_contributions_cand`i' "personal contributions from candidate `i', both rounds"
label variable donations_cand`i' "donations received by candidate `i', both rounds"
label variable natural_advantages_cand`i'  "natural advantages received by candidate `i', both rounds"
label variable acccount_balance_cand`i'   "candidate `i''s campaign account balance, both rounds"
}

save "Intermediate\database_elections_v2", replace

*********************************************************************
*** PART II *** Work on population, newspaper, radio and TV databases
*********************************************************************

***************
* A/ Population
***************

** Create one file per election year based on the Excel from INSEE
clear
set more off
foreach i in 2015 2012 2011 2007 2002 1997 1993 1988 1981 1978 {
clear
import excel "Original\INSEE_departement_population.xls", sheet("`i'")
keep A B H
drop if B==""
* replace the code for the two departements of Corsica to only have numeric values
replace A="201" if A=="2A" 
replace A="202" if A=="2B" 
destring A, replace
destring H, replace
drop B
ren A departement_code
label variable departement_code "departement identifier"

ren H departement_population 
label variable departement_population "departement population"

gen year=`i'
label variable year "year of the election"
save "Intermediate\departement_population_`i'", replace
}

** Merge the files in one unique file 
clear
use "Intermediate\departement_population_2015", clear
foreach i in 2012 2011 2007 2002 1997 1993 1988 1981 1978 {
append using "Intermediate\departement_population_`i'"
}

order year departement_code departement_population

save "Intermediate\departement_population", replace

***************
* B/ Newspapers
***************

clear
use "Original\newspaper_circulation_departement", clear

** We use 2014's data for the year 2015
replace year=2015 if year==2014

** The newspaper database merges the two departements of Corsica into one
** Duplicate the observation and change the departement identifier to merge it with the elections database
expand 2 if departement_code==20
gsort year departement_code
quietly by year departement_code:  gen dup = cond(_N==1,0,_n)
replace departement_code=201 if dup==1
replace departement_code=202 if dup==2
drop dup

save "Intermediate\newspaper_circulation_departement_v2", replace

***************
* C/ Radio
***************

clear
use "Original\radio_audience_departement", clear

gsort departement_code year 

** Assign the values of 2003 to the election years before 2003 
replace year=2002 if year==2003
expand 2 if year==2002
gsort departement_code year 
replace year=1997 if year==year[_n-1]
expand 2 if year==1997
gsort departement_code year 
replace year=1993 if year==year[_n-1]
expand 2 if year==1993
gsort departement_code year 
replace year=1988 if year==year[_n-1]
expand 2 if year==1988
gsort departement_code year 
replace year=1981 if year==year[_n-1]
expand 2 if year==1981
gsort departement_code year 
replace year=1978 if year==year[_n-1]
gsort departement_code year 

save "Intermediate\radio_audience_departement_v2", replace

***************
* D/ TV
***************

clear
use "Original\TV_audience_region", clear

gsort region_code year 

** Assign the values of 2003 to the election years before 2003 
replace year=2007 if year==2010
expand 2 if year==2007
gsort region_code year 
replace year=2002 if year==year[_n-1] 
gsort region_code year 
expand 2 if year==2002
gsort region_code year 
replace year=1997 if year==year[_n-1] 
gsort region_code year 
expand 2 if year==1997
gsort region_code year 
replace year=1993 if year==year[_n-1] 
gsort region_code year 
expand 2 if year==1993
gsort region_code year 
replace year=1988 if year==year[_n-1] 
gsort region_code year 
expand 2 if year==1988
gsort region_code year 
replace year=1981 if year==year[_n-1] 
gsort region_code year 
expand 2 if year==1981
gsort region_code year 
replace year=1978 if year==year[_n-1] 
gsort region_code year 

save "Intermediate\TV_audience_region_v2", replace


**********************************************************************************
*** PART III *** Merge elections database with the population and media databases
**********************************************************************************

clear 

use "Intermediate\database_elections_v2", clear

** Merge with population
merge m:m year departement_code using "Intermediate\departement_population"
tab departement_code if _merge==1
* French territories overseas
drop if _merge==2
drop _merge

** Merge with newspaper circulation
merge m:m year departement_code using "Intermediate\newspaper_circulation_departement_v2"
tab departement_code if _merge==1
* region "Ile de France" and French territories overseas
drop if _merge==2
drop _merge

** Merge with radio audience
merge m:m year departement_code using "Intermediate\radio_audience_departement_v2"
tab departement_code if _merge==1
* French territories overseas and the 16 least densely populated departement
drop if _merge==2
drop _merge

** Merge with TV audience
merge m:m year region_code using "Intermediate\TV_audience_region_v2"
tab region_code if _merge==1
* French territories overseas, regions Corsica and "Centre"
drop _merge

**********************************************************
*** PART IV *** Variables creation
**********************************************************

***********************
* A/ RDD variables
***********************

** Qualification threshold
gen threshold=0.125 
replace threshold=0.1 if year==2011 & departement_code==976
label var threshold "qualification threshold for 2nd round, % registered"

** Treatment
gen treatment=(nb_votes_cand3_R2!=.)
label variable treatment "treatment: 3rd candidate present in 2nd round"

** Running
gen running=prop_registered_votes_cand3_R1-threshold
label variable running "running variable: qualifying margin of the 3rd candidate in 1st round"

** Assignment
gen assignment=(running>=0)
label variable assignment "assignment to treatment: 3rd candidate qualified"

*******************************************
* B/ Number of candidates in rounds 1 and 2 
*******************************************

** Number of candidates
forvalues i=1/2 {
gen nb_candidates_R`i'=0
forvalues j=1/29 {
capture replace nb_candidates_R`i'=nb_candidates_R`i'+1 if nb_votes_cand`j'_R`i'!=.
}
label variable nb_candidates_R`i' "# candidates, round `i'" 
}

** Dummy indicating whether the candidate drops out of the race, for each of the top-three candidate
gen dropout_cand1=(nb_votes_cand1_R2==.)
label variable dropout_cand1 "dummy: the 1st candidate drops out between the 2 rounds"

gen dropout_cand2=(nb_votes_cand2_R2==.)
label variable dropout_cand2 "dummy: the 2nd candidate drops out between the 2 rounds"

gen dropout_cand3=(assignment==1 & treatment==0)
label variable dropout_cand3 "dummy: the 3rd candidate is qualified and drops out between the 2 rounds"

*******************************
* C/ Political orientation  
*******************************

** Dummy for the orientation of the top three candidates
foreach i in left right farright farleft center nonclassified {
forvalues j=1/3 {
gen `i'_cand`j'=(political_orientation_cand`j'=="`i'")
label variable `i'_cand`j' "dummy: candidate `j' has orientation `i'"
}
}

** Ideological ranking on the left-right axis of the top three candidates
label define ideo 1 "farleft" 2 "left" 3 "center" 4 "right" 5 "farright"
forvalues i=1/3 {
gen ideology_cand`i'=1 if political_orientation_cand`i'=="farleft"
replace ideology_cand`i'=2 if political_orientation_cand`i'=="left"
replace ideology_cand`i'=3 if political_orientation_cand`i'=="center"
replace ideology_cand`i'=4 if political_orientation_cand`i'=="right"
replace ideology_cand`i'=5 if political_orientation_cand`i'=="farright"
label variable ideology_cand`i' "ideological position on the left-right axis, candidate `i'"
label values ideology_cand`i' ideo
}

** Dummy indicating whether there is at least one candidate of a given orientation in the first round
foreach i in left right farright farleft center nonclassified {
gen presence_`i'_R1=0
forvalues j=1/29 {
replace presence_`i'_R1=1 if (political_orientation_cand`j'=="`i'")
}
label variable presence_`i'_R1 "dummy: there is at least one `i' candidate, round 1"
}

** Strength of each orientation 
foreach i in left right farright farleft center nonclassified {
gen `i'_strength=0
forvalues j=1/29 {
replace `i'_strength=`i'_strength+prop_voters_votes_cand`j'_R1 if political_orientation_cand`j'=="`i'" 
}
replace `i'_strength=. if presence_`i'==0 
label variable `i'_strength "strength of `i' orientation"
}

** Strength of each of the top three candidates 
forvalues j=1/3 {
gen strength_cand`j'=.
foreach i in left right farright farleft center {
replace strength_cand`j'=`i'_strength if political_orientation_cand`j'=="`i'"
}
label variable strength_cand`j' "strength of candidate `j'"
}

** Number of candidates from each orientation in first round 
foreach i in left right farright farleft center nonclassified {
gen nb_cand_`i'_R1=0
forvalues j=1/29 {
replace nb_cand_`i'_R1=nb_cand_`i'_R1+1 if (political_orientation_cand`j'=="`i'")
}
label variable nb_cand_`i'_R1 "# `i' candidates, round 1"
}

** Dummy indicating whether the third candidate has the same orientation as one top2
gen third_same_orientation_top2=(((political_orientation_cand3==political_orientation_cand1) | (political_orientation_cand3==political_orientation_cand2)) & political_orientation_cand3!="nonclassified" & political_orientation_cand3!="")
label variable third_same_orientation_top2 "dummy: the 3rd candidate has the same orientation as one top-two"

** Identification of the closest (resp. furthest) candidate among the top two candidates
gen closest_to3rd=1 if abs(ideology_cand1-ideology_cand3)<=abs(ideology_cand2-ideology_cand3)
replace closest_to3rd=2 if abs(ideology_cand1-ideology_cand3)>=abs(ideology_cand2-ideology_cand3)
label variable closest_to3rd "candidate among the top 2 ideologically closest to the 3rd"

gen furthest_to3rd=2 if closest_to3rd==1
replace furthest_to3rd=1 if closest_to3rd==2
label variable furthest_to3rd "candidate among the top 2 ideologically furthest to the 3rd"

*******************************
* D/ Vote shares 
*******************************

** Vote share of the top two candidates together
* round 1
* as a fraction of registered citizens
gen prop_registered_votes_top2_R1=prop_registered_votes_cand1_R1+prop_registered_votes_cand2_R1
label variable prop_registered_votes_top2_R1 "% registered citizens who voted for one of the top 2 candidates, round 1"
* as a fraction of candidate votes
gen prop_voters_votes_top2_R1=prop_voters_votes_cand2_R1+prop_voters_votes_cand1_R1
label variable prop_registered_votes_top2_R1 "% voters who voted for one of the top 2 candidates, round 1"
* round 2, as a fraction of registered citizens
gen prop_registered_votes_top2_R2=prop_registered_votes_cand1_R2+prop_registered_votes_cand2_R2
replace prop_registered_votes_top2_R2=prop_registered_votes_cand1_R2 if dropout_cand2==1
replace prop_registered_votes_top2_R2=prop_registered_votes_cand2_R2 if dropout_cand1==1
label variable prop_registered_votes_top2_R2 "% registered citizens who voted for one of the top 2 candidates, round 2"

** Vote share (as a fraction of registered citizens) of the closest and furthest candidates
* rounds 1 and 2
foreach i in closest furthest {
forvalues j=1/2 {
gen prop_reg_votes_`i'_R`j'=prop_registered_votes_cand1_R`j' if `i'_to3rd==1
replace prop_reg_votes_`i'_R`j'=prop_registered_votes_cand2_R`j' if `i'_to3rd==2
label variable prop_reg_votes_`i'_R`j' "% registered citizens who voted for the top-two `i' to the 3rd, round `j'"
}
}

** Vote share (as a fraction of candidates votes) of the closest and furthest candidates
* rounds 1 and 2
foreach i in closest furthest {
forvalues j=1/2 {
gen prop_voters_votes_`i'_R`j'=prop_voters_votes_cand1_R`j' if `i'_to3rd==1
replace prop_voters_votes_`i'_R`j'=prop_voters_votes_cand2_R`j' if `i'_to3rd==2
label variable prop_voters_votes_`i'_R`j' "% voters who voted for the top-two `i' to the 3rd, round `j'"
}
}

** Vote share (as a fraction of registered citizens) of candidates A, B, C in round 2
gen prop_registered_votes_candA_R2=.
gen prop_registered_votes_candC_R2=.
gen prop_registered_votes_candB_R2=.

forvalues i=1/3 {
replace prop_registered_votes_candA_R2=prop_registered_votes_cand`i'_R2 if ideology_cand`i'==min(ideology_cand1, ideology_cand2, ideology_cand3)
replace prop_registered_votes_candC_R2=prop_registered_votes_cand`i'_R2 if ideology_cand`i'==max(ideology_cand1, ideology_cand2, ideology_cand3)
replace prop_registered_votes_candB_R2=prop_registered_votes_cand`i'_R2 if ideology_cand`i'!=min(ideology_cand1, ideology_cand2, ideology_cand3) & ideology_cand`i'!=max(ideology_cand1, ideology_cand2, ideology_cand3)
}
label var prop_registered_votes_candA_R2 "% registered voters who voted for the top-3 the most to the left, round 2"
label var prop_registered_votes_candB_R2 "% registered voters who voted for the top-3 in the middle, round 2"
label var prop_registered_votes_candC_R2 "% registered voters who voted for the top-3 the most to the right, round 2"

** Difference between the vote shares of the top two
gen prop_reg_votes_diff_candAB=prop_registered_votes_candA_R2-prop_registered_votes_candB_R2
replace prop_reg_votes_diff_candAB=prop_registered_votes_candA_R2 if prop_registered_votes_candB_R2==.
replace prop_reg_votes_diff_candAB=-prop_registered_votes_candB_R2 if prop_registered_votes_candA_R2==.
label variable prop_reg_votes_diff_candAB "difference in % registered voters between candidates A and B, round 2"

gen prop_reg_votes_diff_candBC=prop_registered_votes_candB_R2-prop_registered_votes_candC_R2
replace prop_reg_votes_diff_candBC=prop_registered_votes_candB_R2 if prop_registered_votes_candC_R2==.
replace prop_reg_votes_diff_candBC=-prop_registered_votes_candC_R2 if prop_registered_votes_candB_R2==.
label variable prop_reg_votes_diff_candBC "difference in % registered voters between candidates B and C, round 2"

gen prop_reg_votes_diff_candAC=prop_registered_votes_candA_R2-prop_registered_votes_candC_R2
replace prop_reg_votes_diff_candAC=prop_registered_votes_candA_R2 if prop_registered_votes_candC_R2==.
replace prop_reg_votes_diff_candAC=-prop_registered_votes_candC_R2 if prop_registered_votes_candA_R2==.
label variable prop_reg_votes_diff_candAC "difference in % registered voters between candidates A and C, round 2"

** Vote shares (as fractions of candidate votes) of the winner and 2nd candidate in the 2nd round
gen prop_voters_votes_winner_R2=.
gen prop_voters_votes_second_R2=.
forvalues i=1/29 {
replace prop_voters_votes_winner_R2=prop_voters_votes_cand`i'_R2 if ranking_cand`i'_R2==1
replace prop_voters_votes_second_R2=prop_voters_votes_cand`i'_R2 if ranking_cand`i'_R2==2
}
label variable prop_voters_votes_winner_R2 "% voters who voted for the winner, round 2"
label variable prop_voters_votes_second_R2 "% voters who voted for the candidate who finished second, round 2"

** Dummy indicating whether the closest candidate wins
gen winner_closest=((closest_to3rd==1 & ranking_cand1_R2==1) | (closest_to3rd==2 & ranking_cand2_R2==1)) 
label variable winner_closest "dummy: the top-two closest to the 3rd wins the election"

*********************
* E/ Distance
*********************

** Closeness 1st round (distance between the top 2)
* distance between the vote shares of the top 2 (as fractions of candidate votes)
gen distance_voteshare_cand12_R1=prop_voters_votes_cand1_R1-prop_voters_votes_cand2_R1
label variable distance_voteshare_cand12_R1 "difference in % cand votes between the top 2, round 1"
* distance between the strengths (as fractions of candidate votes) of the top 2 
gen distance_strength_cand12_R1=abs(strength_cand1-strength_cand2)
label variable distance_strength_cand12_R1 "difference in strengths between the top 2, round 1"

** Closeness 2nd round (distance between the winner and the second)
* distance between the vote shares (as fractions of candidate votes) of the winner and the second candidate 
gen distance_voteshare_winner2nd_R2=prop_voters_votes_winner_R2-prop_voters_votes_second_R2
label variable distance_voteshare_winner2nd_R2 "difference in % cand votes between the winner and the 2nd, round 2"

** Distance between the 3rd and the closest candidate, 1st round
* in terms of strengths
gen distance_cand3_closest_R1=strength_cand1-strength_cand3 if closest_to3rd==1
replace distance_cand3_closest_R1=strength_cand2-strength_cand3 if closest_to3rd==2
* we replace by distance in vote shares for the cases where the 3rd has the same orientation as one top-two
replace distance_cand3_closest_R1=prop_voters_votes_cand1_R1-prop_voters_votes_cand3_R1 if third_same_orientation_top2==1 & political_orientation_cand3==political_orientation_cand1
replace distance_cand3_closest_R1=prop_voters_votes_cand2_R1-prop_voters_votes_cand3_R1 if third_same_orientation_top2==1 & political_orientation_cand3==political_orientation_cand2
label variable distance_cand3_closest_R1 "distance between the 3rd and the closest cand among the top2, round 1"

** Distance between the third candidate and the weakest of the top two candidates in strengths
gen dist_strength_cand3_weakest_R1=strength_cand1-strength_cand3 if strength_cand1<=strength_cand2
replace dist_strength_cand3_weakest_R1=strength_cand2-strength_cand3 if strength_cand1>strength_cand2
label variable dist_strength_cand3_weakest_R1 "distance between the 3rd and the weakest cand among the top2, round 1"

**************************
* F/ Predicted assignment 
**************************

global X1 "nb_registered_R1 prop_registered_turnout_R1 prop_registered_candvotes_R1"
global X2 "distance_voteshare_cand12_R1 prop_voters_votes_cand1_R1 prop_voters_votes_cand2_R1 prop_voters_votes_cand3_R1"
global X3 "left_cand1 right_cand1 farright_cand1 center_cand1 left_cand2 right_cand2 farright_cand2 farleft_cand2 center_cand2 left_cand3 right_cand3 farright_cand3 farleft_cand3 center_cand3" 
global X4 "presence_left_R1 presence_right_R1 presence_farleft_R1 presence_farright_R1 presence_center_R1 third_same_orientation_top2"
global X5 "nb_candidates_R1 nb_cand_left_R1 nb_cand_farleft_R1 nb_cand_right_R1 nb_cand_farright_R1 nb_cand_center_R1 nb_cand_nonclassified_R1"

tab political_label_cand1, gen(dummy_political_label_cand1)
tab political_label_cand2, gen(dummy_political_label_cand2)
tab political_label_cand3, gen(dummy_political_label_cand3)
global X6 "dummy_political_label_cand1* dummy_political_label_cand2* dummy_political_label_cand3*"

ivreg2 assignment $X1 $X2 $X3 $X4 $X5 $X6
quietly predict predicted_assignment
label variable predicted_assignment "predicted assignment based on baseline variables"

********************************
* G/ Samples and settings 
********************************

** Sample in which the three candidates have different orientations
gen sample0=(third_same_orientation_top2==0 & political_orientation_cand1!=political_orientation_cand2 & ideology_cand1!=. & ideology_cand2!=. & ideology_cand3!=.)
label variable sample0 "dummy: elections where the top 3 cand have distinct orientations"

** Settings depending on the ideological position of the 3rd
gen setting=1 if sample0==1 & (ideology_cand3>ideology_cand2 & ideology_cand3>ideology_cand1) 
replace setting=2 if sample0==1 & (ideology_cand3<ideology_cand2 & ideology_cand3<ideology_cand1)
replace setting=3 if sample0==1 & ((ideology_cand3<ideology_cand2 & ideology_cand3>ideology_cand1) | (ideology_cand3>ideology_cand2 & ideology_cand3<ideology_cand1))
label variable setting "settings depending on the ideological position of the 3rd"

label define set 1 "3rd to the right" 2 "3rd to the left" 3 "3rd in the middle"
label values setting set

** Sample in which the closest candidate is identified
gen sample1=(sample0==1 & (setting==1 | setting==2))
label variable sample1 "dummy: elections where the top-two closest to the 3rd is identified"

** Samples depending on the strength of the 3rd
gen sample2=(sample1==1 & strength_cand3<min(strength_cand1, strength_cand2))
label variable sample2 "dummy: elections in sample 1 where the strength of the 3rd < top2"
gen sample3=(sample2==1 & strength_cand3<min(strength_cand1, strength_cand2)-0.05)
label variable sample3 "dummy: elections in sample 1 where the strength of the 3rd < top2 - 5pp"
gen sample4=(sample2==1 & strength_cand3<min(strength_cand1, strength_cand2)-0.1)
label variable sample4 "dummy: elections in sample 1 where the strength of the 3rd < top2 - 10pp"

** Sample in which the third has the same orientation as one top2 and the closest top2 is identified
gen sample_same_orientation_closest=(third_same_orientation_top2==1 & political_orientation_cand1!=political_orientation_cand2 & ideology_cand1!=. & ideology_cand2!=.)
label variable sample_same_orientation_closest "dummy: 3rd has the same orientation as one top2 + closest identified"

********************************************
* H/ Campaign expenditures
********************************************

** Other contributions
forvalues i=1/3 {
gen other_contributions_cand`i'=tot_contributions_cand`i'
foreach var in personal_contributions_cand donations_cand natural_advantages_cand party_contributions_cand {
replace other_contributions_cand`i'=other_contributions_cand`i'-`var'`i' if `var'`i'!=.
}
label variable other_contributions_cand`i' "other contributions received by candidate `i', both rounds"
}

** Amounts divided by the number of registered citizens
forvalues i=1/3 {
foreach var in tot_expenditures tot_contributions party_contributions personal_contributions donations ///
natural_advantages other_contributions acccount_balance {
gen `var'_cand`i'_reg=`var'_cand`i'/nb_registered_R1
}
label variable tot_expenditures_cand`i'_reg "candidate `i''s total campaign expenditures / # of reg citizens"
label variable tot_contributions_cand`i'_reg "total contributions received by candidate `i' / # of reg citizens"
label variable party_contributions_cand`i'_reg "contributions received from candidate `i''s party / # of reg citizens"
label variable personal_contributions_cand`i'_reg "personal contributions from candidate `i' / # of reg citizens"
label variable donations_cand`i'_reg "donations received by candidate `i' / # of reg citizens"
label variable natural_advantages_cand`i'_reg  "natural advantages received by candidate `i' / # of reg citizens"
label variable acccount_balance_cand`i'_reg  "candidate `i''s campaign account balance / # of reg citizens"
label variable other_contributions_cand`i'_reg  "other contributions received by candidate `i' / # of reg citizens"
}

** Campaign expenditures of the top two
foreach var in tot_expenditures tot_contributions party_contributions personal_contributions donations ///
natural_advantages other_contributions acccount_balance {
gen `var'_top2_reg=`var'_cand1_reg+`var'_cand2_reg
}
label variable tot_expenditures_top2_reg "top 2 cand's total campaign expenditures / # of reg citizens"
label variable tot_contributions_top2_reg "total contributions received by the top 2 cand/ # of reg citizens"
label variable party_contributions_top2_reg "contributions received from the top 2 cand's party / # of reg citizens"
label variable personal_contributions_top2_reg "personal contributions from the top 2 cand / # of reg citizens"
label variable donations_top2_reg "donations received by the top 2 cand / # of reg citizens"
label variable natural_advantages_top2_reg  "natural advantages received by the top 2 cand / # of reg citizens"
label variable acccount_balance_top2_reg  "top 2 cand's campaign account balance / # of reg citizens"
label variable other_contributions_top2_reg  "other contributions received by the top 2 cand / # of reg citizens"

********************************************
* G/ Media coverage 
********************************************

** Newspaper
* newspaper consumption = newspaper circulation / population
gen dpt_newspaper_circulation_pop=dpt_newspaper_circulation/departement_population
* for Corsica we need to divide by the sum of the population of the two departements
gsort year departement_code
gen temp=departement_population+departement_population[_n+1] if departement_code==201 & departement_code[_n+1]==202
bysort year: egen pop_dpt_corse_total=max(temp)
replace dpt_newspaper_circulation_pop=dpt_newspaper_circulation/pop_dpt_corse_total if departement_code==201 | departement_code==202
drop temp pop_dpt_corse_total
label variable dpt_newspaper_circulation_pop "# newspaper copies in circulation in the departement / population"
* median and terciles
egen median_newspaper=xtile(dpt_newspaper_circulation_pop), by(year) n(2)
label variable median_newspaper "newspaper consumption median"
label define med 1 "below" 2 "above"
label values median_newspaper med
egen terciles_newspaper=xtile(dpt_newspaper_circulation_pop), by(year) n(3)
label variable terciles_newspaper "newspaper consumption terciles"

** Radio
* median and terciles
egen median_radio=xtile(dpt_radio_audience), by(year) n(2)
label variable median_radio "radio news audience median"
label values median_radio med
egen terciles_radio=xtile(dpt_radio_audience), by(year) n(3)
label variable terciles_radio "radio news audience terciles"

** TV
* median and terciles
egen median_TV=xtile(region_TV_audience), by(year) n(2)
label variable median_TV "TV news audience median"
label values median_TV med
egen terciles_TV=xtile(region_TV_audience), by(year) n(3)
label variable terciles_TV "TV news audience terciles"

save "Analysis\analysis", replace

***************************************************************************************
*** PART V *** Database of press articles covering instances of candidates dropping out
***************************************************************************************

clear 

use "Original\dropouts_press_Factiva", clear

** Classify as "others" categories which represent less than 5% of the cases 
** And drop these categories
* except for voters' reaction
ren reaction_voters voters_reaction

gen other_context=0
label var other_context "dummy: the article provides another context"
gen other_reason=0
label var other_reason "dummy: the article provides another reason"
gen other_reaction=0
label var other_reaction "dummy: the article provides another reaction"

tab third_same_orientation
foreach j in context reason reaction {
foreach var of varlist `j'* {
count if `var'==1 & third_same_orientation_top2==1
local nbs_`var'=r(N)/233
count if `var'==1 & third_same_orientation_top2==0
local nbd_`var'=r(N)/317
replace other_`j'=1 if `var'==1 & `nbs_`var''<0.05 & `nbd_`var''<0.05
	if `nbs_`var''<0.05 & `nbd_`var''<0.05 {
	drop `var'
	}
}
}
ren voters_reaction reaction_voters

** Dummy indicating whether the article provides a context / reason / reaction
gen existence_context=(context_agreement==1 | context_individual_decision==1 | context_party_decision==1) 
label var existence_context "dummy: the article provides a context"

gen existence_reason=(reason_prevent_victory==1 | reason_ideo_proximity==1 | other_reason==1)
label var existence_reason "dummy: the article provides a reason"

gen existence_reaction=(reaction_voters==1 | reaction_furthest_party==1 | reaction_exclusion==1 | other_reaction==1)
label var existence_reaction "dummy: the article provides a reaction"

save "Analysis\dropouts_press", replace
