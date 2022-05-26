*Regression Review
*Samuel Rowe - Copyright Scott Cunningham
*May 26, 2022

clear 
set more off

************************
*Minimize Squared Errors
************************
set seed 1 
clear 
set obs 10000 
gen x = rnormal() 
gen u  = rnormal() 
gen y  = 5.5*x + 12*u 
reg y x 
predict yhat1 
gen yhat2 = -0.0750109  + 5.598296*x // Compare yhat1 and yhat2
sum yhat* 
predict uhat1, residual 
gen uhat2=y-yhat2 
sum uhat* 

*Graph bivariate regression from y on x
twoway (lfit y x, lcolor(black) lwidth(medium)) (scatter y x, mcolor(black) ///
msize(tiny) msymbol(point)), title(OLS Regression Line) 

*Distribution of Residuals around regression line
rvfplot, yline(0) 

************************
*OLS Residuals
************************
clear 
set seed 1234
set obs 10
gen x = 9*rnormal() 
gen u  = 36*rnormal() 
gen y  = 3 + 2*x + u
reg y x
predict yhat
predict residuals, residual
su residuals
list
collapse (sum) x u y yhat residuals
list

*************************
*Expected Value of OLS
*************************
clear all 
program define ols, rclass 
version 14.2 
syntax [, obs(integer 1) mu(real 0) sigma(real 1) ] 

	clear 
	drop _all 
	set obs 10000 
	gen x = 9*rnormal()  
	gen u  = 36*rnormal()  
	gen y  = 3 + 2*x + u 
	reg y x 
	end 

simulate beta=_b[x], reps(1000): ols 
su 
hist beta
