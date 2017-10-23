cd "/Users/Ankur/Dropbox/School/Duke/Duke/Spring 2017/Master's Project/DiD Analysis"
log using "Log file.log", replace


* Creating map of cluster locations *

* DHS 2009 and 2014 Locations
shp2dta using KEGE52FL.shp, database(2009geo) coordinates(2009coord) replace

use 2009geo.dta, replace
outsheet using 2009geo.csv, comma

use 2009coord.dta, replace
outsheet using 2009coord.csv, comma

shp2dta using KEGE71FL.shp, database(2014geo) coordinates(2014coord) replace

use 2014coord.dta, replace
outsheet using 2014coord.csv, comma



* Kenya sublocation data
shp2dta using kenya_sublocations.shp, database(Kenya_subloc) coordinates(Kenya_subloccoord) replace

use Kenya_subloc, replace
label variable _ID "Location ID"
tostring _ID, gen(LOCID)
gen Location_ID = "A000" + LOCID
drop _ID LOCID
save Kenya_subloc, replace

use Kenya_subloccoord, replace
label variable _ID "Location ID"
collapse _X _Y, by(_ID)
tostring _ID, gen(LOCID)
gen Location_ID = "A000" + LOCID
drop _ID LOCID
save Kenya_subloccoord, replace

clear all
use Kenya_subloc, replace
merge 1:1 Location_ID using Kenya_subloccoord
save Kenya_sublocation_matches, replace
outsheet using Kenya_sublocation_matches.csv, comma replace


* Picking a control group

* Making county-level dataset
use KEHR70FL.DTA, clear

collapse hv270 hv009, by(shcounty)
sort hv270
gen labels = "Nyeri" if shcounty == 42
replace labels = "Kirinyaga" if shcounty == 43
replace labels = "Nyandarua" if shcounty == 41


graph twoway scatter hv009 hv270, mlabel(labels) xtitle("Mean household wealth") ///
	ytitle("Mean household members") title("47 Counties of Kenya") mlabcolor(red)
save scatter.png, replace
* Choosing Nyandarua county for control group area, using scatter plot on hh wealth + # hh members [also in same county]; Nyandarua is also rural and ag-driven w/ similar labour and export makeup)

clear all



*********** Formatting five datasets (births, women, men, total, household); assigning treatment and control groups
set maxvar 10000

* Births
use KEBR52FL.DTA
sort v001
gen year = 0
gen treatment = 0 if inlist(v001, 24,53,60,103,104,140,158,191,192,232,238,264,325,342,343,396)
replace treatment = 1 if inlist(v001, 23,40,56,70,189,208,282,303,326,352,361,369,385,386,391)
codebook treatment
drop if treatment == .
save 2009_births_recode.dta, replace

use KEBR70FL.DTA, replace
sort v001
codebook v001
gen year = 1
gen treatment = 0 if inlist(v001, 57,58,59,60,61,65,68,70,71,74,75,79,80,81,82,83,84,85,87,88)
replace treatment = 1 if inlist(v001, 101,102,104,105,106,108,109,118,121,124,136,137,138,141,144,145,149,150,155)
codebook treatment
drop if treatment == .
save 2014_births_recode.dta, replace

use 2009_births_recode.dta, replace
append using 2014_births_recode.dta, gen(source)
codebook treatment if year == 0
codebook treatment if year == 1
label variable treatment "Treatment? 0=No / 1=Yes"
label define treat 0 "Control" 1 "Treatment"
label values treatment treat
order treatment, after(v000)
label variable year "0=Baseline / 1=Post-treatment"
order year, after(treatment)
save births.dta, replace


* Individual women
use KEIR52FL.DTA, replace
gen year = 0
gen treatment = 0 if inlist(v001, 24,53,60,103,104,140,158,191,192,232,238,264,325,342,343,396)
replace treatment = 1 if inlist(v001, 23,40,56,70,189,208,282,303,326,352,361,369,385,386,391)
codebook treatment
drop if treatment == .
save 2009_individualwomen_recode.dta, replace

use KEIR70FL.DTA, replace
gen year = 1
gen treatment = 0 if inlist(v001, 57,58,59,60,61,65,68,70,71,74,75,79,80,81,82,83,84,85,87,88)
replace treatment = 1 if inlist(v001, 101,102,104,105,106,108,109,118,121,124,136,137,138,141,144,145,149,150,155)
codebook treatment
drop if treatment == .
save 2014_individualwomen_recode.dta, replace

use 2009_individualwomen_recode.dta, replace
append using 2014_individualwomen_recode.dta, gen(source)
codebook treatment if year == 0
codebook treatment if year == 1
label variable treatment "Treatment? 0=No / 1=Yes"
label define treat 0 "Control" 1 "Treatment"
label values treatment treat
order treatment, after(v000)
label variable year "0=Baseline / 1=Post-treatment"
order year, after(treatment)
save women.dta, replace


