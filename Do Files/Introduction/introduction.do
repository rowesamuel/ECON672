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

*Loop over each year
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

*Check all years are there
tab year

**********
*By Sort and EGEN
**********
*You can create new variables by groups with the by sort and egen commands
gen laborforce = .
replace laborforce = 0 if lfsr94 >= 5 & lfsr94 <= 7
replace laborforce = 1 if lfsr94 >= 1 & lfsr94 <= 4
label define laborforce1 0 "NILF" 1 "Labor Force"
label values laborforce laborforce1
tab laborforce

**********
*Weights
**********


