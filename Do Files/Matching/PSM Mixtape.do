*Mixtape Tape PSM Example
*Samuel Rowe - Copyright Scott Cunningham
*May 17, 2022

*Source: https://github.com/scunning1975/mixtape/tree/master/Do

clear
set more off

*Main Stata command
*help teffects

************************************
*Generate Estimated Propensity Score
************************************
*Load experimental group data
*Get data from Scott's repository
use https://github.com/scunning1975/mixtape/raw/master/nsw_mixtape.dta, clear
drop if treat==0

* Now merge in the CPS controls from footnote 2 of Table 2 (Dehejia and Wahba 2002)
append using https://github.com/scunning1975/mixtape/raw/master/cps_mixtape.dta
*Age Squared
gen agesq=age*age
*Age Cubed
gen agecube=age*age*age
*Education Squared
gen edusq=educ*edu
*Unemployed in 1974 if earnings are 0
gen u74 = 0 if re74!=.
replace u74 = 1 if re74==0
*Unemployed in 1975 if earnings are 0
gen u75 = 0 if re75!=.
replace u75 = 1 if re75==0
*Education * 1974 Earnings Interaction
gen interaction1 = educ*re74
*Earnings 1974vSquared
gen re74sq=re74^2
*Earnings 1975 Squared
gen re75sq=re75^2
*Unemployed 1974 * Latino/Hispanic Interaction
gen interaction2 = u74*hisp

* Now estimate the propensity score
*Logit is used to calculate Pr(D=1|X)=F(B0+yD+aX) where F()=e/(1+e)
logit treat age agesq agecube educ edusq marr nodegree black hisp re74 re75 u74 u75 interaction1 
predict pscore

* Checking mean propensity scores for treatment and control groups
sum pscore if treat==1, detail
sum pscore if treat==0, detail

*The pscores are far apart
*If D=0 then the mean pscore is 0.01
*If D=1 then the mean pscore is 0.42

* Now look at the propensity score distribution for treatment and control groups
histogram pscore, by(treat) binrescale
*Very little overlap between treatment and control from the histogram

************************************
*Generate ATE ATT and Calculate SE
************************************
*Manually calculate inverse probability weighting with Propensity Scores
*Note: IPW is not matching, even though we use propensity scores
******
*Use all data
******
*ATE can be estimated by 1/n*Sigma(Yi*Di/pscorei)-1/n*Sigma((Yi*(1-Di))/(1-pscorei))
*Get normalization weights
gen d1=treat/pscore
gen d0=(1-treat)/(1-pscore)
*Sum the inverse pscore
egen s1=sum(d1)
egen s0=sum(d0) 
gen total = _N
egen total_T = sum(treat)
egen total_C = sum(1-treat)

* Manual with non-normalized weights using all the data
*Y1: E[Y1]=1/n*Sigma(Y*D/p(x))
gen y1=treat*re78/pscore
egen y1_2 = sum(y1)
gen y1_3 = y1_2/total
*Y0: E[Y0]=1/n*Sigma(Y*(1-D)/(1-p(x)))
gen y0=(1-treat)*re78/(1-pscore) 
egen y0_2 = sum(y0)
gen y0_3 = y0_2/total
*ATE=E[Y1]-E[Y0]

*Difference in E[Y1]-E[Y0]
*Way 1
gen ht=y1-y0
*Way 2
gen ht2=y1_3-y0_3
*Same results
sum ht ht2
*Given that the mean 1-p(x) is close to 1, a lot of weight is given to Y0

* Manual with normalized weights
*Way 1
replace y1=(treat*re78/pscore)/(s1/total)
replace y0=((1-treat)*re78/(1-pscore))/(s0/total)
*Way 2
replace y1_3=y1_2/s1
replace y0_3=y0_2/s0
*Get the estimated ATE
gen norm=y1-y0
gen norm2=y1_3-y0_3
*Same Results for ht:ht2 and norm:norm2
sum ht ht2 norm norm2

* ATE under non-normalized weights is -$11,876
* ATE under normalized weights is -$7,238

drop d1 d0 s1 s0 y1 y0 ht norm
********
*Trimming the propensity score (not all of the data)
********
drop if pscore <= 0.1 
drop if pscore >= 0.9

histogram pscore, by(treat) binrescale

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

* ATE under non-normalized weights is $2,006
* ATE under normalized weights is $1,806
************************************
*STATA's teffects command n-nearest neighbor
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

*The ATT is 1725.082
 
drop pstub_cps*

* Trimming the propensity score for balance
drop if pscore <= 0.1 
drop if pscore >= 0.9

* Now look at the propensity score distribution for treatment and control groups
histogram pscore, by(treat) binrescale


*Estimate ATE
*Trim [0.1,0.9]
teffects psmatch (re78) (treat age agesq agecube educ edusq marr nodegree black ///
 hisp re74 re75 u74 u75 interaction1, logit), ate gen(pstub_cps) nn(5)

*The ATE is 1758.837
 
drop pstub_cps* 
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
*Divide re78 by 1000 dollars
gen re78_scaled = re78/1000
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

*The ATT is estimated at $2647 
 
*ATE
teffects ipw (re78_scaled) (treat age agesq agecube educ edusq marr nodegree ///
black hisp re74 re75 u74 u75 interaction1, logit), osample(overlap) ate

*The ATE is estimated at $1611
