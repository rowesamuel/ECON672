*Randomization Inference
*Samuel Rowe - Copyright Scott Cunningham
*May 24, 2022

clear 
set more off

set seed 1234

*************************
*Randomization Inference
*************************
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

