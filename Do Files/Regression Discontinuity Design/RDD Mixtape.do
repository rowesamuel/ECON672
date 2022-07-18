*RDD Exercises
*Samuel Rowe - copyright Scott Cunningham and Marcelo Perraillon.
*June 6, 2022

clear
set more off

**************
*Simulate Smooth Continuity Assumption
**************
*You cannot directly test the continuity assumption, but we will simulate it
capture log close
set obs 1000
set seed 1234567

*Generate running variable. Stata code attributed to Marcelo Perraillon.
gen x = rnormal(50, 25)
replace x=0 if x < 0
drop if x > 100
sum x, det

*Set the cutoff at X=50. Treated if X > 50
gen D = 0
replace D = 1 if x > 50
gen y1 = 25 + 0*D + 1.5*x + rnormal(0, 20)

* Potential outcome Y1 not jumping at cutoff (continuity)
* Smooth continuous assumption
twoway (scatter y1 x if D==0, msize(vsmall) msymbol(circle_hollow)) ///
(scatter y1 x if D==1, sort mcolor(blue) msize(vsmall) msymbol(circle_hollow)) ///
 (lfit y1 x if D==0, lcolor(red) msize(small) lwidth(medthin) lpattern(solid)) ///
 (lfit y1 x, lcolor(dknavy) msize(small) lwidth(medthin) lpattern(solid)), ///
 xtitle(Test score (X)) xline(50) legend(off) xlabel(0 "0" 20 "20" 40 "40" ///
 50 "Cutoff" 60 "60" 80 "80" 100 "100") ///
 title("Smoothness of Potential Outcome (Y1)")

 ***************************
 *Simulate the Discontinuity
 ***************************
gen y = 25 + 40*D + 1.5*x + rnormal(0, 20)
scatter y x if D==0, msize(vsmall) || ///
scatter y x if D==1, msize(vsmall) ///
legend(off) xline(50, lstyle(foreground)) || ///
lfit y x if D ==0, color(red) || lfit y x if D ==1, ///
color(red)  title("Estimated LATE using simulated data") ///
ytitle("Outcome (Y)")  xtitle("Test Score (X)")  ///
xlabel(0 "0" 20 "20" 40 "40" ///
 50 "Cutoff" 60 "60" 80 "80" 100 "100")

****************************
*Nonlinear Data generation process
****************************
*What happens when we have nonlinear or polynomial-based
*functional form between y and x?
drop y y1 x* D
set obs 1000
gen x = rnormal(100, 50)
replace x=0 if x < 0
drop if x > 280
sum x, det

*Set the cutoff at X=140. Treated if X > 140
*There isn't a discontinuous jump at 140 but since 
*there is an incorrect functional form, it shows
*that there is a discontinous jump

*Set up a polynomial function form
gen D = 0
replace D = 1 if x > 140
gen x2 = x*x
gen x3 = x*x*x
gen y = 10000 + 0*D - 100*x +x2 + rnormal(0, 1000)
reg y D x

*Visualize the incorrect function form RDD
scatter y x if D==0, msize(vsmall) || scatter y x ///
  if D==1, msize(vsmall) legend(off) xline(140, ///
  lstyle(foreground)) ylabel(none) || lfit y x ///
  if D ==0, color(red) || lfit y x if D ==1, ///
  color(red) xtitle("Test Score (X)") ///
  ytitle("Outcome (Y)") title("Applying Linear Fit to Nonlinear Data") ///
  caption("Spurious discontinuity effect due to incorrect specification")

*Let's attempt Polynomial estimation
capture drop y 
gen y = 10000 + 0*D - 100*x +x2 + rnormal(0, 1000)
reg y D x x2 x3
predict yhat 

*Visual no discontinuous jump
scatter y x if D==0, msize(vsmall) || scatter y x ///
  if D==1, msize(vsmall) legend(off) xline(140, ///
  lstyle(foreground)) ylabel(none) || line yhat x ///
  if D ==0, color(red) sort || line yhat x if D==1, ///
  sort color(red) xtitle("Test Score (X)") ///
  ytitle("Outcome (Y)") title("Applying Nonlinaear Fit to Nonlinear Data") ///
  caption("Polynomial fit shows no discontinuity impact at cutoff")
  
*********************
*Higher-Order Polynominal Modeling
*********************
* Stata code attributed to Marcelo Perraillon.
capture drop y yhat
gen y = 10000 + 0*D - 100*x +x2 + rnormal(0, 1000)
*Interact Treatment with p-th order polynomial (p=3)
reg y D##c.(x x2 x3)
predict yhat
 
*Plot
scatter y x if D==0, msize(vsmall) || scatter y x ///
  if D==1, msize(vsmall) legend(off) xline(140, ///
  lstyle(foreground)) ylabel(none) || line yhat x ///
  if D ==0, color(red) sort || line yhat x if D==1, ///
  sort color(red) xtitle("Test Score (X)") ///
  ytitle("Outcome (Y)") 
