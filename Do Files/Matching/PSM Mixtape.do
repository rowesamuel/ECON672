*Mixtape Tape PSM Example
*Samuel Rowe - Copyright Scott Cunningham
*May 17, 2022

*Source: https://github.com/scunning1975/mixtape/tree/master/Do

clear
set more off

************************************
*Generate Estimated Propensity Score
************************************
*Load experimental group data
*Get data from Scott's repository
use https://github.com/scunning1975/mixtape/raw/master/nsw_mixtape.dta, clear
drop if treat==0

* Now merge in the CPS controls from footnote 2 of Table 2 (Dehejia and Wahba 2002)
append using https://github.com/scunning1975/mixtape/raw/master/cps_mixtape.dta
gen agesq=age*age
gen agecube=age*age*age
gen edusq=educ*edu
gen u74 = 0 if re74!=.
replace u74 = 1 if re74==0
gen u75 = 0 if re75!=.
replace u75 = 1 if re75==0
gen interaction1 = educ*re74
gen re74sq=re74^2
gen re75sq=re75^2
gen interaction2 = u74*hisp

* Now estimate the propensity score
logit treat age agesq agecube educ edusq marr nodegree black hisp re74 re75 u74 u75 interaction1 
predict pscore

* Checking mean propensity scores for treatment and control groups
sum pscore if treat==1, detail
sum pscore if treat==0, detail

* Now look at the propensity score distribution for treatment and control groups
histogram pscore, by(treat) binrescale

************************************
*Generate ATE ATT and Calculate SE
************************************
* Manual with non-normalized weights using all the data
gen d1=treat/pscore
gen d0=(1-treat)/(1-pscore)
egen s1=sum(d1)
egen s0=sum(d0)

gen y1=treat*re78/pscore
gen y0=(1-treat)*re78/(1-pscore)
gen ht=y1-y0

* Manual with normalized weights
replace y1=(treat*re78/pscore)/(s1/_N)
replace y0=((1-treat)*re78/(1-pscore))/(s0/_N)
gen norm=y1-y0
sum ht norm

* ATT under non-normalized weights is -$11,876
* ATT under normalized weights is -$7,238

drop d1 d0 s1 s0 y1 y0 ht norm

* Trimming the propensity score
drop if pscore <= 0.1 
drop if pscore >= 0.9

* Manual with non-normalized weights using trimmed data
gen d1=treat/pscore
gen d0=(1-treat)/(1-pscore)
egen s1=sum(d1)
egen s0=sum(d0)

gen y1=treat*re78/pscore
gen y0=(1-treat)*re78/(1-pscore)
gen ht=y1-y0

* Manual with normalized weights using trimmed data
replace y1=(treat*re78/pscore)/(s1/_N)
replace y0=((1-treat)*re78/(1-pscore))/(s0/_N)
gen norm=y1-y0
sum ht norm

* ATT under non-normalized weights is $2,006
* ATT under normalized weights is $1,806
************************************
*STATA's teffects command
************************************
************************************
*Generate Estimated Propensity Score
************************************
* Reload experimental group data
*Get data from Scott's repository
use https://github.com/scunning1975/mixtape/raw/master/nsw_mixtape.dta, clear
drop if treat==0

* Now merge in the CPS controls from footnote 2 of Table 2 (Dehejia and Wahba 2002)
append using https://github.com/scunning1975/mixtape/raw/master/cps_mixtape.dta
gen agesq=age*age
gen agecube=age*age*age
gen edusq=educ*edu
gen u74 = 0 if re74!=.
replace u74 = 1 if re74==0
gen u75 = 0 if re75!=.
replace u75 = 1 if re75==0
gen interaction1 = educ*re74
gen re74sq=re74^2
gen re75sq=re75^2
gen interaction2 = u74*hisp

* Now estimate the propensity score
logit treat age agesq agecube educ edusq marr nodegree black hisp re74 re75 u74 u75 interaction1 
predict pscore

* Checking mean propensity scores for treatment and control groups
sum pscore if treat==1, detail
sum pscore if treat==0, detail

* Now look at the propensity score distribution for treatment and control groups
histogram pscore, by(treat) binrescale


*PSM with nearest neighbor
*Estimate ATT
teffects psmatch (re78) (treat age agesq agecube educ edusq marr nodegree black ///
 hisp re74 re75 u74 u75 interaction1, logit), atet gen(pstub_cps) nn(5)
 
* Trimming the propensity score for balance
drop if pscore <= 0.1 
drop if pscore >= 0.9

* Now look at the propensity score distribution for treatment and control groups
histogram pscore, by(treat) binrescale


*Estimate ATE
*Trim [0.1,0.9]
teffects psmatch (re78) (treat age agesq agecube educ edusq marr nodegree black ///
 hisp re74 re75 u74 u75 interaction1, logit), ate gen(pstub_cps) nn(5)
 
******************
*teffects with IPW
******************
*Reload Data
use https://github.com/scunning1975/mixtape/raw/master/nsw_mixtape.dta, clear
drop if treat==0

* Now merge in the CPS controls from footnote 2 of Table 2 (Dehejia and Wahba 2002)
append using https://github.com/scunning1975/mixtape/raw/master/cps_mixtape.dta
gen agesq=age*age
gen agecube=age*age*age
gen edusq=educ*edu
gen u74 = 0 if re74!=.
replace u74 = 1 if re74==0
gen u75 = 0 if re75!=.
replace u75 = 1 if re75==0
gen interaction1 = educ*re74
gen re74sq=re74^2
gen re75sq=re75^2
gen interaction2 = u74*hisp

* Now estimate the propensity score
logit treat age agesq agecube educ edusq marr nodegree black hisp re74 re75 u74 u75 interaction1 
predict pscore

* Checking mean propensity scores for treatment and control groups
sum pscore if treat==1, detail
sum pscore if treat==0, detail

* Now look at the propensity score distribution for treatment and control groups
histogram pscore, by(treat) binrescale



* Use teffects to calculate inverse probability weighted regression
*rescale for concavity of logit
gen re78_scaled = re78/10000
capture noisily teffects ipw (re78_scaled) (treat age agesq agecube educ edusq ///
marr nodegree black hisp re74 re75 u74 u75 interaction1, logit), osample(overlap)

keep if overlap==0
drop overlap
capture noisily teffects ipw (re78_scaled) (treat age agesq agecube educ edusq ///
marr nodegree black hisp re74 re75 u74 u75 interaction1, logit), osample(overlap)

capture drop overlap

* Trimming the propensity score
drop if pscore <= 0.1 
drop if pscore >= 0.9

*ATT
teffects ipw (re78_scaled) (treat age agesq agecube educ edusq marr nodegree ///
black hisp re74 re75 u74 u75 interaction1, logit), osample(overlap) atet
capture drop overlap
 
*ATE
teffects ipw (re78_scaled) (treat age agesq agecube educ edusq marr nodegree ///
black hisp re74 re75 u74 u75 interaction1, logit), osample(overlap) ate
 
