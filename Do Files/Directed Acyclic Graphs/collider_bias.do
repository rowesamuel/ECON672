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
gen occupation = (1) + (2)*ability + (0)*female + (-2)*discrimination + rnormal() 
gen wage = (1) + (-1)*discrimination + (1)*occupation + 2*ability + rnormal() 

* Regressions
reg wage discrimination 
reg wage discrimination occupation 
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
