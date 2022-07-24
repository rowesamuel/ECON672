*Twoway Fixed Effects DD Estimator (TWFEDD)
*Samuel Rowe - copyright Scott Cunningham
*July 19, 2022

clear
set more off

********************************
*Replicate Cheng Hoesktra TWFEDD
********************************

use https://github.com/scunning1975/mixtape/raw/master/castle.dta, clear
set scheme cleanplots
*ssc install bacondecomp

* define global macros
global crime1 jhcitizen_c jhpolice_c murder homicide  robbery assault burglary larceny motor robbery_gun_r 
global demo blackm_15_24 whitem_15_24 blackm_25_44 whitem_25_44 //demographics
global lintrend trend_1-trend_51 //state linear trend
global region r20001-r20104  //region-quarter fixed effects
global exocrime l_larceny l_motor // exogenous crime rates
global spending l_exp_subsidy l_exp_pubwelfare
global xvar l_police unemployrt poverty l_income l_prisoner l_lagprisoner $demo $spending

*Replicate Cheng and Hoekstra (2013)
label variable post "Year of treatment"
xi: xtreg l_homicide i.year $region $xvar $lintrend post [aweight=popwt], ///
    fe vce(cluster sid)

********************************
*TWFEDD with pre-treatment lags
********************************
* Event study regression with the year of treatment (lag0) as the omitted category.
xi: xtreg l_homicide  i.year $region lead9 lead8 lead7 lead6 lead5 lead4 lead3 ///
    lead2 lead1 lag1-lag5 [aweight=popwt], fe vce(cluster sid)
	
********************************
*Plot the TWFEDD with coefplot
********************************
 Plot the coefficients using coefplot
* ssc install coefplot

coefplot, keep(lead9 lead8 lead7 lead6 lead5 lead4 lead3 lead2 lead1 ///
          lag1 lag2 lag3 lag4 lag5) xlabel(, angle(vertical)) ///
		  yline(0) xline(9.5) vertical msymbol(D) mfcolor(white) ///
		  ciopts(lwidth(*3) lcolor(*.6)) mlabel format(%9.3f) ///
		  mlabposition(12) mlabgap(*2) title(Log Murder Rate) 

********************************
*Plot the TWFEDD with twoway
********************************

********************************
*Bacon Decomposition
********************************
use https://github.com/scunning1975/mixtape/raw/master/castle.dta, clear
* ssc install bacondecomp

* define global macros
global crime1 jhcitizen_c jhpolice_c murder homicide  robbery assault burglary larceny motor robbery_gun_r 
global demo blackm_15_24 whitem_15_24 blackm_25_44 whitem_25_44 //demographics
global lintrend trend_1-trend_51 //state linear trend
global region r20001-r20104  //region-quarter fixed effects
global exocrime l_larceny l_motor // exogenous crime rates
global spending l_exp_subsidy l_exp_pubwelfare
global xvar l_police unemployrt poverty l_income l_prisoner l_lagprisoner $demo $spending
global law cdl  

* Bacon decomposition
*net install ddtiming, from(https://tgoldring.com/code/)
areg l_homicide post i.year, a(sid) robust
*See the 2-by-2 DD estimates with corresponding weights
ddtiming l_homicide post, i(sid) t(year)

********************************
*TWFEDD Borusyak et al (2021)
********************************
