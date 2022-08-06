*Synthetic Control
*Samuel Rowe edits - copyright Scott Cunningham
*August 2, 2022

clear
set more off

*make a folder called synth_example
pwd
*mkdir "synth_example"
cd "synth_example"

****************
* Estimation 1: Texas model of black male prisoners (per capita) 
****************
use https://github.com/scunning1975/mixtape/raw/master/texas.dta, clear
save texas.dta, replace

*Install Packages
ssc install synth 
ssc install mat2txt

*Pull Main data
use texas.dta, clear

**************
*Set the Panel
**************
*We need to establish the panel and check for any redundent values
sort statefip year
by statefip year: gen idcount = _N
tab idcount
*No redundent or repeated values
drop idcount
*Set Panel
xtset statefip year

************
*Synthetic Control
************

*We need to set the dependent variable bmprison and then we need to set predictor
*covariates.  We will used lagged values as seen in bmprison(1988), bmprison (1990),
*bmprison (1991), and bmprison (1992) 

*We need to specify the treatment unit with the option trunit
*Here Texas' fips code is 48, so set trunit(48)

*We need to specify T0 or the first year of the policy and we can set it with the
*trperiod(1993) option, which means the treatment begins in 1993

*We can use unitnames as state to use State Names instead of fips codes 
*unitnames(state) option

*We need to set the 

*We need to set the mspeperiod(numlist) a list of pre-intervention time periods 
*over which the mean squared prediction error (MSPE) should be minimized

*We can set resultsperiod(numlist) a list of time periods over which the results
*of synth should be obtained in the optional figure (see figure), the optional 
*results dataset (see keep), and the return matrices (see ereturn results))

*We can keep the synthetic control data with keep(<filename>) option
*NOTE: if you don't specify a folder within keep it will go into our current 
*directory and you can check your present working directory with pwd
pwd 

*We can display a figure with the figure option


synth 	bmprison bmprison(1988) bmprison(1990) bmprison(1991) bmprison(1992) ///
			alcohol(1990) aidscapita(1990) aidscapita(1991) ///
			income ur poverty black(1990) black(1991) black(1992) ///
			perc1519(1990), trunit(48) trperiod(1993) unitnames(state) ///
		mspeperiod(1985(1)1993) resultsperiod(1985(1)2000) ///
		keep(synth_bmprate.dta) replace fig

*Display the V matrix for weights of the predictive covariates
*V is the relative importance of our mth covariate.
*Remember that our construction of synthetic weights w(v) is a function of 
*our choices of predictive covariates 
mat list e(V_matrix)

*Save the graph 
graph save Graph synth_tx.gph, replace
		
*************
*Plot the Gap
*************
* Plot the gap between Y treatment and Y synthetic
* Pull our file generated with the keep option within synth
use synth_bmprate.dta, clear
* The first two columns are our donor pool and their weights
* We don't need these now so we can drop them
* The 3rd and 4th columns are our outcomes of interest: Y of Texas and 
* Y of Synthetic Texas
* The 5 column is our time period
keep _Y_treated _Y_synthetic _time
drop if _time==.
rename _time year
rename _Y_treated  treat
rename _Y_synthetic counterfact

*Generate the difference/gap
gen gap48=treat-counterfact
sort year
 
