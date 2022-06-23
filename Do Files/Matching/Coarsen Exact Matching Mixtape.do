*Coarsen Exact Matching Exercise
*Samuel Rowe - Copyright Scott Cunningham
*May 24, 2022

clear
set more off

****************
*Install Program
****************
ssc install cem

* Reload experimental group data
use https://github.com/scunning1975/mixtape/raw/master/nsw_mixtape.dta, clear
drop if treat==0

* Now merge in the CPS controls from footnote 2 of Table 2 (Dehejia and Wahba 2002)
append using https://github.com/scunning1975/mixtape/raw/master/cps_mixtape.dta

*Generate covariates
*Quadratic Age
gen agesq=age*age
*Cube Age
gen agecube=age*age*age
*Quadratic Education
gen edusq=educ*edu
*Generate Unemployed
gen u74 = 0 if re74!=.
replace u74 = 1 if re74==0
gen u75 = 0 if re75!=.
replace u75 = 1 if re75==0
*Education 
gen interaction1 = educ*re74
*Earnings Squared
gen re74sq=re74^2
gen re75sq=re75^2
*Interact unemployed 1974 and Latino/Hispanic
gen interaction2 = u74*hisp

*Run coarsen exact matching
*Set Age Cut Points are (10 20 30 40 60) - youngest age is 16 and oldest age is 55
cem age (10 20 30 40 60) age agesq agecube educ edusq marr nodegree black hisp re74 re75 u74 u75 interaction1, treatment(treat) 
reg re78 treat [iweight=cem_weights], robust

*The delta-hat for training is $2152.38
