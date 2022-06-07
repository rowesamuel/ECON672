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
*Coding Guide
*https://julianreif.com/guide/
**********
*Very good tips about repliciability and organization
*Folder Structure

*├── analysis/
*    ├── data/
*    ├── processed/
*    ├── results/
*        ├── figures/
*        └── tables/
*    ├── scripts/
*        ├── 1_process_raw_data.do
*        └── 2_...
*    └── run.do
*└── paper/
*    ├── manuscript.tex
*    ├── figures/
*    └── tables/

*You be able to pick up a folder and move computers and have it run

*Automate Graphs and Figures
*Stata makes saving graphs easy, so if there is a minor fix all you need to
*do is rerun the scripts and have your graph fixed

*Stata also has estout and outreg2 to output tables and regression from Stata
*While it is easy to copy and paste tables, it is better to avoide this
*Using estout or outreg2 will help you in the long-run

*estout: 
*http://repec.sowi.unibe.ch/stata/estout/index.html
ssc install estout
*outreg2: 
*https://www.princeton.edu/~otorres/Outreg2.pdf
ssc install outreg2

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

*You can also use local macros to test regression models
*We'll demo this later, as well

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
*In the CSV files the weights need to be divided by 1000 
*Since the documentation says implies 4 decimals
*Composite weights are used for final BLS tabulations of labor force
gen cmpwgt2 = pwcmpwgt/10000
*Outgoing Rotation Weights are used for earnings only person in interviews 4 and 8
gen orwgt2 = pworwgt/10000
*PWSSWGT weights are used for general tabulations of sex, race, states, etc.
gen sswgt2 = pwsswgt/10000
*PWVETWGT are used to study the veteran population 
gen vetwgt2 = pwvetwgt/10000
*PWLWGT are weighted used to study someone over multiple CPS interviews
gen lgwgt2 = pwlgwgt/10000

*Usually we would need to divide by 12 for the Basic CPS to get annual weights
replace cmpwgt2 = cmpwgt2/12
*Get a composite weight for all of the CPS files
gen cmpwgt3 = pwcmpwgt/`filecount'

*Use the SvySet command to set up the survey design
svyset [pw=cmpwgt2]

*Use the svy: command vars to utilize the survey design
svy: tab employed hryear4, count cellwidth(20) format(%20.2gc)

***********
*Mincer Equation Example
***********
*Important Note
*Missing values are set to -1 in the CPS PUMS (public-use micro dataset)

*Recategorize Female
gen female = .
replace female = 0 if pesex == 1
replace female = 1 if pesex == 2
label define female1 0 "Male" 1 "Female"
label values female female1

*Generate Union
gen union = .
replace union = 0 if peernlab == 2
replace union = 1 if peernlab == 1
label define union1 0 "Nonunion" 1 "Union"
label values union union1

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

*You can use local macros for testing models
local rhs1 i.educ exp exp2
local rhs2 i.educ exp exp2 i.female
local rhs3 i.educ exp exp2 i.female i.union
local rhs4 i.educ exp exp2 i.female i.union i.hryear4 
local rhs5 i.educ exp exp2 i.female i.union i.hryear4 i.peio1icd
*Add interaction between female and union
local rhs6 i.educ exp exp2 i.female##i.union i.hryear4 i.peio1icd


*Run our regression
reg earnings `rhs1', robust
reg earnings `rhs2', robust
reg earnings `rhs3', robust
reg earnings `rhs4', robust
reg earnings `rhs5', robust
reg earnings `rhs6', robust

*Use esttab for formatted results
*http://repec.org/bocode/e/estout/esttab.html
local rhs4 i.educ exp exp2 i.female i.union i.hryear4 
local rhs5 i.educ exp exp2 i.female i.union i.hryear4 i.peio1icd
*Add interaction between female and union
local rhs6 i.educ exp exp2 i.female##i.union i.hryear4 i.peio1icd

est clear
*Use eststo to save a model
eststo reg1: reg earnings `rhs4'
eststo reg2: reg earnings `rhs5'
eststo reg3: reg earnings `rhs6'
*Output the results
esttab, title (Mincer Equation) r2 se noconstant star(* .10 ** .05 *** .01) ///
 b(%10.3f) drop (*peio1icd) wide label

