*Instrumental Variables
*Samuel Rowe - Copyright Scott Cunningham
*May 31, 2022

clear
set more off

*Main Stata command
help ivregress

**************************
*Card College in County IV
**************************
use https://github.com/scunning1975/mixtape/raw/master/card.dta, clear

* OLS estimate of schooling (educ) on log wages
reg lwage  educ  exper black south married smsa

* 2SLS estimate of schooling (educ) on log wages using "college in the county" as an instrument for schooling
ivregress 2sls lwage (educ=nearc4) exper black south married smsa, first 

* First stage regression of schooling (educ) on all covariates and the college and the county variable
reg educ nearc4 exper black south married smsa

* F test on the excludability of college in the county from the first stage regression.
test nearc4

**************************
*Stevenson Bail Judges IV
**************************

*SSC Install for Jive
net install st0108

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


* First stage
reg jail3 $judge_pre $control2, robust
reg jail3 possess robbery DUI1st drugSell aggAss $demo $prior $off  $control2 $judge_pre, robust



** Instrumental variables estimation
* 2sls main results
* minimum controls
ivregress 2sls guilt (jail3= $judge_pre) $control2, robust first
* maximum controls
ivregress 2sls guilt (jail3= $judge_pre) possess robbery DUI1st drugSell aggAss $demo $prior $off $control2 , robust first

* JIVE main results
* jive can be installed using: net from https://www.stata-journal.com/software/sj6-3/
*net install st0108

* minimum controls
jive guilt (jail3= $judge_pre) $control2, robust
* maximum controls
jive guilt (jail3= $judge_pre) possess robbery DUI1st drugSell aggAss $demo $prior $off $control2 , robust
clear all //Clear global macros