* Men
use KEMR52FL.DTA, replace
gen year = 0
gen treatment = 0 if inlist(mv001, 24,53,60,103,104,140,158,191,192,232,238,264,325,342,343,396)
replace treatment = 1 if inlist(mv001, 23,40,56,70,189,208,282,303,326,352,361,369,385,386,391)
codebook treatment
drop if treatment == .
save 2009_men_recode.dta, replace

use KEMR70FL.DTA, replace
gen year = 1
gen treatment = 0 if inlist(mv001, 57,58,59,60,61,65,68,70,71,74,75,79,80,81,82,83,84,85,87,88)
replace treatment = 1 if inlist(mv001, 101,102,104,105,106,108,109,118,121,124,136,137,138,141,144,145,149,150,155)
codebook treatment
drop if treatment == .
save 2014_men_recode.dta, replace

use 2009_men_recode.dta, replace
append using 2014_men_recode.dta, gen(source)
codebook treatment if year == 0
codebook treatment if year == 1
label variable treatment "Treatment? 0=No / 1=Yes"
label define treat 0 "Control" 1 "Treatment"
label values treatment treat
order treatment, after(mv000)
label variable year "0=Baseline / 1=Post-treatment"
order year, after(treatment)
save men.dta, replace


* Total (men + women)
clear all
use men.dta, replace
gen male = 1
keep mcaseid mv000 treatment year mv001 mv002 mv003 mv004 mv005 mv006 mv007 ///
	mv008 mv307_05 mv481 mv781 birthcontrol mv012 mv107 mv136 mv152 mv155 ///
	mv191 mv201 mv714 married male
rename m* *	
rename (caseid arried ale) (mcaseid married male)
save men2.dta, replace
use women.dta, replace
gen male = 0
keep caseid v000 treatment year v001 v002 v003 v004 v005 v006 v007 ///
	v008 v307_05 v481 v781 birthcontrol v012 v107 v136 v152 v155 ///
	v191 v201 v714 married male
save women2.dta, replace
append using men2.dta, gen(source)
save total.dta, replace


* Household
use KEHR52FL.DTA, replace
gen year = 0
gen treatment = 0 if inlist(hv001, 24,53,60,103,104,140,158,191,192,232,238,264,325,342,343,396)
replace treatment = 1 if inlist(hv001, 23,40,56,70,189,208,282,303,326,352,361,369,385,386,391)
codebook treatment
drop if treatment == .
save 2009_HH_recode.dta, replace

use KEPR70FL.DTA, replace
gen year = 1
gen treatment = 0 if inlist(hv001, 57,58,59,60,61,65,68,70,71,74,75,79,80,81,82,83,84,85,87,88)
replace treatment = 1 if inlist(hv001, 101,102,104,105,106,108,109,118,121,124,136,137,138,141,144,145,149,150,155)
codebook treatment
drop if treatment == .
set seed 040717
gen rand = runiform() if treatment == 0
gen rand2 = runiform() if treatment == 1
sort treatment rand rand2
drop if treatment == 0 & rand > .237
drop if treatment == 1 & rand2 > .285
drop rand rand2
save 2014_HH_recode.dta, replace

use 2009_HH_recode.dta, replace
append using 2014_HH_recode.dta, gen(source)
codebook treatment if year == 0
codebook treatment if year == 1
label variable treatment "Treatment? 0=No / 1=Yes"
label define treat 0 "Control" 1 "Treatment"
label values treatment treat
order treatment, after(hv000)
label variable year "0=Baseline / 1=Post-treatment"
order year, after(treatment)
save household.dta, replace


********* Specifying outcome variables and covariates

* Men (LPM)
use men.dta, clear
/*
 Covariates:
 mv012	age (continuous)
 mv107	highest year of education (continuous; 0 - 8)
 mv136	number of household members (continuous)
 mv152	age of household head (continuous)
 mv155	literacy (categorical; 5 ordinal categories)
 mv191	wealth index factore score (5 decimals) (continuous scale)
 mv201	total children ever born (continuous)
 mv714	currently working (dichotomous)
married	dichotomous variable about whether respondent is married (created from mv501; current marital status)
 
 Outcome variables:
 mv307_05	condom method currently used (dichotomous)
 mv481	covered by health insurance (dichotomous)
 mv781	ever been tested for aids (dichotomous)
 birthcontrol	dichotomous variable about whether respondent is using some form of birth control (derived from mv312; 1 if condom used; 0 if not)
 
 Models:
 Men
 Women
 Poor
 Total
 
 
 */
 
 * Transforming covariates
