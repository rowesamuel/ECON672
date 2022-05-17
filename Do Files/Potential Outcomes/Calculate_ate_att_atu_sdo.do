*Calculate ATE, ATT, ATU, and SDO
*Samuel Rowe
*May 17, 2022

clear
set more

*Get Small potential outcomes data set
local url "https://github.com/rowesamuel/ECON672/blob/main/Data/Potential Outcomes/"
use "`url'potential_outcomes.dta?raw=true", clear

