*RDD Example - Close Elections
*Samuel Rowe - Copyright Scott Cunningham
*June 12, 2022

clear
set more off

* Stata code attributed to Marcelo Perraillon.
use https://github.com/scunning1975/mixtape/raw/master/lmb-data.dta, clear

************************
*Replication of Results from Lee, Moretti, and Butler (2004)
************************
* Replicating Table 1 of Lee, Moretti and Butler (2004)
*Total Effect gamma
reg score lagdemocrat    if lagdemvoteshare>.48 & lagdemvoteshare<.52, cluster(id)
*Pi1
reg score democrat       if lagdemvoteshare>.48 & lagdemvoteshare<.52, cluster(id)
*PDt+1 - PRt+1
reg democrat lagdemocrat if lagdemvoteshare>.48 & lagdemvoteshare<.52, cluster(id)

*Pi1 is "elect"
*total effect gamma - (pi1 * (PDt+1 - PRt+1)) = Pi0 "affect"

*The gap at 0.5 comes from Pi1 or "elect" and not Pi0 or "affect"

*************************
*First we will step through the process of estimating a local regression
*We'll have just the treatment with no running variable
*We'll then add the recentered running variable and treatment
*We'll add an interaction between treatment and running variable
*We'll add a quadratic between treatment and running variable
*We'll then narrow the window around the cutoff by 5 points
*************************
*************************
*Start with an OLS with all data (global) and no running variable
*************************

*Using all of the data instead of just the window around the cutoff
*The window is 0.48 and 0.52 with a cutoff at 0.5, but here we look
*at all of the data 
*This is the full data set and not a window and linear
* Stata code attributed to Marcelo Perraillon.
reg score lagdemocrat, cluster(id)
reg score democrat, cluster(id)
reg democrat lagdemocrat, cluster(id)

**************************
*Add recentered running variable to OLS global
**************************
* Stata code attributed to Marcelo Perraillon.
*Recenter running variable of voteshare
gen demvoteshare_c = demvoteshare - 0.5
*Rerun regressions
reg score lagdemocrat demvoteshare_c, cluster(id)
reg score democrat demvoteshare_c, cluster(id)
reg democrat lagdemocrat demvoteshare_c, cluster(id)

**************************
*Interact Running variable and cutoff to OLS global
**************************
*Allow the intercepts and slopes to differ with interacting
*categorical and continuous variables
* Stata code attributed to Marcelo Perraillon.
*XI is interaction expansion: https://www.stata.com/manuals13/rxi.pdf
xi: reg score i.lagdemocrat*demvoteshare_c, cluster(id)
xi: reg score i.democrat*demvoteshare_c, cluster(id)
xi: reg democrat i.lagdemocrat*demvoteshare_c, cluster(id)

*You can use ## between to variables for interactions as well (I prefer this method)
*You use i.varname for the categorical and c.varname for the continuous
*So we are interacting a binary variable with a continuous one here to 
*allow for different slopes and intercepts
reg score i.lagdemocrat##c.demvoteshare_c, cluster(id)
reg score i.democrat##c.demvoteshare_c, cluster(id)
reg democrat i.lagdemocrat##c.demvoteshare_c, cluster(id)

**************************
*Add Quadratic Interaction to OLS global
**************************
* Stata code attributed to Marcelo Perraillon.
gen demvoteshare_sq = demvoteshare_c^2
xi: reg score lagdemocrat##c.(demvoteshare_c demvoteshare_sq), cluster(id)
xi: reg score democrat##c.(demvoteshare_c demvoteshare_sq), cluster(id)
xi: reg democrat lagdemocrat##c.(demvoteshare_c demvoteshare_sq), cluster(id)
*Same results without xi:
reg score i.lagdemocrat##c.(demvoteshare_c demvoteshare_sq), cluster(id)
reg score i.democrat##c.(demvoteshare_c demvoteshare_sq), cluster(id)
reg democrat i.lagdemocrat##c.(demvoteshare_c demvoteshare_sq), cluster(id)

*************************
*Use 5 points from cutoff in OLS
*************************
* Stata code attributed to Marcelo Perraillon.
xi: reg score lagdemocrat##c.(demvoteshare_c demvoteshare_sq) if lagdemvoteshare>.45 & lagdemvoteshare<.55, cluster(id)
xi: reg score democrat##c.(demvoteshare_c demvoteshare_sq) if lagdemvoteshare>.45 & lagdemvoteshare<.55, cluster(id)
xi: reg democrat lagdemocrat##c.(demvoteshare_c demvoteshare_sq) if lagdemvoteshare>.45 & lagdemvoteshare<.55, cluster(id)

