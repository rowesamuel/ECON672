*Week 1: Brief Intro to Stata Techniques
*Samuel Rowe
*May 16, 2022

*********************Overview***************************************************
*A brief overview of techniques that will be helpful for completing 
*assignments and empirical project
*Topics include - Local Macros, Loops, Tempfiles, 
********************************************************************************


*Always a good idea to clear your memory and turn more off initially
clear
set more off 

**********
*Macros
**********
*Local Macros

*Global Macros


**********
*Looping
**********

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

*Set up initial tempfile so we can add each year of CPS data
*Save the macro and set it to emptyok
tempfile cps
save `cps', emptyok

*Loop over each year
foreach y of numlist 2017/2019 {
  *Show the year
  display "`y'"
  local filename "`url'`y'.dta"
  display "`filename'"
  use "`filename'", clear
  append using `cps'
  save `cps', replace
  clear
}
*Get all 3 years of CPS data
use `cps'

*Set up initial tempfile so we can add each year of CPS data
*Save the macro and set it to emptyok
tempfile cps
save `cps', emptyok

*Loop over each year
foreach y of numlist 2017/2019 {
  *Show the year
  display "`y'"
  local filename "`url'" + "`y'" + ".dta"
  display "`filename'"
}
*
**********
*Weights
**********