twoway (line gap48 year,lp(solid)lw(vthin)lcolor(black)), yline(0, lpattern(shortdash) lcolor(black)) ///
	xline(1993, lpattern(shortdash) lcolor(black)) xtitle("Year",si(medsmall)) xlabel(#10) ///
	ytitle("Gap in black male prisoners", size(medsmall)) legend(off)

save synth_bmprate_48.dta, replace


**************************
* Inference 1: placebo test for each donor state
**************************  
* We will now loop through each state to implement placebo tests for "fake state"
* placebos.  
use texas.dta, clear
*Set local macro with fips codes for the 39 states used
*We will want to include Texas as part of the donor pool for each placebo test
local statelist  1 2 4 5 6 8 9 10 11 12 13 15 16 17 18 20 21 22 23 24 25 26 27 28 ///
                 29 30 31 32 33 34 35 36 37 38 39 40 41 42 45 46 47 48 49 51 53 55 
*Loop through each state
foreach i of local statelist {
synth 	bmprison  ///
		bmprison(1990) bmprison(1992) bmprison(1991) bmprison(1988) ///
		alcohol(1990) aidscapita(1990) aidscapita(1991) /// 
		income ur poverty black(1990) black(1991) black(1992) ///  
		perc1519(1990), ///		 
			trunit(`i') trperiod(1993) unitnames(state) ///
			mspeperiod(1985(1)1993) resultsperiod(1985(1)2000) /// 
			keep(synth_bmprate_`i'.dta) replace
  /* check the V matrix */
  matrix state`i' = e(RMSPE)  
}
  foreach i of local statelist {
    matrix rownames state`i'=`i'
    matlist state`i', names(rows) 
}
*****************************
*Generate Gaps for each state
*****************************
* Note: Here begins a divergence between Mixtape and my work
* It is much easier to use a long format for the data instead of wide
* We will generate a gap between treat and control for each year
* and we will loop through each state and calculate a gap
local statelist  1 2 4 5 6 8 9 10 11 12 13 15 16 17 18 20 21 22 23 24 25 26 27 28 ///
                 29 30 31 32 33 34 35 36 37 38 39 40 41 42 45 46 47 48 49 51 53 55
 foreach i of local statelist {
 	use synth_bmprate_`i' ,clear
 	keep _Y_treated _Y_synthetic _time
 	drop if _time==.
	rename _time year
 	rename _Y_treated  treat
 	rename _Y_synthetic counterfact
 	gen gap=treat-counterfact
 	sort year 
	gen state = `i'
 	save synth_gap_bmprate`i', replace
}
*Append all placebos to main treatment effect into a tempfile
tempfile gap
save `gap', emptyok
clear

local statelist  1 2 4 5 6 8 9 10 11 12 13 15 16 17 18 20 21 22 23 24 25 26 27 28 ///
                 29 30 31 32 33 34 35 36 37 38 39 40 41 42 45 46 47 48 49 51 53 55
foreach i of local statelist {
	append using synth_gap_bmprate`i'
	save `gap', replace 
}
*Our placebo_pmprate.dta file will be in long format not wide format
*This will save us a lot of headache below
save placebo_bmprate.dta, replace
********************
* Inference 2: Exact p-values
********************
*  Estimate the pre-RMSPE and post-RMSPE and calculate the ratio of the 
*  post-RMSPE/pre-RMSPE	

sort state year
gen gap3 = gap*gap

by state: egen postmean=mean(gap3) if year>1993
by state: egen premean=mean(gap3) if year<=1993
gen rmspe=sqrt(premean) if year<=1993
replace rmspe=sqrt(postmean) if year>1993
gen ratio=rmspe/rmspe[_n-1] if 1994
gen rmspe_post=sqrt(postmean) if year>1993
gen rmspe_pre=rmspe[_n-1] if 1994

save synth_rmspe.dta, replace

keep if year == 1994

*Generate Rank and exact p-value
gsort -ratio
gen rank = _n
gen total = _N
gen p=rank/total
histogram ratio, bin(20) frequency fcolor(gs13) lcolor(black) ylabel(0(2)10) /// 
	xtitle(Post/pre RMSPE ratio) xlabel(0(1)20)
* Show the post/pre RMSPE ratio for all states, generate the histogram.
list rank p if state==48 // exact p-value for Texas is 0.04347

********************
*Inference 3: Plot all placebos
********************
use placebo_bmprate.dta, clear

*I really don't feel like programming line gap year if state==n for each state
*So we will utilize macros 
*Drop 1 and 55 from local
local statelist  1 2 4 5 6 8 9 10 11 12 13 15 16 17 18 20 21 22 23 24 25 26 27 28 ///
                 29 30 31 32 33 34 35 36 37 38 39 40 41 42 45 46 47 48 49 51 53 55

*We are going to loop through each state between 1 and 55 and append it
local graphappend " "
foreach s of local statelist {
  display "`s'"
  display "`graphappend'"
  *We want Texas (FIPS==48) to be a bit different, so we will use a if-else statement
  if `s' == 48 {
    local graph`s' " line gap year if state==`s',lp(solid) lw(thick) color(black) ||"
  }
  else {
    local graph`s' " line gap year if state==`s',lp(solid) lw(vthin) ||"
  }
  local graphappend = "`graphappend'" + "`graph`s''" 
}
*Let's add some options - turn off legend and add titles
local graphfinal = "`graphstate1'" + "`graphappend'" + "`graphstate55'" + ///
                   ",legend(off) ytitle(Gap in Black Male Prisoner Rate) xtitle(Year)" ///
				   + "xline(1993,lp(dash))"
display "`graphfinal'"

twoway `graphfinal'
graph save synth_placebo_bmprate.gph, replace

*Let's drop observations that were different from Texas in the pre-treatment period
* Drop the outliers (RMSPE is 5 times more than Texas: drops 11, 28, 32, 33, and 41)
* Picture of the full sample, including outlier RSMPE
use synth_rmspe.dta, clear
keep if year==1993
keep state rmspe_pre

sort state
gen ratio_check = rmspe_pre/rmspe_pre[42] //Texas is the 42 observation
sort ratio_check

*We see that DC and CA have 2 times the RMSPE in pre-treatment
*An issue is that CA has important weight

use placebo_bmprate.dta, clear

*I really don't feel like programming line gap year if state==n for each state
*So we will utilize macros 
*Drop 1 and 55 from local
local statelist  1 2 4 5 8 9 10 12 13 15 16 17 18 20 21 22 23 24 25 26 27 28 ///
                 29 30 31 32 33 34 35 36 37 38 39 40 41 42 45 46 47 48 49 51 53 55

*We are going to loop through each state between 1 and 55 and append it
local graphappend " "
foreach s of local statelist {
  display "`s'"
  display "`graphappend'"
  *We want Texas (FIPS==48) to be a bit different, so we will use a if-else statement
  if `s' == 48 {
    local graph`s' " line gap year if state==`s',lp(solid) lw(thick) color(black) ||"
  }
  else {
    local graph`s' " line gap year if state==`s',lp(solid) lw(vthin) ||"
  }
  local graphappend = "`graphappend'" + "`graph`s''" 
}
*Let's add some options - turn off legend and add titles
local graphfinal = "`graphstate1'" + "`graphappend'" + "`graphstate55'" + ///
                   ",legend(off) ytitle(Gap in Black Male Prisoner Rate) xtitle(Year)" ///
				   + "xline(1993,lp(dash))"
display "`graphfinal'"


