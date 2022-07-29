*Difference-in-Differences
*Samuel Rowe - Copyright Scott Cunningham
*July 5, 2022

clear 
set more off
**********************
*Estimate Diff-in-Diff
**********************
* DD estimate of 15-19 year olds in repeal states vs Roe states	
use https://github.com/scunning1975/mixtape/raw/master/abortion.dta, clear

*Difference-in-Difference estimator
reg lnr i.repeal##i.year i.fip acc ir pi alcohol crack poverty income ur if bf15==1 ///
[aweight=totpop], cluster(fip)

*Get Parameter Estimates for data frame for each year leading
parmest, label for(estimate min95 max95 %8.2f) li(parm label estimate min95 max95) ///
 saving(bf15_DD.dta, replace)
 
*Use the Parameter Estimates Data Frame
use ./bf15_DD.dta, replace

*Keep the Diff-in-Diff Interaction Parameter Estimates
keep in 36/50

*Generate year 
gen		year=.
replace year=1986 in 1
replace year=1987 in 2
replace year=1988 in 3
replace year=1989 in 4
replace year=1990 in 5
replace year=1991 in 6
replace year=1992 in 7
replace year=1993 in 8
replace year=1994 in 9
replace year=1995 in 10
replace year=1996 in 11
replace year=1997 in 12
replace year=1998 in 13
replace year=1999 in 14
replace year=2000 in 15

*You want to sort by year before using year as x-axis
sort year

*Graph Parameter Estimates with Confidence Intervals
twoway (scatter estimate year, mlabel(year) mlabsize(vsmall) msize(tiny)) ///
  (rcap min95 max95 year, msize(vsmall)), ytitle(Repeal x year estimated coefficient) ///
  yscale(titlegap(2)) yline(0, lwidth(thin) lcolor(black)) xtitle(Year) ///
  xline(1986 1987 1988 1989 1990 1991 1992, lwidth(vvvthick) ///
  lpattern(solid) lcolor(ltblue)) xscale(titlegap(2)) ///
  title(Estimated effect of abortion legalization on gonorrhea) ///
  subtitle(Black females 15-19 year-olds) ///
  note(W/o XI; Whisker plots are estimated coefficients of DD estimator from Column b of Table 2.) ///
  legend(off)

*************************************  
*Or with xi: interaction functionality
*************************************
use https://github.com/scunning1975/mixtape/raw/master/abortion.dta, clear

*Difference-in-Difference delta is i.repeal*i.year
xi: reg lnr i.repeal*i.year i.fip acc ir pi alcohol crack poverty income ur if bf15==1 ///
[aweight=totpop], cluster(fip)

*Install on first run
*ssc install parmest, replace
*If you have Stata 15 or older
*Run the following, Select Stata 11, and select parmest
net from "http://www.rogernewsonresources.org.uk/"

*Get the parameter estimates for graph	
parmest, label for(estimate min95 max95 %8.2f) li(parm label estimate min95 max95) ///
 saving(bf15_DD2.dta, replace)

*Use the data you just generated (see saving(bf15_DD.dta,replace))
use ./bf15_DD2.dta, replace

*Keep our estimate of Repeal*Year
keep in 17/31

*Generate year 
gen		year=1986 in 1
replace year=1987 in 2
replace year=1988 in 3
replace year=1989 in 4
replace year=1990 in 5
replace year=1991 in 6
replace year=1992 in 7
replace year=1993 in 8
replace year=1994 in 9
replace year=1995 in 10
replace year=1996 in 11
replace year=1997 in 12
replace year=1998 in 13
replace year=1999 in 14
replace year=2000 in 15

sort year

twoway (scatter estimate year, mlabel(year) mlabsize(vsmall) msize(tiny)) ///
  (rcap min95 max95 year, msize(vsmall)), ytitle(Repeal x year estimated coefficient) ///
  yscale(titlegap(2)) yline(0, lwidth(thin) lcolor(black)) xtitle(Year) ///
  xline(1986 1987 1988 1989 1990 1991 1992, lwidth(vvvthick) ///
  lpattern(solid) lcolor(ltblue)) xscale(titlegap(2)) ///
  title(Estimated effect of abortion legalization on gonorrhea) ///
  subtitle(Black females 15-19 year-olds) ///
  note(Whisker plots are estimated coefficients of DD estimator from Column b of Table 2.) ///
  legend(off)
  
****************
*Placebo Test
*Triple DDD
****************
clear
use https://github.com/scunning1975/mixtape/raw/master/abortion.dta, clear

