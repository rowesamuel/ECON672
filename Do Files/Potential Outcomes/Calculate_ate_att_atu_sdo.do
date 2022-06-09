*Calculate ATE, ATT, ATU, and SDO
*Samuel Rowe
*May 17, 2022

clear
set more off

*Get Small potential outcomes data set
use "https://github.com/rowesamuel/ECON672/blob/main/Data/Potential%20Outcomes/potential_outcomes.dta?raw=true"

*Calculate ATE
egen mean_y1 = mean(Y1)
egen mean_y0 = mean(Y0)
gen ate = mean_y1 - mean_y0

*Calculate ATT
egen mean_y1_d1 = mean(Y1) if Treatment == 1
egen mean_y0_d1 = mean(Y0) if Treatment == 1
gen att = mean_y1_d1 - mean_y0_d1

*Calculate ATU
egen mean_y1_d0 = mean(Y1) if Treatment == 0
egen mean_y0_d0 = mean(Y0) if Treatment == 0
gen atu = mean_y1_d0 - mean_y0_d0

*Calculate SDO
*We cannot calculate mean_y1_d1 and mean_y0_d0 because their blank in the other
*column.  We can generate a new column and fill in the NAs
*Set up a duplicate column for Y1 when D=1
gen mean_y1_d1_a = mean_y1_d1
*Since the first value has a value we can push forward
replace mean_y1_d1_a = mean_y1_d1_a[_n-1] if missing(mean_y1_d1_a)

*Set Up a duplicate column for Y0 when D=0
gen mean_y0_d0_a = mean_y0_d0
*Since the first value is missing we will put last value first and push
*the value forward
replace mean_y0_d0_a = mean_y0_d0_a[_N] if missing(mean_y0_d0_a[1])
replace mean_y0_d0_a = mean_y0_d0_a[_n-1] if missing(mean_y0_d0_a)
*You could just replace all of the missing with a known value like row 3 with [3]
*For example: replace mean_y0_d0_a = mean_y0_d0_a[3] if missing(mean_y0_d0_a)
gen sdo = .
replace sdo = mean_y1_d1_a - mean_y0_d0_a

list ate sdo if _n ==1

