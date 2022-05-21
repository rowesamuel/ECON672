*Matching 
*Samuel Rowe - Copyright Scott Cunningham
*May 21, 2022

clear
set more off

***************
*Exact Matching
***************
use https://github.com/scunning1975/mixtape/raw/master/training_example.dta, clear
gen id = _n
drop if id >= 21
destring earnings_treat, replace
drop id

*Calculate SDO
egen mean_y1 = mean(earnings_treat)
egen mean_y0 = mean(earnings_control)
gen sdo=mean_y1-mean_y0
*SDO shows training is negative -26.25

*View overlap between treatment and control with histograms
histogram age_treat, bin(10) frequency
histogram age_control, bin(10) frequency
*Summarize overlap between treatment and control
sum age_treat age_control
sum earnings_treat earnings_control

*View overlap between treatment and matched control with histograms
histogram age_treat, bin(10) frequency
histogram age_matched, bin(10) frequency
*Summarize overlap between treatment and matched control
sum age_treat age_control
sum earnings_matched earnings_matched

*Calculate ATE-hat
egen mean_y0_matched = mean(earnings_matched)
gen ate_hat=mean_y1-mean_y0_matched