* DDD estimate for 15-19 year olds vs. 20-24 year olds in repeal vs Roe states
gen yr=(repeal) & (younger==1)
*White Male
gen wm=(wht==1) & (male==1)
*White Female
gen wf=(wht==1) & (male==0)
*Black Male
gen bm=(wht==0) & (male==1)
*Black Female
gen bf=(wht==0) & (male==0)

*
char year[omit] 1985
char repeal[omit] 0
char younger[omit] 0
char fip[omit] 1
char fa[omit] 0
char yr[omit] 0 

*Without xi:
reg lnr i.repeal##i.year##i.younger i.fip##c.t acc pi ir alcohol crack  poverty income ur if bf==1 & (age==15 | age==25) ///
[aweight=totpop], cluster(fip)

*Triple Difference-in-Differences
* t time/year
* j older and younger groups
* s state groups
* Where i.fip*t are state-year fixed effects not in the Triple DiD
* DDD estimate for 15-19 year olds vs. 20-24 year olds in repeal vs Roe states
xi: reg lnr i.repeal*i.year i.younger*i.repeal i.younger*i.year i.yr*i.year ///
i.fip*t acc pi ir alcohol crack  poverty income ur if bf==1 & (age==15 | age==25) ///
[aweight=totpop], cluster(fip)

*Parameter Estimate into dataframe
parmest, label for(estimate min95 max95 %8.2f) li(parm label estimate min95 max95) saving(bf15_DDD.dta, replace)

*Get Parameter Estimate Dataframe
use ./bf15_DDD.dta, replace

*Keep Triple Difference-in-Differences Parameter Estimates only
keep in 82/96

gen		year=.
replace year=1986 in 1
replace year=1987 in 2
replace year=1988 in 3
replace year=1989 in 4
replace year=1990 in 5
replace year=1991 in 6
replace year=1992 in 7
replace year=1993 in 8
replace year=1994 in 9
replace year=1995 in 10
replace year=1996 in 11
replace year=1997 in 12
replace year=1998 in 13
replace year=1999 in 14
replace year=2000 in 15

sort year

*Graph the Triple Diff-in-Diff
twoway (scatter estimate year, mlabel(year) mlabsize(vsmall) msize(tiny)) ///
 (rcap min95 max95 year, msize(vsmall)), ///
 ytitle(Repeal x 20-24yo x year estimated coefficient) yscale(titlegap(2)) ///
 yline(0, lwidth(thin) lcolor(black)) xtitle(Year) ///
 xline(1986 1987 1988 1989 1990 1991 1992, lwidth(vvvthick) lpattern(solid) ///
 lcolor(ltblue)) xscale(titlegap(2)) ///
 title(Estimated effect of abortion legalization on gonorrhea) ///
 subtitle(Black females 15-19 year-olds) ///
 note(Whisker plots are estimated coefficients of DDD estimator from Column b of Table 2.) ///
 legend(off)

********************
*Group 20-24
********************
*Estimate the impact of 
use https://github.com/scunning1975/mixtape/raw/master/abortion.dta, clear

* Second DD model for 20-24 year old black females in repeal vs Roe states
char year[omit] 1985 
xi: reg lnr i.repeal*i.year i.fip acc ir pi alcohol crack poverty income ur ///
  if (race==2 & sex==2 & age==20) [aweight=totpop], cluster(fip) 

*OR

reg lnr i.repeal##i.year i.fip acc ir pi alcohol crack poverty income ur ///
  if (race==2 & sex==2 & age==20) [aweight=totpop], cluster(fip)

********************
*DDD 20-24 year olds
********************
use https://github.com/scunning1975/mixtape/raw/master/abortion.dta, clear

* Second DDD model for 20-24 year olds vs 25-29 year olds black females in repeal vs Roe states
gen younger2 = 0 
replace younger2 = 1 if age == 20

gen yr2=(repeal==1) & (younger2==1)

gen wm=(wht==1) & (male==1)
gen wf=(wht==1) & (male==0)
gen bm=(wht==0) & (male==1)
gen bf=(wht==0) & (male==0)
char year[omit] 1985 
char repeal[omit] 0 
char younger2[omit] 0 
char fip[omit] 1 
char fa[omit] 0 
char yr2[omit] 0 

*Triple DDD 
*Compare 20-24 to 25-29 year olds in repeal vs Roe states
xi: reg lnr i.repeal*i.year i.younger2*i.repeal i.younger2*i.year i.yr2*i.year ///
  i.fip*t acc pi ir alcohol crack  poverty income ur if bf==1 & (age==20 | age==25) ///
  [aweight=totpop], cluster(fip) 
  
*OR
reg lnr i.repeal##i.year##i.younger2 i.fip##c.t acc pi ir alcohol crack  poverty ///
 income ur if bf==1 & (age==20 | age==25) [aweight=totpop], cluster(fip) 
