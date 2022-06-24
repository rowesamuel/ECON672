*Subclassification Exercise
*Edited by Samuel Rowe - Copyright Scott Cunningham
*May 19, 2022

clear
set more off

****************
*Calculate SDO
****************
*In this first part we will calculate the Simple Difference in Means/Outcomes (SDO)

*Get the data
use https://github.com/scunning1975/mixtape/raw/master/titanic.dta, clear
*Generate Female Binary
gen female=(sex==0)
label variable female "Female"
*Generate Male Binary
gen male=(sex==1)
label variable male "Male"
*Generate Class binary - Treatment Variable
gen 	d=.
replace d=1 if class==1
replace d=0 if class!=1
label define d1 0 "Not First-Class" 1 "First-Class"
label values d d1

*Summary by class
*Calculate mean of outcome if 1st class and set it using r() function
*Use r() function to get mean after summarize command to store mean
summarize survived if d==1
gen ey1=r(mean)
*Calculate mean of outcome if Not 1st Class and set it using r() function
summarize survived if d==0
gen ey0=r(mean)
*Calculate the Simple Difference in Outcomes (SDO)
gen sdo=ey1-ey0
sum sdo
*The SDO says that the chance for survival is 35.4% for 1st class, but it is
*biased. We will turn to a subclassification to take care of age and sex to
*calculate a weighted average treatment effect



******************
*Calculate ATE with Subclassification
******************
* Subclassification
*If DAG is: D->Y and D<-F->Y and D<-C->Y
*Then we have two confounders: Female Status and Child Status
*There are several steps we need to take to calculate the ATE from subclassification
*Step 1: Stratify into four groups: 1) Young males, 2) Young Females, 
*3) Adult Males, and 4) Adult Females
*Step 2: Calculate the difference in survival probabilities for each group
*Step 3: Calculate the number of people in the non-first-class group and divide
*by the total number of non-first-class population.  These are our strata weights
*Step 4: Calculate the weighted average survival rate using strata weights

*Drop the E[Y|D=1] and E[Y|D=0]
capture noisely drop ey1 ey0
*******
*Step 1: Generate Strata
*******
*Generate Strata based on age and sex
gen 	s=.
replace s=1 if (female==1 & age==1)
replace s=2 if (female==1 & age==0)
replace s=3 if (female==0 & age==1)
replace s=4 if (female==0 & age==0)
label define s1 1 "Female Adult" 2 "Female Child" 3 "Male Adult" 4 "Male Child"
label values s s1
*******
*Step 2: Calculate difference in survival probabilities for each group
*******
*Strata 1
sum survived if s==1 & d==1
gen ey11=r(mean)
label variable ey11 "Average survival for female child in treatment"
sum survived if s==1 & d==0
gen ey10=r(mean)
label variable ey10 "Average survival for female child in control"
gen diff1=ey11-ey10
label variable diff1 "Difference in survival for female children"
*Strata 2
sum survived if s==2 & d==1
gen ey21=r(mean)
label variable ey21 "Average survival for female adult in treatment"
sum survived if s==2 & d==0
gen ey20=r(mean)
label variable ey20 "Average survial for female adult in control"
gen diff2=ey21-ey20
label variable diff2 "Difference in survival for female adults"
*Strata 3
sum survived if s==3 & d==1
gen ey31=r(mean)
label variable ey31 "Average survival for male child in treatment"
sum survived if s==3 & d==0
gen ey30=r(mean)
label variable ey30 "Average survival for male child in control"
gen diff3=ey31-ey30
label variable diff3 "Difference in survival for male child"
*Strata 4 - Male Adults
sum survived if s==4 & d==1
gen ey41=r(mean)
label variable ey41 "Average survival for male adult in treatment"
sum survived if s==4 & d==0
gen ey40=r(mean)
label variable ey40 "Average survival for male adult in control"
gen diff4=ey41-ey40
label variable diff4 "Difference in survival for male adult"
********
*Step 3: Count Observations
********
*Use r() function to get stored results from prior command
count if s==1 & d==0
local wt1 = r(N)
display `wt1'
count if s==2 & d==0
local wt2 = r(N)
display `wt2'
count if s==3 & d==0
local wt3 = r(N)
display `wt3'
count if s==4 & d==0
local wt4 = r(N)
display `wt4'
count if d == 0
local total = r(N)
display `total'

********
*Step 4: Calculate the weighted average survival rate using strata weights
********
*You should not manually code!!!
*Use local macros
gen wt1 = `wt1'/`total'
*gen wt1=281/1876
gen wt2 = `wt2'/`total'
*gen wt2=44/1876
gen wt3 = `wt3'/`total'
*gen wt3=1492/1876
gen wt4 = `wt4'/`total'
*gen wt4=59/1876
gen wate=diff1*wt1 + diff2*wt2 + diff3*wt3 + diff4*wt4

*Compare Weighted Average Treatment Effect with Simple Difference in Outcomes
sum wate sdo

*The SDO is biased upwards 
*The weighted ATE is 18.9% while the SDO is 35.3%
*If we estimate a LPM, our estimate of delta-hat is 22.3%
reg survived i.d i.female##i.age