codebook mv012 mv107 mv136 mv152 mv155 mv191 mv201 mv501 mv714 mv717
gen married = 0 if inlist(mv501, 0,2,3,4)
replace married = 1 if mv501 == 1
label variable married "Married? 0=No / 1=Yes"
label define mar 0 "Not married" 1 "Married"
label values married mar
codebook married
save men.dta, replace

* Transforming outcome variables
codebook mv307_05 mv312 mv481 mv781, tab(12)
gen birthcontrol = 0 if mv312 == 0
replace birthcontrol = 1 if inlist(mv312, 1,2,3,4,5,6,7,8,9,11)
label variable birthcontrol "On birth control? 0=No / 1=Yes"
label define bc 0 "Not on bc" 1 "On bc"
label values birthcontrol bc
codebook birthcontrol
save men.dta, replace



* Women (LPM)
use women.dta, clear
codebook treatment if year == 0
codebook treatment if year == 1

/*
Covariates:
v012	age (continuous)
v107	highest year of education (continuous; 0 - 8)
v136	number of household members (continuous)
v152	age of household head (continuous)
v155	literacy (categorical; 5 ordinal categories)
v191	wealth index factore score (5 decimals) (continuous scale)
v201	total children ever born (continuous)
v714	currently working (dichotomous)
married	dichotomous variable about whether respondent is married (created from v501; current marital status)

Outcome variables:
v307_05	condom method currently used (dichotomous)
v481	covered by health insurance (dichotomous)
v781	ever been tested for aids (dichotomous)
birthcontrol	dichotomous variable about whether respondent is using some form of birth control (derived from v312; 1 if pill/IUD/injection used; 0 if not)
*/

* Transforming covariates
codebook v012 v107 v136 v152 v155 v191 v201 v714, tab(12)
gen married = 0 if inlist(v501, 0,2,3,4)
replace married = 1 if v501 == 1
label variable married "Married? 0=No / 1=Yes"
label define mar 0 "Not married" 1 "Married"
label values married mar
codebook married
save women.dta, replace

* Transforming outcome variables
codebook v307_05 v481 v312 v781, tab(12)
gen birthcontrol = 0 if v312 == 0
replace birthcontrol = 1 if inlist(v312, 1,2,3,5,6,8,9,10,11,13,17)
label variable birthcontrol "On birth control? 0=No / 1=Yes"
label define bc 0 "Not on bc" 1 "On bc"
label values birthcontrol bc
codebook birthcontrol
save women.dta, replace



* Household (Expenditure)
use household.dta, replace
/*
Covariates:
hv220	age of head of HH (continuous)
education														// hv106_01 / hv106	highest year of education for head of HH (need to transform)
hv009	number of household members (continuous)
hv219	sex of head of household
hv014	total children under 5 (continuous)
hv227	have bednet for sleeping (binary)

Outcome variables:
lnasset -- ln(Turn hv206 hv207 hv208 hv209 hv210 hv211 hv212 hv243a hv243b hv243c hv243d into continuous variable 'assets')
lnwealth -- ln(hv270) 	wealth index ranking (1 - 5; continuous)
lnnets -- ln(hml1) - number of mosquito nets (continuous)

Models:
Total
Poor (hv270 bottom two quintiles)
Male (hv219)
Female
*/


drop if hv106_01 == 8
drop if hv106_01 == 9
gen education = hv106
replace education = hv106_01 if education == .
drop if education == .
label define educ 0 "No Education, preschool" 1 "Primary" 2 "Secondary" 3 "Higher"
label values education educ

egen asset =  rowtotal(hv206 hv207 hv208 hv209 hv210 hv211 hv212 hv243a hv243b hv243c hv243d)
drop if hv243b == 9

gen lnwealth = ln(hv271)
gen lnasset = ln(asset)
gen lnnets = ln(hml1)

gen poor = 1 if hv270 == 1
replace poor = 1 if hv270 == 2
replace poor = 0 if poor == .

gen male = 1 if hv219 == 1
replace male = 0 if male == .

save household.dta, replace


use births.dta, replace
* Births (maternal health outcomes)
/*
Covariates:
v012	mother's age (continuous)
v212	mother's age at 1st birth (continuous)
v107	highest year of education (continuous; 0 - 10)
v136	number of household members (continuous)
v191	wealth index factore score (5 decimals) (continuous scale)
v201	total children ever born (continuous)
v714	currently working (dichotomous)
v151	sex of household head (dichotomous)

Outcome variables:
contraceptive = transform v361 into dichotomous		currently using contraceptive (dichotomous)
v394 = visited health facility in the last 12 months (continuous) (many missing obs)
v437	mother's weight (continuous)
v481	covered by health insurance (dichotomous) (lots of missing variables)

Models:
Total mothers
Poor mothers
Non-poor mothers

*/
gen contraceptive = 1 if v361 == 1
replace contraceptive = 0 if contraceptive == .
label variable contraceptive "Currently using contraceptive. 1 = Yes / 0 = No"
save births.dta, replace


