*Fixed Effects (Within Estimator)
*Samuel Rowe - copyright Scott Cunningham
*June 21, 2022

clear
set more off

************************
*Mixtape Exercise
************************
use https://github.com/scunning1975/mixtape/raw/master/sasp_panel.dta, clear
*Set up the panel with tsset
*tsset unit(i) time(t)
*You could use xtset and I recommend using xtset instead of tsset for panel data
*tsset id session
xtset id session

*Find units with 4 observations
local varlist lnw age asq bmi hispanic black other asian schooling cohab married divorced separated age_cl unsafe llength reg asq_cl appearance_cl provider_second asian_cl black_cl hispanic_cl othrace_cl hot massage_cl 
foreach x of local varlist {
  drop if `x'==.
  bysort id: gen s=_N
  keep if s==4
  drop s
}
*Demean the Data
foreach x of local varlist {
  egen mean_`x'=mean(`x'), by(id)
  gen demean_`x'=`x' - mean_`x'
  drop mean*
}
*Pooled OLS
est clear
eststo pooled: xi: reg lnw  age asq bmi hispanic black other asian schooling cohab married divorced separated age_cl unsafe llength reg asq_cl appearance_cl provider_second asian_cl black_cl hispanic_cl othrace_cl hot massage_cl, robust
*Fixed Effects
eststo fixed: xi: xtreg lnw  age asq bmi hispanic black other asian schooling cohab married divorced separated age_cl unsafe llength reg asq_cl appearance_cl provider_second asian_cl black_cl hispanic_cl othrace_cl hot massage_cl, fe i(id) robust
*Demeaned Estimator (Manually doing fixed effects)
eststo demean: reg demean_lnw demean_age demean_asq demean_bmi demean_hispanic demean_black demean_other demean_asian demean_schooling demean_cohab demean_married demean_divorced demean_separated demean_age_cl demean_unsafe demean_llength demean_reg demean_asq_cl demean_appearance_cl demean_provider_second demean_asian_cl demean_black_cl demean_hispanic_cl demean_othrace_cl demean_hot demean_massage_cl, robust cluster(id)

esttab pooled fixed demean


*Discussion
*All time invariant demeaned data become zero in the 3rd model

************************
*CPS
************************
*What is the impact of unionization on wages?
*We can get a correlation by including unionization but it will be
*correlated/endogenous with other factors of interest (schooling, ability, etc.).
*We want to set up a panel to control for time-invariant heterogeneity to 
*assess the impact of unionization on wages


*Appending multiple CPS files 
*Get CPS Data
clear
*Set link into macro
local url "https://github.com/rowesamuel/ECON672/blob/main/Data/Introduction/"
*https://github.com/rowesamuel/ECON672/blob/main/Data/Introduction/small_morg2017.dta?raw=true

*Set up initial tempfile so we can add each year of CPS data
*Save the macro and set it to emptyok
tempfile cps
save `cps', emptyok

*Use Census CPS instead of NBER MORG
*cd "/Users/Sam/Desktop/Econ 672/Course Material/ECON672/Data/Introduction"
*Loop over each year and month to append monthly CPS files into 1 cps file
local month jan feb mar apr may jun jul aug sep oct nov dec
local filecount = 0
*Small CPS Files have only a few variables in them compared to the usual
*CPS files found at
*https://www.census.gov/data/datasets/time-series/demo/cps/cps-basic.html
foreach y of numlist 20/21 {

  foreach m of local month {
    *Show the year and month
    display "`m'`y'"
    local filename "`url'small_`m'`y'pub.dta?raw=true"
    *local filename "small_`m'`y'pub.dta"
	display "`filename'"
    *Open the monthly data file
	use "`filename'", clear
	*Append monthly data file to cps tempfile
    append using `cps'
	*Save the tempfile with appended data
    save `cps', replace
    clear
	*Count the number of monthly files appended
	local filecount = `filecount' + 1
  }
}
*Retrieve the tempfile
use `cps'

*******************
*Set Up Panel
*******************
*Keep MORG
keep if hrmis == 4 | hrmis == 8
*We want 2020 to be the 4th interview and 2021 to be the 8th interview
drop if (hryear4 == 2020 & hrmis == 8) | (hryear4 == 2021 & hrmis == 4)

*Less than 16 are dropped
drop if prtage < 16 | prtage == .

*Check
tab hrmis hryear

*Generate IDs
*Concatenate hhid, hrhhid2 and lineno for a unique 22-digit personal id
*Fix scientific notation in long string
format hrhhid %20.0f
*Create a Unique ID with group function in egen
egen id = group(hrhhid hrhhid2 pulineno)

*Check that it is the same household (hrhhid and hrhhid2) and person (pulineno)
order id hrhhid hrhhid2 pulineno hrmis
sort id hrmis
by id: gen id_count = _N
tab id_count hrmis

*Drop single observations 
drop if id_count == 1

*Sort ID by interview
sort id hrmis

*Find observations that change sex or race and 1-year increase in age
*Set the panel with xtset (unit) (time)
xtset id hryear4

*We could you hrmis but Stata will detect a gap between 4 and 8
*but we set up 2020 to be 4 and 2021 to be 8, so we will use hryear
*This matters when using the l. operator

