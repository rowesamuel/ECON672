*Week 1: Brief Intro to Stata Techniques
*Samuel Rowe
*May 16, 2022

*********************Overview***************************************************
*A brief overview of techniques that will be helpful for completing 
*assignments and empirical project
*Topics include - Local Macros, Loops, Tempfiles, By Sort and Egen, and Weights
********************************************************************************


*Always a good idea to clear your memory and turn more off initially
clear
set more off 

**********
*Macros
**********

*Macros can contain strings or numerics

*Local Macros* - local macros work within a single executed do file and
*removed once the session is run.
*If you are running local macros you must run the line of code that initializes 
*the macro and the command that utilizes it.

*You need to initialize the local macro
*E.g.: local i = 1
*You need to call the macro with `'
*E.g.: display "`i'" 
*E.g.: replace x = 0 if y = `i'

local i = 1
display "`i'"
local k = `i' + 1
display "`k'"

*Global Macros* - stays within memory; can work across multiple do files 
*You need to initialize a global macro 
*E.g.: global j = 2
*You need to call the macro with $
*E.g.: display "$j"
*E.g.: replace z = 1 if y = $i
global j = 2
display "$j"

*Now rerun without initilizing the global macro
display "$j"

*You can set lists for local levels of a categorical variable
*E.g.: 
*levelsof varname, local(levels) 
*foreach l of local levels {
*  command if varname == `l'
* }
*We'll demo this later, but it is quite useful

**********
*Looping
**********
*Looping has many uses when you want to apply a function or command over 
*a repeated set of values
*There is forvalues and foreach - I typically use foreach given it's versatility
*but Stata says that forvalues can be more efficient
*E.g.: Loop over years and iterate i
local i = 0
foreach num of numlist 2000/2019 {
  display "`num'"
  local i = `i'+1
  display "`i'"
}
*E.g.: Loop over months and years to read in new files
local month jan feb mar apr may jun jul aug sep oct nov dec
foreach y of numlist 2018/2019 {
  foreach m of local month {
    local filename = "`m'`y'.dta"
	display "`filename'"
  }
}
**********
*Tempfiles
**********
*Tempfiles are useful since they are a bypass around a Stata limitation
*of one dataframe at a time.  Later iterations of Stata introduced the 
*dataframe functionality, but the tempfile method still works well.
*We will append three years of CPS MORG data from NBER and generate 
*short 1-year panels.
*Tempfiles are really just macros

*Appending multiple CPS files 
*Get CPS Data

*Set link into macro
local url "https://github.com/rowesamuel/ECON672/blob/main/Data/Introduction/"
*https://github.com/rowesamuel/ECON672/blob/main/Data/Introduction/small_morg2017.dta?raw=true

*Set up initial tempfile so we can add each year of CPS data
*Save the macro and set it to emptyok
tempfile cps
save `cps', emptyok

*Use Census CPS instead of NBER MORG

*Loop over each year and append 3 small MORG files into 1 cps file
*Small MORG file only has individuals for MD, VA, and D.C.
foreach y of numlist 2017/2019 {
  *Show the year
  display "`y'"
  local filename "`url'small_morg`y'.dta?raw=true"
  display "`filename'"
  use "`filename'", clear
  append using `cps'
  save `cps', replace
  clear
}
*Get all 3 years of CPS data
use `cps'

*CPS MORG Data Dictionary
*https://data.nber.org/morg/docs/cpsx.pdf

*Check all years are there
tab year

**********
*By Sort and EGEN
**********
*You can summarize, replace, or create new variables by multiple groups 
*with the by sort and egen commands
*Let's generate laborforce
*1 is employed at work; 2 is employed absent; 3 is layoff; 4 is looking;
*5 is NILF retired; 6 is NILF disabiled; and 7 is NILF other
gen laborforce = .
replace laborforce = 0 if lfsr94 >= 5 & lfsr94 <= 7
replace laborforce = 1 if lfsr94 >= 1 & lfsr94 <= 4
label define laborforce1 0 "NILF" 1 "Labor Force"
label values laborforce laborforce1
tab laborforce

*Generate a race/ethnicity category from existing 
gen race_ethnicity = .
replace race_ethnicity = 1 if race == 1 & ethnic == .
replace race_ethnicity = 2 if race == 2 & ethnic == .
replace race_ethnicity = 3 if ethnic >= 1 & ethnic <= 8
replace race_ethnicity = 4 if race == 3 & ethnic == .
replace race_ethnicity = 5 if (race == 4 | race == 5) & ethnic == .
replace race_ethnicity = 6 if (race >= 6 & race <= 26) & ethnic == .
label define race_ethnicity1 1 "White NH" 2 "Black NH" 3 "Hispanic or Latino/a" ///
4 "Native American NH" 5 "Asian or Pacific Islander NH" 6 "Multiracial NH"
label values race_ethnicity race_ethnicity1
tab race_ethnicity 

*Sort by Sex
sort sex
*Summarize laborforce by sex
by sex: sum laborforce
*Sort by Sex and Race
sort sex race_ethnicity
*Summarize laborforce by sex and race
by sex race_ethnicity: sum laborforce

*Generate unweighted laborforce participation rate for each group
*with by sort and egen
*bysort works, as well, but I usually use sort on one line and by on the other
sort sex race_ethnicity
by sex race_ethnicity: egen mean_lfpr = mean(laborforce)

**********
*Weights
**********
*Adjust weights
*Usually we would need to divide by 12 for the Basic CPS
*For the CPS NBER MORG, we need to divide by 3*x where x is the number of years
*for a composite or for annual weights divide by 3
gen earnwt2 = earnwt/9
gen cmpwgt2 = cmpwgt/(3*3)

svyset [pw=earnwt2], strata(cbsafips)

svy: tab laborforce year 

