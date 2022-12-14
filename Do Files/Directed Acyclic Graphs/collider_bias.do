*Collider Bias
*Samuel Rowe - Copyright Scott Cunningham and Erin Hengel
*May 23, 2022

clear
set more off

*********************************
*Discrimination and Collider Bias
*********************************

set obs 10000 

* Half of the population is female. 
gen female = runiform()>=0.5 

* Innate ability is independent of gender. 
gen ability = rnormal() 

* All women experience discrimination. 
gen discrimination = female 

* Data generating processes
* We will hard code occupation to be a function of 
* ability, female, and discrimination
* We will hard code ability to be 2 on occupation
* We will hard code female to be 0 on occupation
* We will hard code discrimination to be -2 on occupation
gen occupation = (1) + (2)*ability + (0)*female + (-2)*discrimination + rnormal() 
* We hard code earnings to be a function of 
* discrimination, ability, and occupation
* We will hard code discrimination to be -1
* We will hard code occupation to be 1
* We will hard code ability to be 2
gen wage = (1) + (-1)*discrimination + (1)*occupation + 2*ability + rnormal() 


* Regressions

* In the first regression we have a large negative number.
* Since this is the combination of the direct effect of discrimination
* and the indirect effect through occupation.
reg wage discrimination 

* If we control for occupation like the Google study
* We get a positive value on discriminationWe know that discrimination should be -1 and not positive as we 
reg wage discrimination occupation 

* When we control for occupation and ability, the direct effect of 
* discrimination is seen
reg wage discrimination occupation ability


***********************************
*Sample selection and Collider Bias
***********************************

clear all 
set seed 3444 

* 2500 independent draws from standard normal distribution 
set obs 2500 
gen beauty=rnormal() 
gen talent=rnormal() 

* Creating the collider variable (star) 
gen score=(beauty+talent) 
egen c85=pctile(score), p(85)   
gen star=(score>=c85) 
label variable star "Movie star" 

* Conditioning on the top 15\% 
twoway (scatter beauty talent, mcolor(black) msize(small) msymbol(smx)), ///
 ytitle(Beauty) xtitle(Talent) subtitle(Aspiring actors and actresses) by(star, total)
