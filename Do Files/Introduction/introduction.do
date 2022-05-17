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
    display "`filename'"
    use "`filename'", clear
    append using `cps'
    save `cps', replace
    clear
	local filecount = `filecount' + 1
  }
}
*Retrieve the tempfile
use `cps'

*CPS Basic Data Dictionary
*https://www2.census.gov/programs-surveys/cps/datasets/2022/basic/2020_Basic_CPS_Public_Use_Record_Layout_plus_IO_Code_list.txt

*Check all years are there
tab hrmonth hryear4

**********
*By Sort and EGEN
**********
*You can summarize, replace, or create new variables by multiple groups 
*with the by sort and egen commands
*Let's generate laborforce
*1 is employed at work; 2 is employed absent; 3 is layoff; 4 is looking;
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

*Sort by Sex
sort pesex
*Summarize laborforce by sex
by pesex: sum laborforce
*Sort by Sex and Race
sort pesex race_ethnicity
*Summarize laborforce by sex and race
by pesex race_ethnicity: sum laborforce

*Generate Age Bin
gen over_16 = .
replace over_16 = 0 if prtage < 16
replace over_16 = 1 if prtage >= 16
label define over_16a 0 "Under 16" 1 "16 and older"
label values over_16 over_16a
tab over_16

*Generate unweighted laborforce participation rate for each group
*with by sort and egen
*bysort works, as well, but I usually use sort on one line and by on the other
sort pesex race_ethnicity
by pesex race_ethnicity: egen mean_lfpr = mean(laborforce) if over_16 == 1
by pesex race_ethnicity: sum mean_lfpr

*Counting and indexing within groups
gen idcount = .
by pesex race_ethnicity: replace idcount = _n
gen idcount2 = .
by pesex race_ethnicity: replace idcount2 = idcount[_N]

**********
*Weights
**********
*Adjust weights
*Usually we would need to divide by 12 for the Basic CPS to get annual weights
gen cmpwgt2 = pwcmpwgt/12
*Get a composite weight for all of the CPS files
gen cmpwgt3 = pwcmpwgt/`filecount'

svyset [pw=cmpwgt2]

svy: tab employed hryear4, count cellwidth(20) format(%20.2gc)