reg score i.lagdemocrat##c.(demvoteshare_c demvoteshare_sq) if lagdemvoteshare>.45 & lagdemvoteshare<.55, cluster(id)
reg score i.democrat##c.(demvoteshare_c demvoteshare_sq) if lagdemvoteshare>.45 & lagdemvoteshare<.55, cluster(id)
reg democrat i.lagdemocrat##c.(demvoteshare_c demvoteshare_sq) if lagdemvoteshare>.45 & lagdemvoteshare<.55, cluster(id)

************************
*We'll now switch to local polynomial regressions as
*a way to assess the impact of treatment at the cutoff
*A nonparametric method in RDD is to estimate
*a model that doesn't assume a functional form for the
*relationship between the outcome and running variable
*Y=f(X)+e
*We'll calculate the E[Y] for each bin of the running 
*variable X
*Stata has cmogram to estimate nonparametric graphics
************************
*Install CMOGRAM
*This is possible with twoway, but cmogram makes it more concise to implement
ssc install cmogram //If this gives you an error, please comment it out and install cmogram manually
*Visualize Quadratic Fit
cmogram score lagdemvoteshare, cut(0.5) scatter line(0.5) qfitci
cmogram score lagdemvoteshare if lagdemvoteshare > 0.4 & lagdemvoteshare < 0.6, cut(0.5) scatter line(0.5) qfitci
*Visualize Linear Fit
cmogram score lagdemvoteshare, cut(0.5) scatter line(0.5) lfit
cmogram score lagdemvoteshare if lagdemvoteshare > 0.4 & lagdemvoteshare < 0.6, cut(0.5) scatter line(0.5) lfit
*Visualize Lowess Fit
cmogram score lagdemvoteshare, cut(0.5) scatter line(0.5) lowess

*Make sure to check the bins after cmogram has run in the output window
*A quadratic fit seem to mimic Lee, Moretti, and Butler (2004) the closest
*Linear Fit seem to be influenced by outliers far from the cutoff

*If there doesn't seem to be any trends in the running variable, 
*then polynomials will not help much.  It is good to visualize what
*potential trends in the running variable are - e.g. your eyes

*************************
*Kernel-weighted local polynomial regressions
*************************
* Stata code attributed to Marcelo Perraillon.
*Observations closer to the cutoff have greater weight
*You need to select the bandwidth window and it is sensitive to the 
*size of the bandwidth window
*We use a triangle kernel
capture drop sdem* x1 x0
lpoly score demvoteshare if democrat == 0, nograph kernel(triangle) gen(x0 sdem0) bwidth(0.1)}
lpoly score demvoteshare if democrat == 1, nograph kernel(triangle) gen(x1 sdem1)  bwidth(0.1)}
scatter sdem1 x1, color(red) msize(small) || scatter sdem0 x0, msize(small) color(red) ///
xline(0.5,lstyle(dot)) legend(off) xtitle("Democratic vote share") ytitle("ADA score")

*Estimate the local polynomial LATE
gen diff = sdem1 - sdem0
list sdem1 sdem0 diff in 1/1

************************
*RDRobust
************************
*There is a bias-variance tradeoff when selecting bandwidth size
*The smaller the bandwidth window, the lower the bias, but fewer observations
*which increases the variance.  The larger the window, the higher the bias, but
*more observations, which decreases the variance
*RDRobust optimizes the tradeoff by choosing the optimal bandwidth sizes
*Which may vary to the left or right of the cutoff.
*Use local polynomial point estimators with bias correction
*ssc install rdrobust

*Estimate the LATE with RDrobust
rdrobust score demvoteshare, c(0.5)

************************
*McCrary Density Test
************************
*Use local polynomial density estimations
*RDDensity
*LPDensity
* McCrary density test. Stata code attributed to Marcelo Perraillon.
net install rddensity, from(https://raw.githubusercontent.com/rdpackages/rddensity/master/stata) replace
net install lpdensity, from(https://raw.githubusercontent.com/nppackages/lpdensity/master/stata) replace
rddensity demvoteshare, c(0.5) plot

