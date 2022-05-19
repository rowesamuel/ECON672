*Subclassification Exercise
*Samuel Rowe - Copyright Scott Cunningham
*May 19, 2022

clear
set more off

****************
*Calculate SDO
****************
use https://github.com/scunning1975/mixtape/raw/master/titanic.dta, clear
gen female=(sex==0)
label variable female "Female"
gen male=(sex==1)
label variable male "Male"
gen 	s=1 if (female==1 & age==1)
replace s=2 if (female==1 & age==0)
replace s=3 if (female==0 & age==1)
replace s=4 if (female==0 & age==0)
gen 	d=1 if class==1
replace d=0 if class!=1
summarize survived if d==1
gen ey1=r(mean)
summarize survived if d==0
gen ey0=r(mean)
gen sdo=ey1-ey0
sum sdo

******************
*Calculate ATE with Subclassification
******************
* Subclassification
capture noisely drop ey1 ey0
sum survived if s==1 & d==1
gen ey11=r(mean)
label variable ey11 "Average survival for male child in treatment"
sum survived if s==1 & d==0
gen ey10=r(mean)
label variable ey10 "Average survival for male child in control"
gen diff1=ey11-ey10
label variable diff1 "Difference in survival for male children"
sum survived if s==2 & d==1
gen ey21=r(mean)
sum survived if s==2 & d==0
gen ey20=r(mean)
gen diff2=ey21-ey20
sum survived if s==3 & d==1
gen ey31=r(mean)
sum survived if s==3 & d==0
gen ey30=r(mean)
gen diff3=ey31-ey30
sum survived if s==4 & d==1
gen ey41=r(mean)
sum survived if s==4 & d==0
gen ey40=r(mean)
gen diff4=ey41-ey40
count if s==1 & d==0
count if s==2 & d==0
count if s==3 & d==0
count if s==4 & d==0
count if d == 0

gen wt1=281/1876
gen wt2=44/1876
gen wt3=1492/1876
gen wt4=59/1876
gen wate=diff1*wt1 + diff2*wt2 + diff3*wt3 + diff4*wt4
sum wate sdo
