** Name: MASTER.do
** Date Created: 02/20/2018 by Vincent Pons (vpons@hbs.edu)
** Last Updated: 05/16/2018
clear all
set matsize 11000
set maxvar 20000
set more off

** Commands you may need to install :
/*

foreach z in ivreg2 ranktest egenmore estout outreg2 coefplot {
capture ssc install `z'
}

To run the rdrobust and rdplot commands you need to get the rdrobust package
You can obtain it from the author's webpage by typing the following in Stata:
net install rdrobust, from(https://sites.google.com/site/rdpackages/rdrobust/stata) replace

*/

//SET YOUR DIRECTORY HERE:
global DIRECTORY "D:\Folder\PUBLISH"

* WINDOWS DIRECTORY
global data "${DIRECTORY}\Data"
global dofiles "${DIRECTORY}\DoFiles"
global appendix "${DIRECTORY}\Results\Appendix"
global paper "${DIRECTORY}\Results\Paper"

* Preparation of databases used for analysis : 
do "$dofiles\Databases_preparation.do"

* Analysis :
do "$dofiles\Analysis.do"