********* Linear Probability Model, Men                                                              										```````````````````````````````                                                                  
/*
How to interpret linear probability model (LPM):
"A coefficient is the change in the probability that Y = 1 for a one-unit change
of the independent variable of interest, holding everything else constant."
*/

use men.dta, replace

* Summary statistics
ttest mv307_05 if year == 0, by(treatment)
ttest mv481 if year == 0, by(treatment)
ttest mv781 if year == 0, by(treatment)
ttest birthcontrol if year == 0, by(treatment)

* Testing covariates
generate interact = treatment*year
nestreg: reg mv307_05 (treatment year interact) (mv012) (mv107) (mv136) (mv152) (mv155) (mv191) (mv201) (mv714) (married), robust
nestreg: reg mv781 (treatment year interact) (mv012) (mv107) (mv136) (mv152) (mv155) (mv191) (mv201) (mv714) (married), robust
nestreg: reg mv481 (treatment year interact) (mv012) (mv107) (mv136) (mv152) (mv155) (mv191) (mv201) (mv714) (married), robust
nestreg: reg birthcontrol (treatment year interact) (mv012) (mv107) (mv136) (mv152) (mv155) (mv191) (mv201) (mv714) (married), robust

quietly regress mv481 treatment##year mv012 mv107 mv136 mv152 mv155 mv191 mv201 mv714 married, robust
estat ic
estimates store Model1
quietly regress mv481 treatment##year mv012 mv107 mv191, robust
estat ic
estimates store Model2
quietly regress mv481 treatment##year mv012 mv107 mv155 mv191 mv714, robust
estat ic
estimates store Model3
quietly regress  mv481 treatment##year mv012 mv107 mv155 mv191 mv714 married, robust
estat ic
estimates store Model4
esttab Model1 Model2 Model3 Model4 using spec_LPM.csv, replace label b(%9.3f) se stats(N r2 r2_a aic bic)
* drop mv201 mv136 mv152 (they fail F-tests in nested hierarchical regression; AIC/BIC criterion in multiple models)


* Heteroskedacticity exists, so we use robust
quietly regress mv481 treatment##year mv012 mv107 mv155 mv191 mv714 married
rvfplot, title("Residual vs. Fitted Values Plot")
save HS_LPM.png, replace
estat hettest


* LPM DiD on whether respondent currently uses condoms in sexual intercourse (mv307_05)
regress mv307_05 treatment##year mv012 mv107 mv155 mv191 mv714 married, robust
estimates store m1, title("Condom method currently used")
* Not significant at p < .05

* LPM DiD on whether respondent has ever been tested for AIDS
regress mv781 treatment##year mv012 mv107 mv155 mv191 mv714 married, robust
estimates store m2, title("Ever been tested for AIDS")
* Not significant at p < .05

* LPM DiD on whether respondent has health insurance (mv481)
regress mv481 treatment##year mv012 mv107 mv155 mv191 mv714 married, robust
estimates store m3, title("Has health insurance")
/* Significant at p < .05
Interpretation: If you live in program area (within 5 km of CBHF), you have a 29.7% greater chance
of having health insurance
*/ 

* LPM DID on whether respondent uses some form of birth control
regress birthcontrol treatment##year mv012 mv107 mv155 mv191 mv714 married, robust
estimates store m4, title("On birth control")
/* Significant at p < .05
Interpretation: If you live in program area (within 5 km of CBHF), you have a 40.1% greater chance
of using some form of birth control
*/

esttab m1 m2 m3 m4 using DID_LPM_MEN.csv, replace cells(b(star fmt(3)) se(par fmt(2)))  ///
   legend label varlabels(_cons constant)


********* Linear Probability Model, Women
/*
How to interpret linear probability model (LPM):
"A coefficient is the change in the probability that Y = 1 for a one-unit change
of the independent variable of interest, holding everything else constant."
*/

use women.dta, replace

* Summary statistics
ttest v307_05 if year == 0, by(treatment)
ttest v481 if year == 0, by(treatment)
ttest v781 if year == 0, by(treatment)
ttest birthcontrol if year == 0, by(treatment)

* Testing covariates
regress v481 treatment##year v012 v107 v136 v152 v155 v191 v201 v714 married, robust
generate interact = treatment*year
nestreg: reg v481 (treatment year interact) (v012) (v107) (v136) (v152) (v155) (v191) (v201) (v714) (married), robust
* drop v136 v152 v155 married (they fail F-test in multiple models)

* LPM DiD on whether respondent currently uses condoms in sexual intercourse (v307_05)
regress v307_05 treatment##year v012 v107 v191 v201 v714, robust
estimates store m1, title("whether respondent currently uses condoms in sexual intercourse")
* Not significant

* LPM DiD on whether respondent has ever been tested for AIDS
regress v781 treatment##year v012 v107 v191 v201 v714, robust
estimates store m2, title("whether respondent has ever been tested for AIDS")
* Significant in the opposite from the intended effect

* LPM DiD on whether respondent has health insurance (v481)
regress v481 treatment##year v012 v107 v191 v201 v714, robust
estimates store m3, title("whether respondent has health insurance")
* Significant but suppressed; less of an effect than men but the effect is still there

* LPM DID on whether respondent uses some form of birth control
regress birthcontrol treatment##year v012 v107 v191 v201 v714, robust
estimates store m4, title("whether respondent uses some form of birth control")
* Significant; similar to men


esttab m1 m2 m3 m4 using DID_LPM_WOMEN.csv, replace cells(b(star fmt(3)) se(par fmt(2)))  ///
   legend label varlabels(_cons constant)


********* Linear Probability Model, Total

use total.dta, replace

=* Summary statistics
ttest v307_05 if year == 0, by(treatment)
ttest v481 if year == 0, by(treatment)
ttest v781 if year == 0, by(treatment)
ttest birthcontrol if year == 0, by(treatment)

* Testing covariates
regress v481 treatment##year male v012 v107 v136 v152 v155 v191 v201 v714 married, robust
generate interact = treatment*year
nestreg: reg v481 (treatment year interact) (v012) (v107) (v136) (v152) (v155) (v191) (v201) (v714) (married), robust
nestreg: reg v481 (treatment year interact) (male) (v136) (v152) (v155) (v201) (married), robust
* drop male, v152, v201, married  (fail F-test in multiple models)

* LPM DiD on whether respondent currently uses condoms in sexual intercourse (v307_05)
regress v307_05 treatment##year v012 v107 v136 v155 v191 v714, robust
estimates store m1
* Insignificant

* LPM DiD on whether respondent has ever been tested for AIDS
regress v781 treatment##year v012 v107 v136 v155 v191 v714, robust
estimates store m2
* insignificant

* LPM DiD on whether respondent has health insurance (v481)
regress v481 treatment##year v012 v107 v136 v155 v191 v714, robust
estimates store m3
* significant at p < .05

* LPM DID on whether respondent uses some form of birth control
regress birthcontrol treatment##year v012 v107 v136 v155 v191 v714, robust
estimates store m4
* significant at p < .05

esttab m1 m2 m3 m4 using DID_LPM_TOTAL.csv, replace cells(b(star fmt(3)) se(par fmt(2)))  ///
   legend label varlabels(_cons constant)


********* Linear Probability Model, Poor (bottom two quintiles in relative wealth)

use total.dta, replace
sort v191
egen p40 = pctile(v191), p(40)
codebook caseid if v191 <= 6566
drop if v191 > 6566
save poor.dta, replace
codebook treatment if year == 1
codebook treatment if year == 0

use poor.dta, replace

* Summary statistics
ttest v307_05 if year == 0, by(treatment)
ttest v481 if year == 0, by(treatment)
ttest v781 if year == 0, by(treatment)
ttest birthcontrol if year == 0, by(treatment)

* LPM DiD on whether respondent currently uses condoms in sexual intercourse (v307_05)
reg v307_05 treatment##year v012 v107 v152 v155 v191 married, robust
estimates store m1
* insignificant

* LPM DiD on whether respondent has ever been tested for AIDS
reg v781 treatment##year v012 v107 v152 v155 v191 married, robust
estimates store m2
* insignificant

* LPM DiD on whether respondent has health insurance (v481)
reg v481 treatment##year v012 v107 v152 v155 v191 married, robust
estimates store m3
* insigificant (unlike male, female, total)

* LPM DID on whether respondent uses some form of birth control
reg birthcontrol treatment##year v012 v107 v152 v155 v191 married, robust
estimates store m4
* sigificant at p < .05

esttab m1 m2 m3 m4 using DID_LPM_POOR.csv, replace cells(b(star fmt(3)) se(par fmt(2)))  ///
   legend label varlabels(_cons constant)

**************** Expenditure Model

* Combined male / female individual-level dataset
use men.dta, replace
gen male = 1
drop m304a_01 m304a_02 m304a_03 m304a_04 m304a_05 m304a_06 m304a_07 m304a_08 m304a_09 m304a_10 m304a_11 m304a_12 m304a_13 m304a_14 m304a_15 m304a_16 m304a_17 m304a_18 m304a_19 m304a_20
rename m* *	
rename (arried ale) (married male)
save men3.dta, replace
use women.dta, replace
gen male = 0
append using men3.dta
save totalexp.dta, replace


use household.dta, replace
* Testing covariates
regress lnwealth treatment##year education hv220 hv009 hv219 hv014 hv227 asset hml1
quietly regress lnwealth treatment##year education hv220 hv009 hv219 hv014 hv227 asset hml1
estat ic
estimates store Model1
quietly regress lnwealth treatment##year education hv220 hv009 hv014 hv227 asset hml1
estat ic
estimates store Model2
esttab Model1 Model2 using spec_expend.csv, label replace b(%9.3f) se stats(N r2 r2_a aic bic)
* keep education hv220 hv009 hv219 hv014 hv227 as covariates

* Heteroskedasticity?
quietly regress lnwealth treatment##year education hv220 hv009 hv219 hv014 hv227 asset hml1
rvfplot, title("Residuals vs. fitted values plot (Outcome variable: ln(wealth))") 
estat hettest	// yes
quietly regress lnasset treatment##year education hv220 hv009 hv219 hv014 hv227 hv271 hml1
rvfplot, title("Residuals vs. fitted values plot (Outcome variable: ln(assets))")
estat hettest	// yes
quietly regress lnnets treatment##year education hv220 hv009 hv219 hv014 hv227 hv271 asset
rvfplot, title("Residuals vs. fitted values plot (Outcome variable: ln(bed nets))")
estat hettest	// yes
* Use these heteroskedasticity visualizations to justify log transformations on three outcome variables
* Other two reasons: interpretation, theoretical (increases in predictor variables don't increase linearly)

**** Population: total ****

* Summary statistics
ttest hv271 if year == 0, by(treatment)
ttest asset if year == 0, by(treatment)
ttest hml1 if year == 0, by(treatment)

* DID on wealth index
regress lnwealth treatment##year education hv220 hv009 hv219 hv014 hv227, robust
estimates store m1
* log transformation is not significant

* DID on assets
regress asset treatment##year education hv220 hv009 hv219 hv014 hv227, robust
estimates store m2
* log transformation is not significant

* DID on number of mosquito nets
regress lnnets treatment##year education hv220 hv009 hv219 hv014 hv227, robust
estimates store m3
* Log transformation is significant at p < .05
* Log: Average treatment effect. People living in program area have 18.88% more mosquito nets

esttab m1 m2 m3 using DID_EXP_TOTAL.csv, replace cells(b(star fmt(3)) se(par fmt(2)))  ///
   legend label varlabels(_cons constant)
   

**** Population: poor ****

* Summary statistics
ttest hv271 if year == 0 & poor == 1, by(treatment)
ttest asset if year == 0 & poor == 1, by(treatment)
ttest hml1 if year == 0 & poor == 1, by(treatment)

* DID on wealth index
regress hv271 treatment##year education hv220 hv009 hv219 hv014 hv227 if poor == 1, robust
estimates store m1
* Can't use lnwealth, so I'm using continuous wealth variable hv271
* Not significant

* DID on assets
regress asset treatment##year education hv220 hv009 hv219 hv014 hv227 if poor == 1, robust
estimates store m2
* log transformation is not significant

* DID on number of mosquito nets
regress lnnets treatment##year education hv220 hv009 hv219 hv014 hv227 if poor == 1, robust
estimates store m3
* Log and linear not significant

esttab m1 m2 m3 using DID_EXP_POOR.csv, replace cells(b(star fmt(3)) se(par fmt(2)))  ///
   legend label varlabels(_cons constant)

**** Population: Male head of HH ****

* Summary statistics
ttest hv271 if year == 0 & male == 1, by(treatment)
ttest asset if year == 0 & male == 1, by(treatment)
ttest hml1 if year == 0 & male == 1, by(treatment)

* DID on wealth index
regress lnwealth treatment##year education hv220 hv009 hv014 hv227 if male == 1, robust
estimates store m1
* Not significant

* DID on assets
regress asset treatment##year education hv220 hv009 hv014 hv227 if male == 1, robust
estimates store m2
* Not significant

* DID on number of mosquito nets
regress lnnets treatment##year education hv220 hv009 hv014 hv227 if male == 1, robust

* Significant

esttab m1 m2 m3 using DID_EXP_MALE.csv, replace cells(b(star fmt(3)) se(par fmt(2)))  ///
   legend label varlabels(_cons constant)

**** Population: Female head of HH ****

* Summary statistics
ttest hv271 if year == 0 & male == 0, by(treatment)
ttest asset if year == 0 & male == 0, by(treatment)
ttest hml1 if year == 0 & male == 0, by(treatment)

* DID on wealth index
regress lnwealth treatment##year education hv220 hv009 hv014 hv227 if male == 0, robust
estimates store m1
* Not significant

* DID on assets
regress lnasset treatment##year education hv220 hv009 hv014 hv227 if male == 0, robust
estimates store m2
* Not significant

* DID on number of mosquito nets
regress lnnets treatment##year education hv220 hv009 hv014 hv227 if male == 0, robust
estimates store m3
* Not significant

esttab m1 m2 m3 using DID_EXP_FEMALE.csv, replace cells(b(star fmt(3)) se(par fmt(2)))  ///
   legend label varlabels(_cons constant)

**************** Maternal (births) Model
use births.dta, replace


* Testing covariates
regress contraceptive treatment##year v012 v212 v107 v136 v191 v201 v714 v151
regress v394 treatment##year v012 v212 v107 v136 v191 v201 v714 v151
regress v437 treatment##year v012 v212 v107 v136 v191 v201 v714 v151
regress v481 treatment##year v012 v212 v107 v136 v191 v201 v714 v151

quietly regress contraceptive treatment##year v012 v212 v107 v136 v191 v201 v714 v151
estat ic
estimates store Model1
quietly regress contraceptive treatment##year v212 v107 v191 v714 v151
estat ic
estimates store Model2
quietly regress contraceptive treatment##year v012 v212 v107 v191 v714 v151
estat ic
estimates store Model3
quietly regress contraceptive treatment##year v012 v212 v107 v136 v191 v714 v151
estat ic
estimates store Model4
esttab Model1 Model2 Model3 Model4 using spec_births.csv, label replace b(%9.3f) se stats(N r2 r2_a aic bic)
* keep v012 v212 v107 v136 v191 v201 v714 v151 as covariates; best fit according to AIC

* Heteroskedasticity?
quietly regress contraceptive treatment##year v012 v212 v107 v136 v191 v201 v714 v151
rvfplot, title("Residuals vs. fitted values plot" "(Outcome variable: Contraceptive use)")
estat hettest	// No
quietly regress v394 treatment##year v012 v212 v107 v136 v191 v201 v714 v151
rvfplot, title("Residuals vs. fitted values plot" "(Outcome variable: Visited health facility in last 12 months)")
estat hettest	// yes
quietly regress v437 treatment##year v012 v212 v107 v136 v191 v201 v714 v151
rvfplot, title("Residuals vs. fitted values plot" "(Outcome variable: Respondent's weight)")
estat hettest	// yes
quietly regress v481 treatment##year v012 v212 v107 v136 v191 v201 v714 v151
rvfplot, title("Residuals vs. fitted values plot" "(Outcome variable: Covered by health insurance)")
estat hettest	// yes

**** Population: Total ****
use births.dta, replace

* Summary statistics
ttest contraceptive if year == 0, by(treatment)
ttest v394 if year == 0, by(treatment)
ttest v437 if year == 0, by(treatment)
ttest v481 if year == 0, by(treatment)

* DID Model on contraceptive use (LPM)
regress contraceptive treatment##year v012 v212 v107 v136 v191 v201 v714 v151, robust
estimates store m1
* Significant. 18.5% higher probability of currently using contraceptives

* DID Model on visited health facility in last 12 months
regress v394 treatment##year v012 v212 v107 v136 v191 v201 v714 v151, robust
estimates store m2
* Not significant

* DID Model on mother's weight
regress v437 treatment##year v012 v212 v107 v136 v191 v201 v714 v151, robust
estimates store m3
* Not significant

* DID Model on whether covered by health insurance (LPM)
regress v481 treatment##year v012 v212 v107 v136 v191 v201 v714 v151, robust
estimates store m4
* Not significant

esttab m1 m2 m3 m4 using DID_BIRTHS_TOTAL.csv, replace cells(b(star fmt(3)) se(par fmt(2)))  ///
   legend label varlabels(_cons constant)

**** Population: Poor (bottom two quintiles) ****
use births.dta, replace
sort v191
egen p40 = pctile(v191), p(40)
gen poor = 1 if v191 <= -15919
replace poor = 0 if v191 > -15919
save births.dta, replace

* Summary statistics
ttest contraceptive if year == 0 & poor == 1, by(treatment)
ttest v394 if year == 0 & poor == 1, by(treatment)
ttest v437 if year == 0 & poor == 1, by(treatment)
ttest v481 if year == 0 & poor == 1, by(treatment)

* DID Model on contraceptive use (LPM)
regress contraceptive treatment##year v012 v212 v107 v136 v191 v201 v714 v151 if poor == 1, robust
estimates store m1
* Significant. 24.5% higher probability of currently using contraceptives

* DID Model on visited health facility in last 12 months (LPM)
regress v394 treatment##year v012 v212 v107 v136 v191 v201 v714 v151 if poor == 1, robust
estimates store m2
* Significant. 15.67% higher probability that visited health facility in last 12 months

* DID Model on mother's weight
regress v437 treatment##year v012 v212 v107 v136 v191 v201 v714 v151 if poor == 1, robust
estimates store m3
* Not significant

* DID Model on whether covered by health insurance (LPM)
regress v481 treatment##year v012 v212 v107 v136 v191 v201 v714 v151 if poor == 1, robust
estimates store m4
* Significant, but in the opposite direction (14.27% less likely)

esttab m1 m2 m3 m4 using DID_BIRTHS_POOR.csv, replace cells(b(star fmt(3)) se(par fmt(2)))  ///
   legend label varlabels(_cons constant)


**** Population: Non-poor (top three quintiles) ****
use births.dta, replace

* Summary statistics
ttest contraceptive if year == 0 & poor == 0, by(treatment)
ttest v394 if year == 0 & poor == 0, by(treatment)
ttest v437 if year == 0 & poor == 0, by(treatment)
ttest v481 if year == 0 & poor == 0, by(treatment)

* DID Model on contraceptive use (LPM)
regress contraceptive treatment##year v012 v212 v107 v136 v191 v201 v714 v151 if poor == 0, robust
estimates store m1
* Significant. 24.78% higher probability of currently using contraceptives

* DID Model on visited health facility in last 12 months (LPM)
regress v394 treatment##year v012 v212 v107 v136 v191 v201 v714 v151 if poor == 0, robust
estimates store m2
* Not significant

* DID Model on mother's weight
regress v437 treatment##year v012 v212 v107 v136 v191 v201 v714 v151 if poor == 0, robust
estimates store m3
* Not significant

* DID Model on whether covered by health insurance (LPM)
regress v481 treatment##year v012 v212 v107 v136 v191 v201 v714 v151 if poor == 0, robust
estimates store m4
* Not significant

esttab m1 m2 m3 m4 using DID_BIRTHS_NONPOOR.csv, replace cells(b(star fmt(3)) se(par fmt(2)))  ///
   legend label varlabels(_cons constant)



*********************** SENSITIVITY ANALYSIS

********* Creating cluster-level dataset with assigned treatment and year variables
* Men
use men.dta, clear
collapse (max) treatment year (mean) mv012 mv107 mv136 mv152 mv155 mv191 mv201 ///
	mv501 mv714 mv717 married mv307_05 mv312 mv481 mv781 birthcontrol, by(mv001)
label variable treatment "0=No / 1=Yes"
label variable year "0=Baseline / 1=Post-treatment"
label variable mv012 "age"
label variable mv107 "highest year of education (0-8)"
label variable mv136 "number of household members"
label variable mv152 "age of household head"
label variable mv155 "literacy; 0=No / 1=Yes"
label variable mv191 "wealth index factore score (5 decimals) (continuous scale)"
label variable mv201 "total children ever born"
label variable mv501 "current marital status (categorical"
label variable mv714 "currently working 0=No / 1=Yes"
label variable mv717 "respondent's occupation (categorical; 11 categories)"
label variable married "Currently married? 0=No / 1=Yes"
label variable mv307_05 "condom method currently used; 0=No / 1=Yes"
label variable mv312 "current contraceptive method (categorical)"
label variable mv481 "covered by health insurance; 0=No / 1=Yes"
label variable mv781 "ever been tested for aids; 0=No / 1=Yes"
label variable birthcontrol "On some form of birth control? 0=No / 1=Yes"
save men_collapsed.dta, replace


* Women
use women.dta, clear
collapse (max) treatment year (mean) v012 v107 v136 v152 v155 v191 v201 ///
	v501 v714 v717 married v307_05 v312 v481 v781 birthcontrol, by(v001)
label variable treatment "0=No / 1=Yes"
label variable year "0=Baseline / 1=Post-treatment"
label variable v012 "age"
label variable v107 "highest year of education (0-8)"
label variable v136 "number of household members"
label variable v152 "age of household head"
label variable v155 "literacy; 0=No / 1=Yes"
label variable v191 "wealth index factore score (5 decimals) (continuous scale)"
label variable v201 "total children ever born"
label variable v501 "current marital status (categorical"
label variable v714 "currently working 0=No / 1=Yes"
label variable v717 "respondent's occupation (categorical; 11 categories)"
label variable married "Currently married? 0=No / 1=Yes"
label variable v307_05 "condom method currently used; 0=No / 1=Yes"
label variable v312 "current contraceptive method (categorical)"
label variable v481 "covered by health insurance; 0=No / 1=Yes"
label variable v781 "ever been tested for aids; 0=No / 1=Yes"
label variable birthcontrol "On some form of birth control? 0=No / 1=Yes"
save women_collapsed.dta, replace

clear all