*After xtset use the l. operator for 1-time period lag
*Generate a race/ethnicity category from existing 
gen race_ethnicity = .
replace race_ethnicity = 1 if ptdtrace == 1 & pehspnon == 2
replace race_ethnicity = 2 if ptdtrace == 2 & pehspnon == 2
replace race_ethnicity = 3 if pehspnon == 1
replace race_ethnicity = 4 if ptdtrace == 3 & pehspnon == 2
replace race_ethnicity = 5 if (ptdtrace == 4 | ptdtrace == 5) & pehspnon == 2
replace race_ethnicity = 6 if (ptdtrace >= 6 & ptdtrace <= 26) & pehspnon == 2
label define race_ethnicity1 1 "White NH" 2 "Black NH" 3 "Hispanic or Latino/a" ///
4 "Native American NH" 5 "Asian or Pacific Islander NH" 6 "Multiracial NH"
label values race_ethnicity race_ethnicity1
tab race_ethnicity 

*Sex
gen lag_sex = l.pesex
gen sex_diff = pesex-lag_sex
tab sex_diff
*Age
gen lag_age = l.prtage
gen age_diff = prtage-lag_age
tab age_diff
*Race
gen lag_race = l.race_ethnicity
gen race_diff = race_ethnicity-lag_race
tab race_diff

*Keep those that don't change sex or race
keep if sex_diff == 0 | sex_diff == .
keep if race_diff == 0 | race_diff == .
keep if age_diff == . | age_diff < 6
keep if age_diff == . | age_diff >= 0

*Sort and drop observations with only 1 observation
sort id hryear4
by id: gen id_count2 = _N
tab id_count2
drop if id_count2 == 1

*******************
*Generate variables
*******************
***********
*Mincer Equation Example
***********
*Important Note
*Missing values are set to -1 in the CPS PUMS (public-use micro dataset)

*You can summarize, replace, or create new variables by multiple groups 
*with the by sort and egen commands
*Let's generate laborforce
*1 is employed at work; 2 is employed absent; 3 is unemployed layoff; 4 is unemployed looking;
*5 is NILF retired; 6 is NILF disabiled; and 7 is NILF other
gen laborforce = .
replace laborforce = 0 if pemlr >= 5 & pemlr <= 7
replace laborforce = 1 if pemlr >= 1 & pemlr <= 4
label define laborforce1 0 "NILF" 1 "Labor Force"
label values laborforce laborforce1
tab laborforce

gen employed = .
replace employed = 0 if pemlr >= 3 & pemlr <= 7
replace employed = 1 if pemlr >= 1 & pemlr <= 2
label define employed1 0 "Not Employed" 1 "Employed"
label values employed employed1
tab employed



*Recategorize Female
gen female = .
replace female = 0 if pesex == 1
replace female = 1 if pesex == 2
label define female1 0 "Male" 1 "Female"
label values female female1
label variable female "Individual is Female"

*Generate Union - Treatment variable of interest
gen union = .
replace union = 0 if peernlab == 2
replace union = 1 if peernlab == 1
label define union1 0 "Nonunion" 1 "Union"
label values union union1
label variable "Individual is a Union Member"

*Earnings - PTERNWA
*Documentation says that they imply 2 decimals so we need to divide by 100
gen earnings = .
replace earnings = pternwa if pternwa >= 0
*Divide by 100 for decimals
replace earnings = earnings/100

*Generate Educational Bins
tab peeduca
gen educ = .
*High School Drop Out: from Less than 1st Grade to 12th Grade No Diploma
replace educ = 1 if peeduca >= 31 & peeduca <38
*Graduated High School or GED
replace educ = 2 if peeduca == 39
*Some College
replace educ = 3 if peeduca == 40
*AA Degree: Vocational or Academic
replace educ = 4 if peeduca == 41 | peeduca == 42
*Bachelor's Degree
replace educ = 5 if peeduca == 43
*Advanced Degree: Master's, Professional, or Doctorate
replace educ = 6 if peeduca >= 44 & peeduca <= 46
label define educ1 1 "High School Dropout" 2 "High School Graduate" ///
                   3 "Some College" 4 "Associates (VorA) Degree" ///
				   5 "Bachelor's Degree" 6 "Advanced Degree"
label values educ educ1

*Caveat with Generating Categorical Variables in Stata
*Don't do peeduca >= 44 without peeduca <= 46 since missing values are very large
*So you if do peeduca >= 44 and missing peeduca is . then missing will get 
*Categorized in Advanced Degree which will be a measurement error

*Generate Potential Experience
gen exp = prtage - 16
gen exp2 = exp*exp

*Natural log of wages
gen ln_wages = ln(pternwa)

**************
*Demean
**************
local vars1 ln_wages educ exp exp2 female race_ethnicity union peio1icd

*Demean the Data
foreach x of local vars1 {
  egen mean_`x'=mean(`x'), by(id)
  gen demean_`x'=`x' - mean_`x'
  drop mean*
}
*Pooled
est clear
eststo: reg ln_wages exp exp2 i.educ female race_ethnicity union i.peio1icd, robust
*Panel Fixed Effects (Within Estimator)
eststo: xtreg ln_wages exp exp2 i.educ female race_ethnicity union i.peio1icd, fe robust
*Demean (Slightly different than Fixed Effects due to categorical variables)
reg demean_ln_wages demean_exp demean_exp2 demean_educ demean_female demean_race_ethnicity demean_union demean_peio1icd, robust cluster(id)
*One problem is that we cannot study race, ethnicity, or sex with fixed effects

esttab, wide
*Pooled OLS shows that unionization is associated with ~16.1 percent increase
*in wages
*Within Fixed Effects Estimators shows that unionization ~2.7 percent increase
*in wages - which is unbiased if the strict exogeneity assumption hold (no
*time-varying heterogeneity)
*The demeaned OLS shows a similar result to the Within Fixed Effects estimator

