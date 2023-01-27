*Instrumental Variables
*Samuel Rowe - Copyright Scott Cunningham
*May 31, 2022

clear
set more off

*Main Stata command
*help ivregress

**************************
*Card College in County IV
**************************
use https://github.com/scunning1975/mixtape/raw/master/card.dta, clear

* OLS estimate of schooling (educ) on log wages
* We know that the estimate delta on educ is biased - self selection into schooling
reg lwage  educ  exper black south married i.smsa
* Returns to education is a 7.3 percent increase with a marginal increase of 1 year


* We can use the 
* 2SLS estimate of schooling (educ) on log wages using "college in the county" as an instrument for schooling
ivregress 2sls lwage (educ=nearc4) exper black south married i.smsa, first 
* Our 2SLS estimate of the LATE is 13.5%.  Being near a college increases
* the wages by 13.5% for compliers 

* First stage regression of schooling (educ) on all covariates and the college and the county variable
reg educ nearc4 exper black south married smsa
* Causal effect of distance to college in county on education is 38.7%

* F-test on 1-stage
* F-test on the excludability of college in the county from the first stage regression.
test nearc4

*The F-statistic is 15.767 which is indicative of a good instrument

*Test monotonicity 
*Get first-stage estimate
reg educ nearc4 exper black south married smsa
predict dhat

*Average outcome across dhat
*Get Bins of outcomes
sum lwage, detail
egen lwage_bins = cut(lwage), at(5,5.5,6,6.5,7,7.5)
sort lwage_bins
by lwage_bins: egen dhat_mean=mean(dhat)
by lwage_bins: egen mean_z=mean(nearc4)

*Show Monotonicity Graph 
*By D-Hat
sort dhat_mean
twoway line lwage_bins dhat_mean
*By Z
sort mean_z
twoway line lwage_bins mean_z

**************************
*Stevenson Bail Judges IV
**************************

*SSC Install for Jive
*net install st0108

use https://github.com/scunning1975/mixtape/raw/master/judge_fe.dta, clear

*Set up global macros 
global judge_pre judge_pre_1 judge_pre_2 judge_pre_3 judge_pre_4 judge_pre_5 judge_pre_6 judge_pre_7 judge_pre_8
global demo black age male white 
global off  	fel mis sum F1 F2 F3 F M1 M2 M3 M 
global prior priorCases priorWI5 prior_felChar  prior_guilt onePrior threePriors
global control2 	day day2 day3  bailDate t1 t2 t3 t4 t5 t6


* Naive OLS
* minimum controls
reg guilt jail3 $control2, robust
* maximum controls
reg guilt jail3 possess robbery DUI1st drugSell aggAss $demo $prior $off  $control2 , robust
* Minimal OLS estimate of pretrail detention on guilty plea is -0.0007 increase in 
* percentage points of a guily plea, while maximum controls yields an estimate of
* 2.9 percentage points.

* First stage using Judge Fixed Effects
reg jail3 $judge_pre $control2, robust
reg jail3 possess robbery DUI1st drugSell aggAss $demo $prior $off  $control2 $judge_pre, robust

** Instrumental variables estimation
* 2sls main results
* minimum controls
ivregress 2sls guilt (jail3= $judge_pre) $control2, robust first
* Our LATE estimate is an increase of guilty plea by 15 percentage points for
* individuals with a guilty plea

*Check F-statistic in 1st stage
reg jail3 $judge_pre $control2, robust first
test $judge_pre

* maximum controls
ivregress 2sls guilt (jail3= $judge_pre) possess robbery DUI1st drugSell aggAss $demo $prior $off $control2 , robust first
* Our LATE estimate is an increase of guilty plea by 18.6 percentage points for
* individuals with a guilty plea

*Check F-statistic in 1st stage
reg jail3 $judge_pre possess robbery DUI1st drugSell aggAss $demo $prior $off $control2 , robust first
test $judge_pre


* JIVE main results
*Jackknife Instrumental Variable Estimator (JIVE)
* jive can be installed using: net from https://www.stata-journal.com/software/sj6-3/
*net install st0108

* minimum controls
jive guilt (jail3= $judge_pre) $control2, robust
* Our estimated LATE with JIVE is a 16.2 percentage point increase in a guilty
* plea for individuals with a pre-trail detention
* maximum controls
jive guilt (jail3= $judge_pre) possess robbery DUI1st drugSell aggAss $demo $prior $off $control2 , robust
* Our estimated LATE with JIVE is a 21.2 percentage point increase in a guilty
* plea for individuals with a pre-trail detention

clear all 
* Clear global macros
macro drop _all
