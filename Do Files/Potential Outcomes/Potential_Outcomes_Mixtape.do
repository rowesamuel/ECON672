*Independence Test Through Monte Carlo simulation
*Samuel Rowe - Copyright Scott Cunningham
*May 21, 2022

clear
set more off

*****************************
*Test Independence Assumption
*
*We cannot observe y1 and y0, so we cannot directly test the independence 
*assumption.  However, we will create some hypothetical data for y1 and y0
*to show how the independence assumption works
*****************************

clear all
program define gap, rclass

	version 14.2
	syntax [, obs(integer 1) mu(real 0) sigma(real 1) ]
	clear
	drop _all
	set obs 10
	gen 	y1 = 7 in 1
	replace y1 = 5 in 2
	replace y1 = 5 in 3
	replace y1 = 7 in 4
	replace y1 = 4 in 5
	replace y1 = 10 in 6
	replace y1 = 1 in 7
	replace y1 = 5 in 8
	replace y1 = 3 in 9
	replace y1 = 9 in 10

	gen 	y0 = 1 in 1
	replace y0 = 6 in 2
	replace y0 = 1 in 3
	replace y0 = 8 in 4
	replace y0 = 2 in 5
	replace y0 = 1 in 6
	replace y0 = 10 in 7
	replace y0 = 6 in 8
	replace y0 = 7 in 9
	replace y0 = 8 in 10
	drawnorm random
	sort random

	gen 	d=1 in 1/5
	replace d=0 in 6/10
	gen 	y=d*y1 + (1-d)*y0
	egen sy1 = mean(y) if d==1
	egen sy0 = mean(y) if d==0			
	collapse (mean) sy1 sy0
	gen sdo = sy1 - sy0
	keep sdo
	summarize sdo
	gen mean = r(mean)
	end

simulate mean, reps(10000): gap
su _sim_1 

********************************
*Randomized Inference
*
*A placebo-based test to calculate exact p-values. We need every single
*permutation of treatment to calculate the exact p-values from the ATE
********************************

clear 

set seed 1234

*Get Data from Github
use https://github.com/scunning1975/mixtape/raw/master/ri.dta, clear

tempfile ri
gen id = _n
save "`ri'", replace

* Create all combinations 
* ssc install percom

*Out of 8 observations, we get 70 permutations
combin id, k(4)
*ID count of permutations
gen permutation = _n
tempfile combo
save "`combo'", replace

forvalue i =1/4 {
	rename id_`i' treated`i'
}
*

destring treated*, replace
cross using `ri'
*Your first permutation is the one of interest
sort permutation name
*Randomize the treatment assignment and calculate other test statistics
gen d2 = .
replace d2 = 1 if id == treated1 | id == treated2 | id == treated3 | id == treated4
replace d2 = 0 if ~(id == treated1 | id == treated2 | id == treated3 | id == treated4)
gen check = d - d2

* Calculate true effect using absolute value of SDO
egen te1 = mean(y) if d2==1, by(permutation)
egen te0 = mean(y) if d2==0, by(permutation)

*Get ATE
collapse (mean) te1 te0, by(permutation)
gen 	ate = te1 - te0
keep 	ate permutation

*Rank Permutations
gsort -ate
gen rank = _n
sum rank if permutation==1
*Calculate Exact P-value
gen pvalue = (`r(mean)'/70)
list pvalue if permutation==1
* pvalue equals 0.6


