cd "C:\Users\User\Desktop\Thesis"

* load the excel file downloaded from: https://www.slickcharts.com/sp500
import excel "SP.xlsx", sheet("Sheet1") firstrow clear //firstrow means variable names are pulled from the top row in excel; clear means delete data that was previously in memory
keep Symbol //keep the list of tickers
* export the list of tickers to be uploaded to WRDS to get the right list of firms
export delimited using "tic_list.txt", novarnames replace //novarnames means variable name should not be put at the top row; replace means overwrite the file if it already existed

* prepare fama french data; need the risk free rate
import delimited "F-F_Research_Data_Factors_daily.CSV", varnames(5) clear 
drop if rf == . //drops the last line of data with data comment
gen Date = date(v1,"YMD") //convert the date variable to correct STATA daily date variable; YMD means the variable is in YEARMONTHDAY format
format Date %td //change the display of the Date variable to time daily
drop v1
keep rf Date //keep only the date and risk free rate
replace rf = rf / 100 //to have it as decimal, consistent with other return variables
save ff, replace

* at this step, I went to WRDS and collected data from two sections
* 1) total assets, market value, and total equity come from Compustat database
* 2) daily stock prices are obtained from CCM (CRSP Compustat Merged database); Why? Because we have a list of tickers and hence we must get the data from CCM (normally stock prices are obtained directly from CRSP but CRSP identifier is PERMNO but we identify S&P firms by TICKER)

* prepare the compustat file for merging
use comp, clear
drop indfmt consol popsrc datafmt curcd costat //drop some redundant variables
rename fyear year //rename
save comp_edited, replace
// the data above is uniquely identified at gvkey year level, meaning that one line of data corresponds to one gvkey/year combination

* combine CRSP and Compustat data
use ccm, clear
drop cheqv trfd iid  //drop some redundant variables
generate year = year(datadate) //extract the year of the datadate variable- to be used for merging
rename GVKEY gvkey //make the gvkey variable name consistent in the two datasets
merge m:1 gvkey year using comp_edited, keep(match) nogen
//m:1 stands for many-to-one where many means that the data in memory (stock prices data) has multiple records at gvkey/year level while one means that in the using data (annual data on total assets and market value) there is only one line per gvkey/year observation
//keep(match) means keep only observations that have data in both files (master and using)
//nogen means do not generate the _merge variable which is always generated as part of the merging process

* merge in S&P return data
rename datadate Date //rename the variable to match its name in the SP500 dataset downloaded from WRDS
merge m:1 Date using SP500, keep(match) nogen

//account for stock splits for tesla and apple 
replace prccd = prccd/4 if (LPERMNO == 14593 & Date >= td(01nov2019) & Date <= td(28aug2020))
replace prccd = prccd/5 if (LPERMNO == 93436 & Date >= td(01nov2019) & Date <= td(28aug2020))

* calculate returns from prices
sort LPERMNO Date
bysort LPERMNO (Date): gen r = prccd / prccd[_n-1] - 1 //calculate returns using the formula from the web
drop prccd //drop the prices variable

* merge in risk free rate
merge m:1 Date using ff, keep(match) nogen
sort LPERMNO Date

* substract risk free rate from both stock return and s&p index to get excess return for both
replace r 		= r 		- rf
replace sprtrn 	= sprtrn 	- rf

save data_pre_AR, replace

* calculate abnormal returns
use data_pre_AR, clear

* CAPM
* excess ret = alpha + beta * market excess return
* example of CAPM regression estimated for 1 firm only (Microsoft) (for illustration purposes)
regress r sprtrn if LPERMNO == 10107 & Date < td(01nov2020) 
twoway (line r sprtrn Date) if LPERMNO == 10107 & Date < td(01nov2020), legend(order(1 "Microsoft" 2 "S&P500")) xtitle("")

* generate a variable that will tag the estimation window
* estimation window spans the period from 01nov2019 to 30oct2020 so it includes a year of stock returns. This also leaves about a month of break (gap) in between the estimation period and the first event date (Dec11th)
gen ew = Date < td(01nov2020)
gen r_ew = r if ew == 1 //generate another version of the return variable which is only available during the estimation window (to make sure that we only use estimation period data in the regression)

ssc install rangestat
rangestat (reg) r_ew sprtrn, interval(LPERMNO 0 0)
//rangestat command repeats the CAPM regression for each firm (as specified in the interval option) while regressions stock return on the S&P 500 index return* estimation window tag
drop reg_r2 reg_adj_r2 se_sprtrn se_cons //drop the redundant variables
drop if reg_nobs < 146 //drop cases where regression is estimated using periods shorter than 6 months (150 trading days)
codebook LPERMNO //this leaves me with 468 firms

gen r_pred = b_cons + b_sprtrn * sprtrn //generate a CAPM-based prediction of stock return
gen ar = r - r_pred if ew != 1 //finally, generate abnormal return as difference between actual stock return and CAPM-based prediction (note: generate the variable only for the testing period (after estimation window has ended))

keep gvkey LPERMNO Date cshoc sic tic at ceq ch mkvalt ew ar //keep the essential variables
drop if ew == 1 //drop data for the estimation window, i.e. keep only the data after it 

save AR, replace

*-------------------------------------------------------------------------------
*event time plot around Nov 20th
use AR, clear

* generate time variable equals zero at event data, -1, -2 etc before that, and 1, 2 etc after that
bys LPERMNO (Date): g n = _n
g temp_n_at_event = n if Date == td(20nov2020)
bys LPERMNO: egen n_at_event = min(temp_n_at_event)
g t = n - n_at_event
drop n n_at_event temp_n_at_event

collapse (mean) ar, by(t)
twoway (line ar t) if inrange(t,-7,7), ytitle(Mean Abnormal Return) yline(0) ylabel(-0.01(0.005)0.01, nogrid) xtitle(Time Around the Event) xlabel(#11) title(Mean Abnormal Returns from +/- 7 Days on November 20) graphregion(fcolor(white))
graph export graph1.png, as(png) replace

twoway (line ar t), ytitle(Mean Abnormal Return) yline(0) ylabel(-0.01(0.005)0.01, nogrid) xtitle(Time Around the Event) xlabel(#11) title(Mean Abnormal Returns from +/- 7 Days on November 20) graphregion(fcolor(white))


* event time plot around Nov 30th
use AR, clear

* generate time variable equals zero at event data, -1, -2 etc before that, and 1, 2 etc after that
bys LPERMNO (Date): g n = _n
g temp_n_at_event = n if Date == td(30nov2020)
bys LPERMNO: egen n_at_event = min(temp_n_at_event)
g t = n - n_at_event
drop n n_at_event temp_n_at_event

collapse (mean) ar, by(t)
twoway (line ar t)
twoway (line ar t) if inrange(t,-7,7), ytitle(Mean Abnormal Return) yline(0) ylabel(-0.01(0.005)0.01, nogrid) xtitle(Time Around the Event) xlabel(#11) title(Mean Abnormal Returns from +/- 7 Days on November 30) graphregion(fcolor(white))
graph export graph2.png, as(png) replace

* event time plot around both announcement dates
use AR, clear
collapse (mean) ar, by(Date)
twoway (line ar Date)
twoway (line ar Date) if inrange(Date,td(13nov2020),td(7dec2020)), ytitle(Mean Abnormal Return) yline(0) ylabel(-0.01(0.005)0.01, nogrid) xtitle(Time Around the Event) xlabel(#11, angle(45)) title(Mean Abnormal Returns Around the Event Date) graphregion(fcolor(white)) xline(22239 22249, lpattern(dash) lcolor(maroon)) text(0.01 22242 "Announcement 1") text(0.01 22252 "Announcement 2")
graph export graph3.png, as(png) replace

*-------------------------------------------------------------------------------
* Event Date: Nov 20
use AR, clear

* generate time variable equals zero at event data, -1, -2 etc before that, and 1, 2 etc after that
sort LPERMNO Date
browse LPERMNO Date 
bysort LPERMNO (Date): generate n = _n //generate n variable which simply counts observations for each firm separately (while data is sorted on Date)
generate temp_n_at_event = n if Date == td(20nov2020) //identify n value for which Date equals Nov 20th
bysort LPERMNO: egen n_at_event = min(temp_n_at_event) //make n_at_event available for all records of a firm instead of having it in a single line only
generate t = n - n_at_event //finaly, create time variable as difference between n and n_at_event
drop n n_at_event temp_n_at_event //drop redundant variables

generate period1 = inrange(t,0,0) //tag period1 which spans dates as in the parenthesis (0,0) so that we can cumulate returns over that period
generate period2 = inrange(t,-1,1)
generate period3 = inrange(t,-3,3)
generate period4 = inrange(t,-5,5)
generate period5 = inrange(t,-7, 7)

bysort LPERMNO: egen car1 = sum(ar) if period1 == 1
bysort LPERMNO: egen car2 = sum(ar) if period2 == 1
bysort LPERMNO: egen car3 = sum(ar) if period3 == 1
bysort LPERMNO: egen car4 = sum(ar) if period4 == 1
bysort LPERMNO: egen car5 = sum(ar) if period5 == 1


/* the loop below does the same summation of abrnomal returns as the code above does	
forvalues i = 1/5 {
	bysort LPERMNO: egen car`i' = sum(ar) if period`i' == 1
}
*/
keep LPERMNO cshoc sic at ceq ch mkvalt car* //keep the necessary variables
collapse (firstnm) cshoc sic at ceq ch mkvalt car*, by(LPERMNO)

label var car1 "CAR(0,0)"
label var car2 "CAR(-1,1)"
label var car3 "CAR(-3,3)"
label var car4 "CAR(-5,5)"
label var car5 "CAR(-7,7)"


ssc install asdoc
* run t-tests for all 5 CAR to test if they are significantly different than 0
* also use the asdoc command to export the results to a Word document
asdoc ttest car1 == 0, save(results/CAAR.doc) label replace
forv i = 2/5 {
	asdoc ttest car`i' == 0, save(results/CAAR.doc) label rowappend
}

* sic variable is currently a string and we need to have it as numeric
destring sic, replace


// ssc install ffind does not work // go to end of file


* use the ffind command to convert SIC codes to Fama French 12 industry classification (FF12 is more compact than SIC codes)
ffind sic, newvar(ff12) type(12)

* generate ln of total assets variable, make histograms of both
hist at, xtitle(Total Assets) graphregion(fcolor(white))
graph export at.png, as(png) replace
generate ln_at = ln(at)
label variable ln_at "Natural Logarithm of Total Assets"
hist ln_at, xtitle(Natural Logarithm of Total Assets) graphregion(fcolor(white))
graph export ln_at.png, as(png) replace

* use regression to regress CARs on the 12 industry dummies to analyze differences in CARs among industries
//eststo model1: regress car1 i.ff12
forvalues i = 1/5 {
	eststo model`i': regress car`i' ln_at i.ff12
}
* use the esttab command below to export the results to an rtf file 
esttab model* using results/regressions_dec11.rtf, replace label noomit nobase b(%4.3f) se(%3.2f) modelwidth(8)

*-------------------------------------------------------------------------------
* Nov 30
use AR, clear

bys LPERMNO (Date): g n = _n
g temp_n_at_event = n if Date == td(30nov2020)
bys LPERMNO: egen n_at_event = min(temp_n_at_event)
g t = n - n_at_event
drop n n_at_event temp_n_at_event

generate period1 = inrange(t,0,0)
generate period2 = inrange(t,-1,1)
generate period3 = inrange(t,-3,3)
generate period4 = inrange(t,-5,5)
generate period5 = inrange(t,-7,7)

forv i = 1/5 {
	bys LPERMNO: egen car`i' = sum(ar) if period`i' == 1
}

keep LPERMNO cshoc sic at ceq ch mkvalt car*
collapse (firstnm) cshoc sic at ceq ch mkvalt car*, by(LPERMNO)

label var car1 "CAR(0,0)"
label var car2 "CAR(-1,1)"
label var car3 "CAR(-3,3)"
label var car4 "CAR(-5,5)"
label var car5 "CAR(-7,7)"


ssc install asdoc
asdoc ttest car1 == 0, save(results/CAAR.doc) label append
forv i = 2/5 {
	asdoc ttest car`i' == 0, save(results/CAAR.doc) label rowappend
}
         
destring sic, replace
ffind sic, newvar(ff12) type(12)

* generate ln of total assets variable, make histograms of both
hist at, xtitle(Total Assets) graphregion(fcolor(white))
graph export at.png, as(png) replace
generate ln_at = ln(at)
label variable ln_at "Natural Logarithm of Total Assets"
hist ln_at, xtitle(Natural Logarithm of Total Assets) graphregion(fcolor(white))
graph export ln_at.png, as(png) replace

forvalues i = 1/5 {
	eststo model`i': regress car`i' ln_at i.ff12
}
esttab model* using results/regressions_dec18.rtf, replace label noomit nobase b(%4.3f) se(%3.2f) modelwidth(8)


asdoc sum mkvalt at ln_at, save(results/at.doc) label append
// no need for a correlation table
// correlate ff12 ln_at

//testing the assumptions of OLS
//no multicollinearity 

forvalues i = 1/5 {
	eststo model`i': regress car`i' ln_at i.ff12
	estat vif
}

//normality
ssc install jb


forvalues i = 1/12 {
	asdoc summarize mkvalt if (ff12 == `i'), detail, save(results/descriptives.doc) label rowappend
}
asdoc summarize mkvalt at ln_at, detail, save(results/descriptives.doc) label rowappend


//ffind install
capture program drop ffind

program define ffind
	version 9.2
	syntax varlist(min=1 max=1 numeric) [if] [in], newvar(string) type(numlist max=1 min=1)

	tempvar ftyp
	tokenize "`type'"
	local `ftyp'=`1'
	
	* Check if newvar is valid variable name
	capture confirm new variable `newvar'
	if _rc != 0 {
		di as error "Variable `newvar' is invalid"
		exit 111
		}

	* Check type
	if ~inlist(``ftyp'',5,10,12,17,30,38,48,49) {
		di as error "Type must be 5, 10, 12, 17, 30, 38, 48 or 49"
		exit 111
		}

	* Set industries

	tempvar ffind
	tokenize "`varlist'"
	local `ffind' "`1'"


	qui gen `newvar'=.
	label variable `newvar' "Fama-French industry code (``ftyp'' industries)"

	capture label drop `newvar'
	if ``ftyp''==5 {
		label define `newvar' 1 "Consumer Durables, NonDurables, Wholesale, Retail, and Some Services (Laundries, Repair Shops)" 2 "Manufacturing, Energy, and Utilities" 3 "Business Equipment, Telephone and Television Transmission" 4 "Healthcare, Medical Equipment, and Drugs" 5 "Other -- Mines, Constr, BldMt, Trans, Hotels, Bus Serv, Entertainment, Finance"
		label values `newvar' `newvar'

		qui replace `newvar'=1 if inrange(``ffind'',100,999) | inrange(``ffind'',2000,2399) | inrange(``ffind'',2700,2749) | inrange(``ffind'',2770,2799) | inrange(``ffind'',3100,3199) | inrange(``ffind'',3940,3989) | inrange(``ffind'',2500,2519) | inrange(``ffind'',2590,2599) | inrange(``ffind'',3630,3659) | inrange(``ffind'',3710,3711) | inrange(``ffind'',3714,3714) | inrange(``ffind'',3716,3716) | inrange(``ffind'',3750,3751) | inrange(``ffind'',3792,3792) | inrange(``ffind'',3900,3939) | inrange(``ffind'',3990,3999) | inrange(``ffind'',5000,5999) | inrange(``ffind'',7200,7299) | inrange(``ffind'',7600,7699)
		qui replace `newvar'=2 if inrange(``ffind'',2520,2589) | inrange(``ffind'',2600,2699) | inrange(``ffind'',2750,2769) | inrange(``ffind'',2800,2829) | inrange(``ffind'',2840,2899) | inrange(``ffind'',3000,3099) | inrange(``ffind'',3200,3569) | inrange(``ffind'',3580,3629) | inrange(``ffind'',3700,3709) | inrange(``ffind'',3712,3713) | inrange(``ffind'',3715,3715) | inrange(``ffind'',3717,3749) | inrange(``ffind'',3752,3791) | inrange(``ffind'',3793,3799) | inrange(``ffind'',3830,3839) | inrange(``ffind'',3860,3899) | inrange(``ffind'',1200,1399) | inrange(``ffind'',2900,2999) | inrange(``ffind'',4900,4949)
		qui replace `newvar'=3 if inrange(``ffind'',3570,3579) | inrange(``ffind'',3622,3622) | inrange(``ffind'',3660,3692) | inrange(``ffind'',3694,3699) | inrange(``ffind'',3810,3839) | inrange(``ffind'',7370,7372) | inrange(``ffind'',7373,7373) | inrange(``ffind'',7374,7374) | inrange(``ffind'',7375,7375) | inrange(``ffind'',7376,7376) | inrange(``ffind'',7377,7377) | inrange(``ffind'',7378,7378) | inrange(``ffind'',7379,7379) | inrange(``ffind'',7391,7391) | inrange(``ffind'',8730,8734) | inrange(``ffind'',4800,4899)
		qui replace `newvar'=4 if inrange(``ffind'',2830,2839) | inrange(``ffind'',3693,3693) | inrange(``ffind'',3840,3859) | inrange(``ffind'',8000,8099)
		qui replace `newvar'=5 if missing(`newvar') & ~missing(``ffind'')
		}
	else if ``ftyp''==10 {
		label define `newvar' 1 "Consumer NonDurables -- Food, Tobacco, Textiles, Apparel, Leather, Toys" 2 "Consumer Durables -- Cars, TV's, Furniture, Household Appliances" 3 "Manufacturing -- Machinery, Trucks, Planes, Chemicals, Off Furn, Paper, Com Printing" 4 "Oil, Gas, and Coal Extraction and Products" 5 "Business Equipment -- Computers, Software, and Electronic Equipment" 6 "Telephone and Television Transmission" 7 "Wholesale, Retail, and Some Services (Laundries, Repair Shops)" 8 "Healthcare, Medical Equipment, and Drugs" 9 "Utilities" 10 "Other -- Mines, Constr, BldMt, Trans, Hotels, Bus Serv, Entertainment, Finance"
		label values `newvar' `newvar'

		qui replace `newvar'=1 if inrange(``ffind'',100,999) | inrange(``ffind'',2000,2399) | inrange(``ffind'',2700,2749) | inrange(``ffind'',2770,2799) | inrange(``ffind'',3100,3199) | inrange(``ffind'',3940,3989)
		qui replace `newvar'=2 if inrange(``ffind'',2500,2519) | inrange(``ffind'',2590,2599) | inrange(``ffind'',3630,3659) | inrange(``ffind'',3710,3711) | inrange(``ffind'',3714,3714) | inrange(``ffind'',3716,3716) | inrange(``ffind'',3750,3751) | inrange(``ffind'',3792,3792) | inrange(``ffind'',3900,3939) | inrange(``ffind'',3990,3999)
		qui replace `newvar'=3 if inrange(``ffind'',2520,2589) | inrange(``ffind'',2600,2699) | inrange(``ffind'',2750,2769) | inrange(``ffind'',2800,2829) | inrange(``ffind'',2840,2899) | inrange(``ffind'',3000,3099) | inrange(``ffind'',3200,3569) | inrange(``ffind'',3580,3629) | inrange(``ffind'',3700,3709) | inrange(``ffind'',3712,3713) | inrange(``ffind'',3715,3715) | inrange(``ffind'',3717,3749) | inrange(``ffind'',3752,3791) | inrange(``ffind'',3793,3799) | inrange(``ffind'',3830,3839) | inrange(``ffind'',3860,3899)
		qui replace `newvar'=4 if inrange(``ffind'',1200,1399) | inrange(``ffind'',2900,2999)
		qui replace `newvar'=5 if inrange(``ffind'',3570,3579) | inrange(``ffind'',3622,3622) | inrange(``ffind'',3660,3692) | inrange(``ffind'',3694,3699) | inrange(``ffind'',3810,3839) | inrange(``ffind'',7370,7372) | inrange(``ffind'',7373,7373) | inrange(``ffind'',7374,7374) | inrange(``ffind'',7375,7375) | inrange(``ffind'',7376,7376) | inrange(``ffind'',7377,7377) | inrange(``ffind'',7378,7378) | inrange(``ffind'',7379,7379) | inrange(``ffind'',7391,7391) | inrange(``ffind'',8730,8734)
		qui replace `newvar'=6 if inrange(``ffind'',4800,4899)
		qui replace `newvar'=7 if inrange(``ffind'',5000,5999) | inrange(``ffind'',7200,7299) | inrange(``ffind'',7600,7699)
		qui replace `newvar'=8 if inrange(``ffind'',2830,2839) | inrange(``ffind'',3693,3693) | inrange(``ffind'',3840,3859) | inrange(``ffind'',8000,8099)
		qui replace `newvar'=9 if inrange(``ffind'',4900,4949)
		qui replace `newvar'=10 if missing(`newvar') & ~missing(``ffind'')
		}
	else if ``ftyp''==12 {
		label define `newvar' 1 "Consumer NonDurables -- Food, Tobacco, Textiles, Apparel, Leather, Toys" 2 "Consumer Durables -- Cars, TV's, Furniture, Household Appliances" 3 "Manufacturing -- Machinery, Trucks, Planes, Off Furn, Paper, Com Printing" 4 "Oil, Gas, and Coal Extraction and Products" 5 "Chemicals and Allied Products" 6 "Business Equipment -- Computers, Software, and Electronic Equipment" 7 "Telephone and Television Transmission" 8 "Utilities" 9 "Wholesale, Retail, and Some Services (Laundries, Repair Shops)" 10 "Healthcare, Medical Equipment, and Drugs" 11 "Finance" 12 "Other -- Mines, Constr, BldMt, Trans, Hotels, Bus Serv, Entertainment"
		label values `newvar' `newvar'

		qui replace `newvar'=1 if inrange(``ffind'',100,999) | inrange(``ffind'',2000,2399) | inrange(``ffind'',2700,2749) | inrange(``ffind'',2770,2799) | inrange(``ffind'',3100,3199) | inrange(``ffind'',3940,3989)
		qui replace `newvar'=2 if inrange(``ffind'',2500,2519) | inrange(``ffind'',2590,2599) | inrange(``ffind'',3630,3659) | inrange(``ffind'',3710,3711) | inrange(``ffind'',3714,3714) | inrange(``ffind'',3716,3716) | inrange(``ffind'',3750,3751) | inrange(``ffind'',3792,3792) | inrange(``ffind'',3900,3939) | inrange(``ffind'',3990,3999)
		qui replace `newvar'=3 if inrange(``ffind'',2520,2589) | inrange(``ffind'',2600,2699) | inrange(``ffind'',2750,2769) | inrange(``ffind'',3000,3099) | inrange(``ffind'',3200,3569) | inrange(``ffind'',3580,3629) | inrange(``ffind'',3700,3709) | inrange(``ffind'',3712,3713) | inrange(``ffind'',3715,3715) | inrange(``ffind'',3717,3749) | inrange(``ffind'',3752,3791) | inrange(``ffind'',3793,3799) | inrange(``ffind'',3830,3839) | inrange(``ffind'',3860,3899)
		qui replace `newvar'=4 if inrange(``ffind'',1200,1399) | inrange(``ffind'',2900,2999)
		qui replace `newvar'=5 if inrange(``ffind'',2800,2829) | inrange(``ffind'',2840,2899)
		qui replace `newvar'=6 if inrange(``ffind'',3570,3579) | inrange(``ffind'',3660,3692) | inrange(``ffind'',3694,3699) | inrange(``ffind'',3810,3829) | inrange(``ffind'',7370,7379)
		qui replace `newvar'=7 if inrange(``ffind'',4800,4899)
		qui replace `newvar'=8 if inrange(``ffind'',4900,4949)
		qui replace `newvar'=9 if inrange(``ffind'',5000,5999) | inrange(``ffind'',7200,7299) | inrange(``ffind'',7600,7699)
		qui replace `newvar'=10 if inrange(``ffind'',2830,2839) | inrange(``ffind'',3693,3693) | inrange(``ffind'',3840,3859) | inrange(``ffind'',8000,8099)
		qui replace `newvar'=11 if inrange(``ffind'',6000,6999)
		qui replace `newvar'=12 if missing(`newvar') & ~missing(``ffind'')
		}

	else if ``ftyp''==17 {
		label define `newvar' 1 "Food" 2 "Mining and Minerals" 3 "Oil and Petroleum Products" 4 "Textiles, Apparel & Footware" 5 "Consumer Durables" 6 "Chemicals" 7 "Drugs, Soap, Prfums, Tobacco" 8 "Construction and Construction Materials" 9 "Steel Works Etc" 10 "Fabricated Products" 11 "Machinery and Business Equipment" 12 "Automobiles" 13 "Transportation" 14 "Utilities" 15 "Retail Stores" 16 "Banks, Insurance Companies, and Other Financials" 17 "Other"
		label values `newvar' `newvar'

		qui replace `newvar'=1 if inrange(``ffind'',100,199) | inrange(``ffind'',200,299) | inrange(``ffind'',700,799) | inrange(``ffind'',900,999) | inrange(``ffind'',2000,2009) | inrange(``ffind'',2010,2019) | inrange(``ffind'',2020,2029) | inrange(``ffind'',2030,2039) | inrange(``ffind'',2040,2046) | inrange(``ffind'',2047,2047) | inrange(``ffind'',2048,2048) | inrange(``ffind'',2050,2059) | inrange(``ffind'',2060,2063) | inrange(``ffind'',2064,2068) | inrange(``ffind'',2070,2079) | inrange(``ffind'',2080,2080) | inrange(``ffind'',2082,2082) | inrange(``ffind'',2083,2083) | inrange(``ffind'',2084,2084) | inrange(``ffind'',2085,2085) | inrange(``ffind'',2086,2086) | inrange(``ffind'',2087,2087) | inrange(``ffind'',2090,2092) | inrange(``ffind'',2095,2095) | inrange(``ffind'',2096,2096) | inrange(``ffind'',2097,2097) | inrange(``ffind'',2098,2099) | inrange(``ffind'',5140,5149) | inrange(``ffind'',5150,5159) | inrange(``ffind'',5180,5182) | inrange(``ffind'',5191,5191)
		qui replace `newvar'=2 if inrange(``ffind'',1000,1009) | inrange(``ffind'',1010,1019) | inrange(``ffind'',1020,1029) | inrange(``ffind'',1030,1039) | inrange(``ffind'',1040,1049) | inrange(``ffind'',1060,1069) | inrange(``ffind'',1080,1089) | inrange(``ffind'',1090,1099) | inrange(``ffind'',1200,1299) | inrange(``ffind'',1400,1499) | inrange(``ffind'',5050,5052)
		qui replace `newvar'=3 if inrange(``ffind'',1300,1300) | inrange(``ffind'',1310,1319) | inrange(``ffind'',1320,1329) | inrange(``ffind'',1380,1380) | inrange(``ffind'',1381,1381) | inrange(``ffind'',1382,1382) | inrange(``ffind'',1389,1389) | inrange(``ffind'',2900,2912) | inrange(``ffind'',5170,5172)
		qui replace `newvar'=4 if inrange(``ffind'',2200,2269) | inrange(``ffind'',2270,2279) | inrange(``ffind'',2280,2284) | inrange(``ffind'',2290,2295) | inrange(``ffind'',2296,2296) | inrange(``ffind'',2297,2297) | inrange(``ffind'',2298,2298) | inrange(``ffind'',2299,2299) | inrange(``ffind'',2300,2390) | inrange(``ffind'',2391,2392) | inrange(``ffind'',2393,2395) | inrange(``ffind'',2396,2396) | inrange(``ffind'',2397,2399) | inrange(``ffind'',3020,3021) | inrange(``ffind'',3100,3111) | inrange(``ffind'',3130,3131) | inrange(``ffind'',3140,3149) | inrange(``ffind'',3150,3151) | inrange(``ffind'',3963,3965) | inrange(``ffind'',5130,5139)
		qui replace `newvar'=5 if inrange(``ffind'',2510,2519) | inrange(``ffind'',2590,2599) | inrange(``ffind'',3060,3069) | inrange(``ffind'',3070,3079) | inrange(``ffind'',3080,3089) | inrange(``ffind'',3090,3099) | inrange(``ffind'',3630,3639) | inrange(``ffind'',3650,3651) | inrange(``ffind'',3652,3652) | inrange(``ffind'',3860,3861) | inrange(``ffind'',3870,3873) | inrange(``ffind'',3910,3911) | inrange(``ffind'',3914,3914) | inrange(``ffind'',3915,3915) | inrange(``ffind'',3930,3931) | inrange(``ffind'',3940,3949) | inrange(``ffind'',3960,3962) | inrange(``ffind'',5020,5023) | inrange(``ffind'',5064,5064) | inrange(``ffind'',5094,5094) | inrange(``ffind'',5099,5099)
		qui replace `newvar'=6 if inrange(``ffind'',2800,2809) | inrange(``ffind'',2810,2819) | inrange(``ffind'',2820,2829) | inrange(``ffind'',2860,2869) | inrange(``ffind'',2870,2879) | inrange(``ffind'',2890,2899) | inrange(``ffind'',5160,5169)
		qui replace `newvar'=7 if inrange(``ffind'',2100,2199) | inrange(``ffind'',2830,2830) | inrange(``ffind'',2831,2831) | inrange(``ffind'',2833,2833) | inrange(``ffind'',2834,2834) | inrange(``ffind'',2840,2843) | inrange(``ffind'',2844,2844) | inrange(``ffind'',5120,5122) | inrange(``ffind'',5194,5194)
		qui replace `newvar'=8 if inrange(``ffind'',800,899) | inrange(``ffind'',1500,1511) | inrange(``ffind'',1520,1529) | inrange(``ffind'',1530,1539) | inrange(``ffind'',1540,1549) | inrange(``ffind'',1600,1699) | inrange(``ffind'',1700,1799) | inrange(``ffind'',2400,2439) | inrange(``ffind'',2440,2449) | inrange(``ffind'',2450,2459) | inrange(``ffind'',2490,2499) | inrange(``ffind'',2850,2859) | inrange(``ffind'',2950,2952) | inrange(``ffind'',3200,3200) | inrange(``ffind'',3210,3211) | inrange(``ffind'',3240,3241) | inrange(``ffind'',3250,3259) | inrange(``ffind'',3261,3261) | inrange(``ffind'',3264,3264) | inrange(``ffind'',3270,3275) | inrange(``ffind'',3280,3281) | inrange(``ffind'',3290,3293) | inrange(``ffind'',3420,3429) | inrange(``ffind'',3430,3433) | inrange(``ffind'',3440,3441) | inrange(``ffind'',3442,3442) | inrange(``ffind'',3446,3446) | inrange(``ffind'',3448,3448) | inrange(``ffind'',3449,3449) | inrange(``ffind'',3450,3451) | inrange(``ffind'',3452,3452) | inrange(``ffind'',5030,5039) | inrange(``ffind'',5070,5078) | inrange(``ffind'',5198,5198) | inrange(``ffind'',5210,5211) | inrange(``ffind'',5230,5231) | inrange(``ffind'',5250,5251)
		qui replace `newvar'=9 if inrange(``ffind'',3300,3300) | inrange(``ffind'',3310,3317) | inrange(``ffind'',3320,3325) | inrange(``ffind'',3330,3339) | inrange(``ffind'',3340,3341) | inrange(``ffind'',3350,3357) | inrange(``ffind'',3360,3369) | inrange(``ffind'',3390,3399)
		qui replace `newvar'=10 if inrange(``ffind'',3410,3412) | inrange(``ffind'',3443,3443) | inrange(``ffind'',3444,3444) | inrange(``ffind'',3460,3469) | inrange(``ffind'',3470,3479) | inrange(``ffind'',3480,3489) | inrange(``ffind'',3490,3499)
		qui replace `newvar'=11 if inrange(``ffind'',3510,3519) | inrange(``ffind'',3520,3529) | inrange(``ffind'',3530,3530) | inrange(``ffind'',3531,3531) | inrange(``ffind'',3532,3532) | inrange(``ffind'',3533,3533) | inrange(``ffind'',3534,3534) | inrange(``ffind'',3535,3535) | inrange(``ffind'',3536,3536) | inrange(``ffind'',3540,3549) | inrange(``ffind'',3550,3559) | inrange(``ffind'',3560,3569) | inrange(``ffind'',3570,3579) | inrange(``ffind'',3580,3580) | inrange(``ffind'',3581,3581) | inrange(``ffind'',3582,3582) | inrange(``ffind'',3585,3585) | inrange(``ffind'',3586,3586) | inrange(``ffind'',3589,3589) | inrange(``ffind'',3590,3599) | inrange(``ffind'',3600,3600) | inrange(``ffind'',3610,3613) | inrange(``ffind'',3620,3621) | inrange(``ffind'',3622,3622) | inrange(``ffind'',3623,3629) | inrange(``ffind'',3670,3679) | inrange(``ffind'',3680,3680) | inrange(``ffind'',3681,3681) | inrange(``ffind'',3682,3682) | inrange(``ffind'',3683,3683) | inrange(``ffind'',3684,3684) | inrange(``ffind'',3685,3685) | inrange(``ffind'',3686,3686) | inrange(``ffind'',3687,3687) | inrange(``ffind'',3688,3688) | inrange(``ffind'',3689,3689) | inrange(``ffind'',3690,3690) | inrange(``ffind'',3691,3692) | inrange(``ffind'',3693,3693) | inrange(``ffind'',3694,3694) | inrange(``ffind'',3695,3695) | inrange(``ffind'',3699,3699) | inrange(``ffind'',3810,3810) | inrange(``ffind'',3811,3811) | inrange(``ffind'',3812,3812) | inrange(``ffind'',3820,3820) | inrange(``ffind'',3821,3821) | inrange(``ffind'',3822,3822) | inrange(``ffind'',3823,3823) | inrange(``ffind'',3824,3824) | inrange(``ffind'',3825,3825) | inrange(``ffind'',3826,3826) | inrange(``ffind'',3827,3827) | inrange(``ffind'',3829,3829) | inrange(``ffind'',3830,3839) | inrange(``ffind'',3950,3955) | inrange(``ffind'',5060,5060) | inrange(``ffind'',5063,5063) | inrange(``ffind'',5065,5065) | inrange(``ffind'',5080,5080) | inrange(``ffind'',5081,5081)
		qui replace `newvar'=12 if inrange(``ffind'',3710,3710) | inrange(``ffind'',3711,3711) | inrange(``ffind'',3714,3714) | inrange(``ffind'',3716,3716) | inrange(``ffind'',3750,3751) | inrange(``ffind'',3792,3792) | inrange(``ffind'',5010,5015) | inrange(``ffind'',5510,5521) | inrange(``ffind'',5530,5531) | inrange(``ffind'',5560,5561) | inrange(``ffind'',5570,5571) | inrange(``ffind'',5590,5599)
		qui replace `newvar'=13 if inrange(``ffind'',3713,3713) | inrange(``ffind'',3715,3715) | inrange(``ffind'',3720,3720) | inrange(``ffind'',3721,3721) | inrange(``ffind'',3724,3724) | inrange(``ffind'',3725,3725) | inrange(``ffind'',3728,3728) | inrange(``ffind'',3730,3731) | inrange(``ffind'',3732,3732) | inrange(``ffind'',3740,3743) | inrange(``ffind'',3760,3769) | inrange(``ffind'',3790,3790) | inrange(``ffind'',3795,3795) | inrange(``ffind'',3799,3799) | inrange(``ffind'',4000,4013) | inrange(``ffind'',4100,4100) | inrange(``ffind'',4110,4119) | inrange(``ffind'',4120,4121) | inrange(``ffind'',4130,4131) | inrange(``ffind'',4140,4142) | inrange(``ffind'',4150,4151) | inrange(``ffind'',4170,4173) | inrange(``ffind'',4190,4199) | inrange(``ffind'',4200,4200) | inrange(``ffind'',4210,4219) | inrange(``ffind'',4220,4229) | inrange(``ffind'',4230,4231) | inrange(``ffind'',4400,4499) | inrange(``ffind'',4500,4599) | inrange(``ffind'',4600,4699) | inrange(``ffind'',4700,4700) | inrange(``ffind'',4710,4712) | inrange(``ffind'',4720,4729) | inrange(``ffind'',4730,4739) | inrange(``ffind'',4740,4742) | inrange(``ffind'',4780,4780) | inrange(``ffind'',4783,4783) | inrange(``ffind'',4785,4785) | inrange(``ffind'',4789,4789)
		qui replace `newvar'=14 if inrange(``ffind'',4900,4900) | inrange(``ffind'',4910,4911) | inrange(``ffind'',4920,4922) | inrange(``ffind'',4923,4923) | inrange(``ffind'',4924,4925) | inrange(``ffind'',4930,4931) | inrange(``ffind'',4932,4932) | inrange(``ffind'',4939,4939) | inrange(``ffind'',4940,4942)
		qui replace `newvar'=15 if inrange(``ffind'',5260,5261) | inrange(``ffind'',5270,5271) | inrange(``ffind'',5300,5300) | inrange(``ffind'',5310,5311) | inrange(``ffind'',5320,5320) | inrange(``ffind'',5330,5331) | inrange(``ffind'',5334,5334) | inrange(``ffind'',5390,5399) | inrange(``ffind'',5400,5400) | inrange(``ffind'',5410,5411) | inrange(``ffind'',5412,5412) | inrange(``ffind'',5420,5421) | inrange(``ffind'',5430,5431) | inrange(``ffind'',5440,5441) | inrange(``ffind'',5450,5451) | inrange(``ffind'',5460,5461) | inrange(``ffind'',5490,5499) | inrange(``ffind'',5540,5541) | inrange(``ffind'',5550,5551) | inrange(``ffind'',5600,5699) | inrange(``ffind'',5700,5700) | inrange(``ffind'',5710,5719) | inrange(``ffind'',5720,5722) | inrange(``ffind'',5730,5733) | inrange(``ffind'',5734,5734) | inrange(``ffind'',5735,5735) | inrange(``ffind'',5736,5736) | inrange(``ffind'',5750,5750) | inrange(``ffind'',5800,5813) | inrange(``ffind'',5890,5890) | inrange(``ffind'',5900,5900) | inrange(``ffind'',5910,5912) | inrange(``ffind'',5920,5921) | inrange(``ffind'',5930,5932) | inrange(``ffind'',5940,5940) | inrange(``ffind'',5941,5941) | inrange(``ffind'',5942,5942) | inrange(``ffind'',5943,5943) | inrange(``ffind'',5944,5944) | inrange(``ffind'',5945,5945) | inrange(``ffind'',5946,5946) | inrange(``ffind'',5947,5947) | inrange(``ffind'',5948,5948) | inrange(``ffind'',5949,5949) | inrange(``ffind'',5960,5963) | inrange(``ffind'',5980,5989) | inrange(``ffind'',5990,5990) | inrange(``ffind'',5992,5992) | inrange(``ffind'',5993,5993) | inrange(``ffind'',5994,5994) | inrange(``ffind'',5995,5995) | inrange(``ffind'',5999,5999)
		qui replace `newvar'=16 if inrange(``ffind'',6010,6019) | inrange(``ffind'',6020,6020) | inrange(``ffind'',6021,6021) | inrange(``ffind'',6022,6022) | inrange(``ffind'',6023,6023) | inrange(``ffind'',6025,6025) | inrange(``ffind'',6026,6026) | inrange(``ffind'',6028,6029) | inrange(``ffind'',6030,6036) | inrange(``ffind'',6040,6049) | inrange(``ffind'',6050,6059) | inrange(``ffind'',6060,6062) | inrange(``ffind'',6080,6082) | inrange(``ffind'',6090,6099) | inrange(``ffind'',6100,6100) | inrange(``ffind'',6110,6111) | inrange(``ffind'',6112,6112) | inrange(``ffind'',6120,6129) | inrange(``ffind'',6140,6149) | inrange(``ffind'',6150,6159) | inrange(``ffind'',6160,6163) | inrange(``ffind'',6172,6172) | inrange(``ffind'',6199,6199) | inrange(``ffind'',6200,6299) | inrange(``ffind'',6300,6300) | inrange(``ffind'',6310,6312) | inrange(``ffind'',6320,6324) | inrange(``ffind'',6330,6331) | inrange(``ffind'',6350,6351) | inrange(``ffind'',6360,6361) | inrange(``ffind'',6370,6371) | inrange(``ffind'',6390,6399) | inrange(``ffind'',6400,6411) | inrange(``ffind'',6500,6500) | inrange(``ffind'',6510,6510) | inrange(``ffind'',6512,6512) | inrange(``ffind'',6513,6513) | inrange(``ffind'',6514,6514) | inrange(``ffind'',6515,6515) | inrange(``ffind'',6517,6519) | inrange(``ffind'',6530,6531) | inrange(``ffind'',6532,6532) | inrange(``ffind'',6540,6541) | inrange(``ffind'',6550,6553) | inrange(``ffind'',6611,6611) | inrange(``ffind'',6700,6700) | inrange(``ffind'',6710,6719) | inrange(``ffind'',6720,6722) | inrange(``ffind'',6723,6723) | inrange(``ffind'',6724,6724) | inrange(``ffind'',6725,6725) | inrange(``ffind'',6726,6726) | inrange(``ffind'',6730,6733) | inrange(``ffind'',6790,6790) | inrange(``ffind'',6792,6792) | inrange(``ffind'',6794,6794) | inrange(``ffind'',6795,6795) | inrange(``ffind'',6798,6798) | inrange(``ffind'',6799,6799)
		qui replace `newvar'=17 if missing(`newvar') & ~missing(``ffind'')

		}

	else if ``ftyp''==30 {
		label define `newvar' 1 "Food Products" 2 "Beer & Liquor" 3 "Tobacco Products" 4 "Recreation" 5 "Printing and Publishing" 6 "Consumer Goods" 7 "Apparel" 8 "Healthcare, Medical Equipment, Pharmaceutical Products" 9 "Chemicals" 10 "Textiles" 11 "Construction and Construction Materials" 12 "Steel Works Etc" 13 "Fabricated Products and Machinery" 14 "Electrical Equipment" 15 "Automobiles and Trucks" 16 "Aircraft, ships, and railroad equipment" 17 "Precious Metals, Non-Metallic, and Industrial Metal Mining" 18 "Coal" 19 "Petroleum and Natural Gas" 20 "Utilities" 21 "Communication" 22 "Personal and Business Services" 23 "Business Equipment" 24 "Business Supplies and Shipping Containers" 25 "Transportation" 26 "Wholesale" 27 "Retail" 28 "Restaurants, Hotels, Motels" 29 "Banking, Insurance, Real Estate, Trading" 30 "Everything Else"
		label values `newvar' `newvar'

		qui replace `newvar'=1 if inrange(``ffind'',100,199) | inrange(``ffind'',200,299) | inrange(``ffind'',700,799) | inrange(``ffind'',910,919) | inrange(``ffind'',2000,2009) | inrange(``ffind'',2010,2019) | inrange(``ffind'',2020,2029) | inrange(``ffind'',2030,2039) | inrange(``ffind'',2040,2046) | inrange(``ffind'',2048,2048) | inrange(``ffind'',2050,2059) | inrange(``ffind'',2060,2063) | inrange(``ffind'',2064,2068) | inrange(``ffind'',2070,2079) | inrange(``ffind'',2086,2086) | inrange(``ffind'',2087,2087) | inrange(``ffind'',2090,2092) | inrange(``ffind'',2095,2095) | inrange(``ffind'',2096,2096) | inrange(``ffind'',2097,2097) | inrange(``ffind'',2098,2099)
		qui replace `newvar'=2 if inrange(``ffind'',2080,2080) | inrange(``ffind'',2082,2082) | inrange(``ffind'',2083,2083) | inrange(``ffind'',2084,2084) | inrange(``ffind'',2085,2085)
		qui replace `newvar'=3 if inrange(``ffind'',2100,2199)
		qui replace `newvar'=4 if inrange(``ffind'',920,999) | inrange(``ffind'',3650,3651) | inrange(``ffind'',3652,3652) | inrange(``ffind'',3732,3732) | inrange(``ffind'',3930,3931) | inrange(``ffind'',3940,3949) | inrange(``ffind'',7800,7829) | inrange(``ffind'',7830,7833) | inrange(``ffind'',7840,7841) | inrange(``ffind'',7900,7900) | inrange(``ffind'',7910,7911) | inrange(``ffind'',7920,7929) | inrange(``ffind'',7930,7933) | inrange(``ffind'',7940,7949) | inrange(``ffind'',7980,7980) | inrange(``ffind'',7990,7999)
		qui replace `newvar'=5 if inrange(``ffind'',2700,2709) | inrange(``ffind'',2710,2719) | inrange(``ffind'',2720,2729) | inrange(``ffind'',2730,2739) | inrange(``ffind'',2740,2749) | inrange(``ffind'',2750,2759) | inrange(``ffind'',2770,2771) | inrange(``ffind'',2780,2789) | inrange(``ffind'',2790,2799) | inrange(``ffind'',3993,3993)
		qui replace `newvar'=6 if inrange(``ffind'',2047,2047) | inrange(``ffind'',2391,2392) | inrange(``ffind'',2510,2519) | inrange(``ffind'',2590,2599) | inrange(``ffind'',2840,2843) | inrange(``ffind'',2844,2844) | inrange(``ffind'',3160,3161) | inrange(``ffind'',3170,3171) | inrange(``ffind'',3172,3172) | inrange(``ffind'',3190,3199) | inrange(``ffind'',3229,3229) | inrange(``ffind'',3260,3260) | inrange(``ffind'',3262,3263) | inrange(``ffind'',3269,3269) | inrange(``ffind'',3230,3231) | inrange(``ffind'',3630,3639) | inrange(``ffind'',3750,3751) | inrange(``ffind'',3800,3800) | inrange(``ffind'',3860,3861) | inrange(``ffind'',3870,3873) | inrange(``ffind'',3910,3911) | inrange(``ffind'',3914,3914) | inrange(``ffind'',3915,3915) | inrange(``ffind'',3960,3962) | inrange(``ffind'',3991,3991) | inrange(``ffind'',3995,3995)
		qui replace `newvar'=7 if inrange(``ffind'',2300,2390) | inrange(``ffind'',3020,3021) | inrange(``ffind'',3100,3111) | inrange(``ffind'',3130,3131) | inrange(``ffind'',3140,3149) | inrange(``ffind'',3150,3151) | inrange(``ffind'',3963,3965)
		qui replace `newvar'=8 if inrange(``ffind'',2830,2830) | inrange(``ffind'',2831,2831) | inrange(``ffind'',2833,2833) | inrange(``ffind'',2834,2834) | inrange(``ffind'',2835,2835) | inrange(``ffind'',2836,2836) | inrange(``ffind'',3693,3693) | inrange(``ffind'',3840,3849) | inrange(``ffind'',3850,3851) | inrange(``ffind'',8000,8099)
		qui replace `newvar'=9 if inrange(``ffind'',2800,2809) | inrange(``ffind'',2810,2819) | inrange(``ffind'',2820,2829) | inrange(``ffind'',2850,2859) | inrange(``ffind'',2860,2869) | inrange(``ffind'',2870,2879) | inrange(``ffind'',2890,2899)
		qui replace `newvar'=10 if inrange(``ffind'',2200,2269) | inrange(``ffind'',2270,2279) | inrange(``ffind'',2280,2284) | inrange(``ffind'',2290,2295) | inrange(``ffind'',2297,2297) | inrange(``ffind'',2298,2298) | inrange(``ffind'',2299,2299) | inrange(``ffind'',2393,2395) | inrange(``ffind'',2397,2399)
		qui replace `newvar'=11 if inrange(``ffind'',800,899) | inrange(``ffind'',1500,1511) | inrange(``ffind'',1520,1529) | inrange(``ffind'',1530,1539) | inrange(``ffind'',1540,1549) | inrange(``ffind'',1600,1699) | inrange(``ffind'',1700,1799) | inrange(``ffind'',2400,2439) | inrange(``ffind'',2450,2459) | inrange(``ffind'',2490,2499) | inrange(``ffind'',2660,2661) | inrange(``ffind'',2950,2952) | inrange(``ffind'',3200,3200) | inrange(``ffind'',3210,3211) | inrange(``ffind'',3240,3241) | inrange(``ffind'',3250,3259) | inrange(``ffind'',3261,3261) | inrange(``ffind'',3264,3264) | inrange(``ffind'',3270,3275) | inrange(``ffind'',3280,3281) | inrange(``ffind'',3290,3293) | inrange(``ffind'',3295,3299) | inrange(``ffind'',3420,3429) | inrange(``ffind'',3430,3433) | inrange(``ffind'',3440,3441) | inrange(``ffind'',3442,3442) | inrange(``ffind'',3446,3446) | inrange(``ffind'',3448,3448) | inrange(``ffind'',3449,3449) | inrange(``ffind'',3450,3451) | inrange(``ffind'',3452,3452) | inrange(``ffind'',3490,3499) | inrange(``ffind'',3996,3996)
		qui replace `newvar'=12 if inrange(``ffind'',3300,3300) | inrange(``ffind'',3310,3317) | inrange(``ffind'',3320,3325) | inrange(``ffind'',3330,3339) | inrange(``ffind'',3340,3341) | inrange(``ffind'',3350,3357) | inrange(``ffind'',3360,3369) | inrange(``ffind'',3370,3379) | inrange(``ffind'',3390,3399)
		qui replace `newvar'=13 if inrange(``ffind'',3400,3400) | inrange(``ffind'',3443,3443) | inrange(``ffind'',3444,3444) | inrange(``ffind'',3460,3469) | inrange(``ffind'',3470,3479) | inrange(``ffind'',3510,3519) | inrange(``ffind'',3520,3529) | inrange(``ffind'',3530,3530) | inrange(``ffind'',3531,3531) | inrange(``ffind'',3532,3532) | inrange(``ffind'',3533,3533) | inrange(``ffind'',3534,3534) | inrange(``ffind'',3535,3535) | inrange(``ffind'',3536,3536) | inrange(``ffind'',3538,3538) | inrange(``ffind'',3540,3549) | inrange(``ffind'',3550,3559) | inrange(``ffind'',3560,3569) | inrange(``ffind'',3580,3580) | inrange(``ffind'',3581,3581) | inrange(``ffind'',3582,3582) | inrange(``ffind'',3585,3585) | inrange(``ffind'',3586,3586) | inrange(``ffind'',3589,3589) | inrange(``ffind'',3590,3599)
		qui replace `newvar'=14 if inrange(``ffind'',3600,3600) | inrange(``ffind'',3610,3613) | inrange(``ffind'',3620,3621) | inrange(``ffind'',3623,3629) | inrange(``ffind'',3640,3644) | inrange(``ffind'',3645,3645) | inrange(``ffind'',3646,3646) | inrange(``ffind'',3648,3649) | inrange(``ffind'',3660,3660) | inrange(``ffind'',3690,3690) | inrange(``ffind'',3691,3692) | inrange(``ffind'',3699,3699)
		qui replace `newvar'=15 if inrange(``ffind'',2296,2296) | inrange(``ffind'',2396,2396) | inrange(``ffind'',3010,3011) | inrange(``ffind'',3537,3537) | inrange(``ffind'',3647,3647) | inrange(``ffind'',3694,3694) | inrange(``ffind'',3700,3700) | inrange(``ffind'',3710,3710) | inrange(``ffind'',3711,3711) | inrange(``ffind'',3713,3713) | inrange(``ffind'',3714,3714) | inrange(``ffind'',3715,3715) | inrange(``ffind'',3716,3716) | inrange(``ffind'',3792,3792) | inrange(``ffind'',3790,3791) | inrange(``ffind'',3799,3799)
		qui replace `newvar'=16 if inrange(``ffind'',3720,3720) | inrange(``ffind'',3721,3721) | inrange(``ffind'',3723,3724) | inrange(``ffind'',3725,3725) | inrange(``ffind'',3728,3729) | inrange(``ffind'',3730,3731) | inrange(``ffind'',3740,3743)
		qui replace `newvar'=17 if inrange(``ffind'',1000,1009) | inrange(``ffind'',1010,1019) | inrange(``ffind'',1020,1029) | inrange(``ffind'',1030,1039) | inrange(``ffind'',1040,1049) | inrange(``ffind'',1050,1059) | inrange(``ffind'',1060,1069) | inrange(``ffind'',1070,1079) | inrange(``ffind'',1080,1089) | inrange(``ffind'',1090,1099) | inrange(``ffind'',1100,1119) | inrange(``ffind'',1400,1499)
		qui replace `newvar'=18 if inrange(``ffind'',1200,1299)
		qui replace `newvar'=19 if inrange(``ffind'',1300,1300) | inrange(``ffind'',1310,1319) | inrange(``ffind'',1320,1329) | inrange(``ffind'',1330,1339) | inrange(``ffind'',1370,1379) | inrange(``ffind'',1380,1380) | inrange(``ffind'',1381,1381) | inrange(``ffind'',1382,1382) | inrange(``ffind'',1389,1389) | inrange(``ffind'',2900,2912) | inrange(``ffind'',2990,2999)
		qui replace `newvar'=20 if inrange(``ffind'',4900,4900) | inrange(``ffind'',4910,4911) | inrange(``ffind'',4920,4922) | inrange(``ffind'',4923,4923) | inrange(``ffind'',4924,4925) | inrange(``ffind'',4930,4931) | inrange(``ffind'',4932,4932) | inrange(``ffind'',4939,4939) | inrange(``ffind'',4940,4942)
		qui replace `newvar'=21 if inrange(``ffind'',4800,4800) | inrange(``ffind'',4810,4813) | inrange(``ffind'',4820,4822) | inrange(``ffind'',4830,4839) | inrange(``ffind'',4840,4841) | inrange(``ffind'',4880,4889) | inrange(``ffind'',4890,4890) | inrange(``ffind'',4891,4891) | inrange(``ffind'',4892,4892) | inrange(``ffind'',4899,4899)
		qui replace `newvar'=22 if inrange(``ffind'',7020,7021) | inrange(``ffind'',7030,7033) | inrange(``ffind'',7200,7200) | inrange(``ffind'',7210,7212) | inrange(``ffind'',7214,7214) | inrange(``ffind'',7215,7216) | inrange(``ffind'',7217,7217) | inrange(``ffind'',7218,7218) | inrange(``ffind'',7219,7219) | inrange(``ffind'',7220,7221) | inrange(``ffind'',7230,7231) | inrange(``ffind'',7240,7241) | inrange(``ffind'',7250,7251) | inrange(``ffind'',7260,7269) | inrange(``ffind'',7270,7290) | inrange(``ffind'',7291,7291) | inrange(``ffind'',7292,7299) | inrange(``ffind'',7300,7300) | inrange(``ffind'',7310,7319) | inrange(``ffind'',7320,7329) | inrange(``ffind'',7330,7339) | inrange(``ffind'',7340,7342) | inrange(``ffind'',7349,7349) | inrange(``ffind'',7350,7351) | inrange(``ffind'',7352,7352) | inrange(``ffind'',7353,7353) | inrange(``ffind'',7359,7359) | inrange(``ffind'',7360,7369) | inrange(``ffind'',7370,7372) | inrange(``ffind'',7374,7374) | inrange(``ffind'',7375,7375) | inrange(``ffind'',7376,7376) | inrange(``ffind'',7377,7377) | inrange(``ffind'',7378,7378) | inrange(``ffind'',7379,7379) | inrange(``ffind'',7380,7380) | inrange(``ffind'',7381,7382) | inrange(``ffind'',7383,7383) | inrange(``ffind'',7384,7384) | inrange(``ffind'',7385,7385) | inrange(``ffind'',7389,7390) | inrange(``ffind'',7391,7391) | inrange(``ffind'',7392,7392) | inrange(``ffind'',7393,7393) | inrange(``ffind'',7394,7394) | inrange(``ffind'',7395,7395) | inrange(``ffind'',7396,7396) | inrange(``ffind'',7397,7397) | inrange(``ffind'',7399,7399) | inrange(``ffind'',7500,7500) | inrange(``ffind'',7510,7519) | inrange(``ffind'',7520,7529) | inrange(``ffind'',7530,7539) | inrange(``ffind'',7540,7549) | inrange(``ffind'',7600,7600) | inrange(``ffind'',7620,7620) | inrange(``ffind'',7622,7622) | inrange(``ffind'',7623,7623) | inrange(``ffind'',7629,7629) | inrange(``ffind'',7630,7631) | inrange(``ffind'',7640,7641) | inrange(``ffind'',7690,7699) | inrange(``ffind'',8100,8199) | inrange(``ffind'',8200,8299) | inrange(``ffind'',8300,8399) | inrange(``ffind'',8400,8499) | inrange(``ffind'',8600,8699) | inrange(``ffind'',8700,8700) | inrange(``ffind'',8710,8713) | inrange(``ffind'',8720,8721) | inrange(``ffind'',8730,8734) | inrange(``ffind'',8740,8748) | inrange(``ffind'',8800,8899) | inrange(``ffind'',8900,8910) | inrange(``ffind'',8911,8911) | inrange(``ffind'',8920,8999)
		qui replace `newvar'=23 if inrange(``ffind'',3570,3579) | inrange(``ffind'',3622,3622) | inrange(``ffind'',3661,3661) | inrange(``ffind'',3662,3662) | inrange(``ffind'',3663,3663) | inrange(``ffind'',3664,3664) | inrange(``ffind'',3665,3665) | inrange(``ffind'',3666,3666) | inrange(``ffind'',3669,3669) | inrange(``ffind'',3670,3679) | inrange(``ffind'',3680,3680) | inrange(``ffind'',3681,3681) | inrange(``ffind'',3682,3682) | inrange(``ffind'',3683,3683) | inrange(``ffind'',3684,3684) | inrange(``ffind'',3685,3685) | inrange(``ffind'',3686,3686) | inrange(``ffind'',3687,3687) | inrange(``ffind'',3688,3688) | inrange(``ffind'',3689,3689) | inrange(``ffind'',3695,3695) | inrange(``ffind'',3810,3810) | inrange(``ffind'',3811,3811) | inrange(``ffind'',3812,3812) | inrange(``ffind'',3820,3820) | inrange(``ffind'',3821,3821) | inrange(``ffind'',3822,3822) | inrange(``ffind'',3823,3823) | inrange(``ffind'',3824,3824) | inrange(``ffind'',3825,3825) | inrange(``ffind'',3826,3826) | inrange(``ffind'',3827,3827) | inrange(``ffind'',3829,3829) | inrange(``ffind'',3830,3839) | inrange(``ffind'',7373,7373)
		qui replace `newvar'=24 if inrange(``ffind'',2440,2449) | inrange(``ffind'',2520,2549) | inrange(``ffind'',2600,2639) | inrange(``ffind'',2640,2659) | inrange(``ffind'',2670,2699) | inrange(``ffind'',2760,2761) | inrange(``ffind'',3220,3221) | inrange(``ffind'',3410,3412) | inrange(``ffind'',3950,3955)
		qui replace `newvar'=25 if inrange(``ffind'',4000,4013) | inrange(``ffind'',4040,4049) | inrange(``ffind'',4100,4100) | inrange(``ffind'',4110,4119) | inrange(``ffind'',4120,4121) | inrange(``ffind'',4130,4131) | inrange(``ffind'',4140,4142) | inrange(``ffind'',4150,4151) | inrange(``ffind'',4170,4173) | inrange(``ffind'',4190,4199) | inrange(``ffind'',4200,4200) | inrange(``ffind'',4210,4219) | inrange(``ffind'',4220,4229) | inrange(``ffind'',4230,4231) | inrange(``ffind'',4240,4249) | inrange(``ffind'',4400,4499) | inrange(``ffind'',4500,4599) | inrange(``ffind'',4600,4699) | inrange(``ffind'',4700,4700) | inrange(``ffind'',4710,4712) | inrange(``ffind'',4720,4729) | inrange(``ffind'',4730,4739) | inrange(``ffind'',4740,4749) | inrange(``ffind'',4780,4780) | inrange(``ffind'',4782,4782) | inrange(``ffind'',4783,4783) | inrange(``ffind'',4784,4784) | inrange(``ffind'',4785,4785) | inrange(``ffind'',4789,4789)
		qui replace `newvar'=26 if inrange(``ffind'',5000,5000) | inrange(``ffind'',5010,5015) | inrange(``ffind'',5020,5023) | inrange(``ffind'',5030,5039) | inrange(``ffind'',5040,5042) | inrange(``ffind'',5043,5043) | inrange(``ffind'',5044,5044) | inrange(``ffind'',5045,5045) | inrange(``ffind'',5046,5046) | inrange(``ffind'',5047,5047) | inrange(``ffind'',5048,5048) | inrange(``ffind'',5049,5049) | inrange(``ffind'',5050,5059) | inrange(``ffind'',5060,5060) | inrange(``ffind'',5063,5063) | inrange(``ffind'',5064,5064) | inrange(``ffind'',5065,5065) | inrange(``ffind'',5070,5078) | inrange(``ffind'',5080,5080) | inrange(``ffind'',5081,5081) | inrange(``ffind'',5082,5082) | inrange(``ffind'',5083,5083) | inrange(``ffind'',5084,5084) | inrange(``ffind'',5085,5085) | inrange(``ffind'',5086,5087) | inrange(``ffind'',5088,5088) | inrange(``ffind'',5090,5090) | inrange(``ffind'',5091,5092) | inrange(``ffind'',5093,5093) | inrange(``ffind'',5094,5094) | inrange(``ffind'',5099,5099) | inrange(``ffind'',5100,5100) | inrange(``ffind'',5110,5113) | inrange(``ffind'',5120,5122) | inrange(``ffind'',5130,5139) | inrange(``ffind'',5140,5149) | inrange(``ffind'',5150,5159) | inrange(``ffind'',5160,5169) | inrange(``ffind'',5170,5172) | inrange(``ffind'',5180,5182) | inrange(``ffind'',5190,5199)
		qui replace `newvar'=27 if inrange(``ffind'',5200,5200) | inrange(``ffind'',5210,5219) | inrange(``ffind'',5220,5229) | inrange(``ffind'',5230,5231) | inrange(``ffind'',5250,5251) | inrange(``ffind'',5260,5261) | inrange(``ffind'',5270,5271) | inrange(``ffind'',5300,5300) | inrange(``ffind'',5310,5311) | inrange(``ffind'',5320,5320) | inrange(``ffind'',5330,5331) | inrange(``ffind'',5334,5334) | inrange(``ffind'',5340,5349) | inrange(``ffind'',5390,5399) | inrange(``ffind'',5400,5400) | inrange(``ffind'',5410,5411) | inrange(``ffind'',5412,5412) | inrange(``ffind'',5420,5429) | inrange(``ffind'',5430,5439) | inrange(``ffind'',5440,5449) | inrange(``ffind'',5450,5459) | inrange(``ffind'',5460,5469) | inrange(``ffind'',5490,5499) | inrange(``ffind'',5500,5500) | inrange(``ffind'',5510,5529) | inrange(``ffind'',5530,5539) | inrange(``ffind'',5540,5549) | inrange(``ffind'',5550,5559) | inrange(``ffind'',5560,5569) | inrange(``ffind'',5570,5579) | inrange(``ffind'',5590,5599) | inrange(``ffind'',5600,5699) | inrange(``ffind'',5700,5700) | inrange(``ffind'',5710,5719) | inrange(``ffind'',5720,5722) | inrange(``ffind'',5730,5733) | inrange(``ffind'',5734,5734) | inrange(``ffind'',5735,5735) | inrange(``ffind'',5736,5736) | inrange(``ffind'',5750,5799) | inrange(``ffind'',5900,5900) | inrange(``ffind'',5910,5912) | inrange(``ffind'',5920,5929) | inrange(``ffind'',5930,5932) | inrange(``ffind'',5940,5940) | inrange(``ffind'',5941,5941) | inrange(``ffind'',5942,5942) | inrange(``ffind'',5943,5943) | inrange(``ffind'',5944,5944) | inrange(``ffind'',5945,5945) | inrange(``ffind'',5946,5946) | inrange(``ffind'',5947,5947) | inrange(``ffind'',5948,5948) | inrange(``ffind'',5949,5949) | inrange(``ffind'',5950,5959) | inrange(``ffind'',5960,5969) | inrange(``ffind'',5970,5979) | inrange(``ffind'',5980,5989) | inrange(``ffind'',5990,5990) | inrange(``ffind'',5992,5992) | inrange(``ffind'',5993,5993) | inrange(``ffind'',5994,5994) | inrange(``ffind'',5995,5995) | inrange(``ffind'',5999,5999)
		qui replace `newvar'=28 if inrange(``ffind'',5800,5819) | inrange(``ffind'',5820,5829) | inrange(``ffind'',5890,5899) | inrange(``ffind'',7000,7000) | inrange(``ffind'',7010,7019) | inrange(``ffind'',7040,7049) | inrange(``ffind'',7213,7213)
		qui replace `newvar'=29 if inrange(``ffind'',6000,6000) | inrange(``ffind'',6010,6019) | inrange(``ffind'',6020,6020) | inrange(``ffind'',6021,6021) | inrange(``ffind'',6022,6022) | inrange(``ffind'',6023,6024) | inrange(``ffind'',6025,6025) | inrange(``ffind'',6026,6026) | inrange(``ffind'',6027,6027) | inrange(``ffind'',6028,6029) | inrange(``ffind'',6030,6036) | inrange(``ffind'',6040,6059) | inrange(``ffind'',6060,6062) | inrange(``ffind'',6080,6082) | inrange(``ffind'',6090,6099) | inrange(``ffind'',6100,6100) | inrange(``ffind'',6110,6111) | inrange(``ffind'',6112,6113) | inrange(``ffind'',6120,6129) | inrange(``ffind'',6130,6139) | inrange(``ffind'',6140,6149) | inrange(``ffind'',6150,6159) | inrange(``ffind'',6160,6169) | inrange(``ffind'',6170,6179) | inrange(``ffind'',6190,6199) | inrange(``ffind'',6200,6299) | inrange(``ffind'',6300,6300) | inrange(``ffind'',6310,6319) | inrange(``ffind'',6320,6329) | inrange(``ffind'',6330,6331) | inrange(``ffind'',6350,6351) | inrange(``ffind'',6360,6361) | inrange(``ffind'',6370,6379) | inrange(``ffind'',6390,6399) | inrange(``ffind'',6400,6411) | inrange(``ffind'',6500,6500) | inrange(``ffind'',6510,6510) | inrange(``ffind'',6512,6512) | inrange(``ffind'',6513,6513) | inrange(``ffind'',6514,6514) | inrange(``ffind'',6515,6515) | inrange(``ffind'',6517,6519) | inrange(``ffind'',6520,6529) | inrange(``ffind'',6530,6531) | inrange(``ffind'',6532,6532) | inrange(``ffind'',6540,6541) | inrange(``ffind'',6550,6553) | inrange(``ffind'',6590,6599) | inrange(``ffind'',6610,6611) | inrange(``ffind'',6700,6700) | inrange(``ffind'',6710,6719) | inrange(``ffind'',6720,6722) | inrange(``ffind'',6723,6723) | inrange(``ffind'',6724,6724) | inrange(``ffind'',6725,6725) | inrange(``ffind'',6726,6726) | inrange(``ffind'',6730,6733) | inrange(``ffind'',6740,6779) | inrange(``ffind'',6790,6791) | inrange(``ffind'',6792,6792) | inrange(``ffind'',6793,6793) | inrange(``ffind'',6794,6794) | inrange(``ffind'',6795,6795) | inrange(``ffind'',6798,6798) | inrange(``ffind'',6799,6799)
		qui replace `newvar'=30 if missing(`newvar') & ~missing(``ffind'')
		}

	else if ``ftyp''==38 {
		label define `newvar' 1 "Agriculture, forestry, and fishing" 2 "Mining" 3 "Oil and Gas Extraction" 4 "Nonmetalic Minerals Except Fuels" 5 "Construction" 6 "Food and Kindred Products" 7 "Tobacco Products" 8 "Textile Mill Products" 9 "Apparel and other Textile Products" 10 "Lumber and Wood Products" 11 "Furniture and Fixtures" 12 "Paper and Allied Products" 13 "Printing and Publishing" 14 "Chemicals and Allied Products" 15 "Petroleum and Coal Products" 16 "Rubber and Miscellaneous Plastics Products" 17 "Leather and Leather Products" 18 "Stone, Clay and Glass Products" 19 "Primary Metal Industries" 20 "Fabricated Metal Products" 21 "Machinery, Except Electrical" 22 "Electrical and Electronic Equipment" 23 "Transportation Equipment" 24 "Instruments and Related Products" 25 "Miscellaneous Manufacturing Industries" 26 "Transportation" 27 "Telephone and Telegraph Communication" 28 "Radio and Television Broadcasting" 29 "Electric, Gas, and Water Supply" 30 "Sanitary Services" 31 "Steam Supply" 32 "Irrigation Systems" 33 "Wholesale" 34 "Retail Stores" 35 "Finance, Insurance, and Real Estate" 36 "Services" 37 "Public Administration" 38 "Almost Nothing"
		label values `newvar' `newvar'

		qui replace `newvar'=1 if inrange(``ffind'',100,999)
		qui replace `newvar'=2 if inrange(``ffind'',1000,1299)
		qui replace `newvar'=3 if inrange(``ffind'',1300,1399)
		qui replace `newvar'=4 if inrange(``ffind'',1400,1499)
		qui replace `newvar'=5 if inrange(``ffind'',1500,1799)
		qui replace `newvar'=6 if inrange(``ffind'',2000,2099)
		qui replace `newvar'=7 if inrange(``ffind'',2100,2199)
		qui replace `newvar'=8 if inrange(``ffind'',2200,2299)
		qui replace `newvar'=9 if inrange(``ffind'',2300,2399)
		qui replace `newvar'=10 if inrange(``ffind'',2400,2499)
		qui replace `newvar'=11 if inrange(``ffind'',2500,2599)
		qui replace `newvar'=12 if inrange(``ffind'',2600,2661)
		qui replace `newvar'=13 if inrange(``ffind'',2700,2799)
		qui replace `newvar'=14 if inrange(``ffind'',2800,2899)
		qui replace `newvar'=15 if inrange(``ffind'',2900,2999)
		qui replace `newvar'=16 if inrange(``ffind'',3000,3099)
		qui replace `newvar'=17 if inrange(``ffind'',3100,3199)
		qui replace `newvar'=18 if inrange(``ffind'',3200,3299)
		qui replace `newvar'=19 if inrange(``ffind'',3300,3399)
		qui replace `newvar'=20 if inrange(``ffind'',3400,3499)
		qui replace `newvar'=21 if inrange(``ffind'',3500,3599)
		qui replace `newvar'=22 if inrange(``ffind'',3600,3699)
		qui replace `newvar'=23 if inrange(``ffind'',3700,3799)
		qui replace `newvar'=24 if inrange(``ffind'',3800,3879)
		qui replace `newvar'=25 if inrange(``ffind'',3900,3999)
		qui replace `newvar'=26 if inrange(``ffind'',4000,4799)
		qui replace `newvar'=27 if inrange(``ffind'',4800,4829)
		qui replace `newvar'=28 if inrange(``ffind'',4830,4899)
		qui replace `newvar'=29 if inrange(``ffind'',4900,4949)
		qui replace `newvar'=30 if inrange(``ffind'',4950,4959)
		qui replace `newvar'=31 if inrange(``ffind'',4960,4969)
		qui replace `newvar'=32 if inrange(``ffind'',4970,4979)
		qui replace `newvar'=33 if inrange(``ffind'',5000,5199)
		qui replace `newvar'=34 if inrange(``ffind'',5200,5999)
		qui replace `newvar'=35 if inrange(``ffind'',6000,6999)
		qui replace `newvar'=36 if inrange(``ffind'',7000,8999)
		qui replace `newvar'=37 if inrange(``ffind'',9000,9999)
		qui replace `newvar'=38 if missing(`newvar') & ~missing(``ffind'')

		}
	else if ``ftyp''==48 {
		label define `newvar' 1 "Agriculture" 2 "Food Products" 3 "Candy & Soda" 4 "Beer & Liquor" 5 "Tobacco Products" 6 "Recreation" 7 "Entertainment" 8 "Printing and Publishing" 9 "Consumer Goods" 10 "Apparel" 11 "Healthcare" 12 "Medical Equipment" 13 "Pharmaceutical Products" 14 "Chemicals" 15 "Rubber and Plastic Products" 16 "Textiles" 17 "Construction Materials" 18 "Construction" 19 "Steel Works Etc" 20 "Fabricated Products" 21 "Machinery" 22 "Electrical Equipment" 23 "Automobiles and Trucks" 24 "Aircraft" 25 "Shipbuilding, Railroad Equipment" 26 "Defense" 27 "Precious Metals" 28 "Non-Metallic and Industrial Metal Mining" 29 "Coal" 30 "Petroleum and Natural Gas" 31 "Utilities" 32 "Communication" 33 "Personal Services" 34 "Business Services" 35 "Computers" 36 "Electronic Equipment" 37 "Measuring and Control Equipment" 38 "Business Supplies" 39 "Shipping Containers" 40 "Transportation" 41 "Wholesale" 42 "Retail" 43 "Restaraunts, Hotels, Motels" 44 "Banking" 45 "Insurance" 46 "Real Estate" 47 "Trading" 48 "Almost Nothing"
		label values `newvar' `newvar'

		qui replace `newvar'=1 if inrange(``ffind'',100,199) | inrange(``ffind'',200,299) | inrange(``ffind'',700,799) | inrange(``ffind'',910,919) | inrange(``ffind'',2048,2048)
		qui replace `newvar'=2 if inrange(``ffind'',2000,2009) | inrange(``ffind'',2010,2019) | inrange(``ffind'',2020,2029) | inrange(``ffind'',2030,2039) | inrange(``ffind'',2040,2046) | inrange(``ffind'',2050,2059) | inrange(``ffind'',2060,2063) | inrange(``ffind'',2070,2079) | inrange(``ffind'',2090,2092) | inrange(``ffind'',2095,2095) | inrange(``ffind'',2098,2099)
		qui replace `newvar'=3 if inrange(``ffind'',2064,2068) | inrange(``ffind'',2086,2086) | inrange(``ffind'',2087,2087) | inrange(``ffind'',2096,2096) | inrange(``ffind'',2097,2097)
		qui replace `newvar'=4 if inrange(``ffind'',2080,2080) | inrange(``ffind'',2082,2082) | inrange(``ffind'',2083,2083) | inrange(``ffind'',2084,2084) | inrange(``ffind'',2085,2085)
		qui replace `newvar'=5 if inrange(``ffind'',2100,2199)
		qui replace `newvar'=6 if inrange(``ffind'',920,999) | inrange(``ffind'',3650,3651) | inrange(``ffind'',3652,3652) | inrange(``ffind'',3732,3732) | inrange(``ffind'',3930,3931) | inrange(``ffind'',3940,3949)
		qui replace `newvar'=7 if inrange(``ffind'',7800,7829) | inrange(``ffind'',7830,7833) | inrange(``ffind'',7840,7841) | inrange(``ffind'',7900,7900) | inrange(``ffind'',7910,7911) | inrange(``ffind'',7920,7929) | inrange(``ffind'',7930,7933) | inrange(``ffind'',7940,7949) | inrange(``ffind'',7980,7980) | inrange(``ffind'',7990,7999)
		qui replace `newvar'=8 if inrange(``ffind'',2700,2709) | inrange(``ffind'',2710,2719) | inrange(``ffind'',2720,2729) | inrange(``ffind'',2730,2739) | inrange(``ffind'',2740,2749) | inrange(``ffind'',2770,2771) | inrange(``ffind'',2780,2789) | inrange(``ffind'',2790,2799)
		qui replace `newvar'=9 if inrange(``ffind'',2047,2047) | inrange(``ffind'',2391,2392) | inrange(``ffind'',2510,2519) | inrange(``ffind'',2590,2599) | inrange(``ffind'',2840,2843) | inrange(``ffind'',2844,2844) | inrange(``ffind'',3160,3161) | inrange(``ffind'',3170,3171) | inrange(``ffind'',3172,3172) | inrange(``ffind'',3190,3199) | inrange(``ffind'',3229,3229) | inrange(``ffind'',3260,3260) | inrange(``ffind'',3262,3263) | inrange(``ffind'',3269,3269) | inrange(``ffind'',3230,3231) | inrange(``ffind'',3630,3639) | inrange(``ffind'',3750,3751) | inrange(``ffind'',3800,3800) | inrange(``ffind'',3860,3861) | inrange(``ffind'',3870,3873) | inrange(``ffind'',3910,3911) | inrange(``ffind'',3914,3914) | inrange(``ffind'',3915,3915) | inrange(``ffind'',3960,3962) | inrange(``ffind'',3991,3991) | inrange(``ffind'',3995,3995)
		qui replace `newvar'=10 if inrange(``ffind'',2300,2390) | inrange(``ffind'',3020,3021) | inrange(``ffind'',3100,3111) | inrange(``ffind'',3130,3131) | inrange(``ffind'',3140,3149) | inrange(``ffind'',3150,3151) | inrange(``ffind'',3963,3965)
		qui replace `newvar'=11 if inrange(``ffind'',8000,8099)
		qui replace `newvar'=12 if inrange(``ffind'',3693,3693) | inrange(``ffind'',3840,3849) | inrange(``ffind'',3850,3851)
		qui replace `newvar'=13 if inrange(``ffind'',2830,2830) | inrange(``ffind'',2831,2831) | inrange(``ffind'',2833,2833) | inrange(``ffind'',2834,2834) | inrange(``ffind'',2835,2835) | inrange(``ffind'',2836,2836)
		qui replace `newvar'=14 if inrange(``ffind'',2800,2809) | inrange(``ffind'',2810,2819) | inrange(``ffind'',2820,2829) | inrange(``ffind'',2850,2859) | inrange(``ffind'',2860,2869) | inrange(``ffind'',2870,2879) | inrange(``ffind'',2890,2899)
		qui replace `newvar'=15 if inrange(``ffind'',3031,3031) | inrange(``ffind'',3041,3041) | inrange(``ffind'',3050,3053) | inrange(``ffind'',3060,3069) | inrange(``ffind'',3070,3079) | inrange(``ffind'',3080,3089) | inrange(``ffind'',3090,3099)
		qui replace `newvar'=16 if inrange(``ffind'',2200,2269) | inrange(``ffind'',2270,2279) | inrange(``ffind'',2280,2284) | inrange(``ffind'',2290,2295) | inrange(``ffind'',2297,2297) | inrange(``ffind'',2298,2298) | inrange(``ffind'',2299,2299) | inrange(``ffind'',2393,2395) | inrange(``ffind'',2397,2399)
		qui replace `newvar'=17 if inrange(``ffind'',800,899) | inrange(``ffind'',2400,2439) | inrange(``ffind'',2450,2459) | inrange(``ffind'',2490,2499) | inrange(``ffind'',2660,2661) | inrange(``ffind'',2950,2952) | inrange(``ffind'',3200,3200) | inrange(``ffind'',3210,3211) | inrange(``ffind'',3240,3241) | inrange(``ffind'',3250,3259) | inrange(``ffind'',3261,3261) | inrange(``ffind'',3264,3264) | inrange(``ffind'',3270,3275) | inrange(``ffind'',3280,3281) | inrange(``ffind'',3290,3293) | inrange(``ffind'',3295,3299) | inrange(``ffind'',3420,3429) | inrange(``ffind'',3430,3433) | inrange(``ffind'',3440,3441) | inrange(``ffind'',3442,3442) | inrange(``ffind'',3446,3446) | inrange(``ffind'',3448,3448) | inrange(``ffind'',3449,3449) | inrange(``ffind'',3450,3451) | inrange(``ffind'',3452,3452) | inrange(``ffind'',3490,3499) | inrange(``ffind'',3996,3996)
		qui replace `newvar'=18 if inrange(``ffind'',1500,1511) | inrange(``ffind'',1520,1529) | inrange(``ffind'',1530,1539) | inrange(``ffind'',1540,1549) | inrange(``ffind'',1600,1699) | inrange(``ffind'',1700,1799)
		qui replace `newvar'=19 if inrange(``ffind'',3300,3300) | inrange(``ffind'',3310,3317) | inrange(``ffind'',3320,3325) | inrange(``ffind'',3330,3339) | inrange(``ffind'',3340,3341) | inrange(``ffind'',3350,3357) | inrange(``ffind'',3360,3369) | inrange(``ffind'',3370,3379) | inrange(``ffind'',3390,3399)
		qui replace `newvar'=20 if inrange(``ffind'',3400,3400) | inrange(``ffind'',3443,3443) | inrange(``ffind'',3444,3444) | inrange(``ffind'',3460,3469) | inrange(``ffind'',3470,3479)
		qui replace `newvar'=21 if inrange(``ffind'',3510,3519) | inrange(``ffind'',3520,3529) | inrange(``ffind'',3530,3530) | inrange(``ffind'',3531,3531) | inrange(``ffind'',3532,3532) | inrange(``ffind'',3533,3533) | inrange(``ffind'',3534,3534) | inrange(``ffind'',3535,3535) | inrange(``ffind'',3536,3536) | inrange(``ffind'',3538,3538) | inrange(``ffind'',3540,3549) | inrange(``ffind'',3550,3559) | inrange(``ffind'',3560,3569) | inrange(``ffind'',3580,3580) | inrange(``ffind'',3581,3581) | inrange(``ffind'',3582,3582) | inrange(``ffind'',3585,3585) | inrange(``ffind'',3586,3586) | inrange(``ffind'',3589,3589) | inrange(``ffind'',3590,3599)
		qui replace `newvar'=22 if inrange(``ffind'',3600,3600) | inrange(``ffind'',3610,3613) | inrange(``ffind'',3620,3621) | inrange(``ffind'',3623,3629) | inrange(``ffind'',3640,3644) | inrange(``ffind'',3645,3645) | inrange(``ffind'',3646,3646) | inrange(``ffind'',3648,3649) | inrange(``ffind'',3660,3660) | inrange(``ffind'',3690,3690) | inrange(``ffind'',3691,3692) | inrange(``ffind'',3699,3699)
		qui replace `newvar'=23 if inrange(``ffind'',2296,2296) | inrange(``ffind'',2396,2396) | inrange(``ffind'',3010,3011) | inrange(``ffind'',3537,3537) | inrange(``ffind'',3647,3647) | inrange(``ffind'',3694,3694) | inrange(``ffind'',3700,3700) | inrange(``ffind'',3710,3710) | inrange(``ffind'',3711,3711) | inrange(``ffind'',3713,3713) | inrange(``ffind'',3714,3714) | inrange(``ffind'',3715,3715) | inrange(``ffind'',3716,3716) | inrange(``ffind'',3792,3792) | inrange(``ffind'',3790,3791) | inrange(``ffind'',3799,3799)
		qui replace `newvar'=24 if inrange(``ffind'',3720,3720) | inrange(``ffind'',3721,3721) | inrange(``ffind'',3723,3724) | inrange(``ffind'',3725,3725) | inrange(``ffind'',3728,3729)
		qui replace `newvar'=25 if inrange(``ffind'',3730,3731) | inrange(``ffind'',3740,3743)
		qui replace `newvar'=26 if inrange(``ffind'',3760,3769) | inrange(``ffind'',3795,3795) | inrange(``ffind'',3480,3489)
		qui replace `newvar'=27 if inrange(``ffind'',1040,1049)
		qui replace `newvar'=28 if inrange(``ffind'',1000,1009) | inrange(``ffind'',1010,1019) | inrange(``ffind'',1020,1029) | inrange(``ffind'',1030,1039) | inrange(``ffind'',1050,1059) | inrange(``ffind'',1060,1069) | inrange(``ffind'',1070,1079) | inrange(``ffind'',1080,1089) | inrange(``ffind'',1090,1099) | inrange(``ffind'',1100,1119) | inrange(``ffind'',1400,1499)
		qui replace `newvar'=29 if inrange(``ffind'',1200,1299)
		qui replace `newvar'=30 if inrange(``ffind'',1300,1300) | inrange(``ffind'',1310,1319) | inrange(``ffind'',1320,1329) | inrange(``ffind'',1330,1339) | inrange(``ffind'',1370,1379) | inrange(``ffind'',1380,1380) | inrange(``ffind'',1381,1381) | inrange(``ffind'',1382,1382) | inrange(``ffind'',1389,1389) | inrange(``ffind'',2900,2912) | inrange(``ffind'',2990,2999)
		qui replace `newvar'=31 if inrange(``ffind'',4900,4900) | inrange(``ffind'',4910,4911) | inrange(``ffind'',4920,4922) | inrange(``ffind'',4923,4923) | inrange(``ffind'',4924,4925) | inrange(``ffind'',4930,4931) | inrange(``ffind'',4932,4932) | inrange(``ffind'',4939,4939) | inrange(``ffind'',4940,4942)
		qui replace `newvar'=32 if inrange(``ffind'',4800,4800) | inrange(``ffind'',4810,4813) | inrange(``ffind'',4820,4822) | inrange(``ffind'',4830,4839) | inrange(``ffind'',4840,4841) | inrange(``ffind'',4880,4889) | inrange(``ffind'',4890,4890) | inrange(``ffind'',4891,4891) | inrange(``ffind'',4892,4892) | inrange(``ffind'',4899,4899)
		qui replace `newvar'=33 if inrange(``ffind'',7020,7021) | inrange(``ffind'',7030,7033) | inrange(``ffind'',7200,7200) | inrange(``ffind'',7210,7212) | inrange(``ffind'',7214,7214) | inrange(``ffind'',7215,7216) | inrange(``ffind'',7217,7217) | inrange(``ffind'',7219,7219) | inrange(``ffind'',7220,7221) | inrange(``ffind'',7230,7231) | inrange(``ffind'',7240,7241) | inrange(``ffind'',7250,7251) | inrange(``ffind'',7260,7269) | inrange(``ffind'',7270,7290) | inrange(``ffind'',7291,7291) | inrange(``ffind'',7292,7299) | inrange(``ffind'',7395,7395) | inrange(``ffind'',7500,7500) | inrange(``ffind'',7520,7529) | inrange(``ffind'',7530,7539) | inrange(``ffind'',7540,7549) | inrange(``ffind'',7600,7600) | inrange(``ffind'',7620,7620) | inrange(``ffind'',7622,7622) | inrange(``ffind'',7623,7623) | inrange(``ffind'',7629,7629) | inrange(``ffind'',7630,7631) | inrange(``ffind'',7640,7641) | inrange(``ffind'',7690,7699) | inrange(``ffind'',8100,8199) | inrange(``ffind'',8200,8299) | inrange(``ffind'',8300,8399) | inrange(``ffind'',8400,8499) | inrange(``ffind'',8600,8699) | inrange(``ffind'',8800,8899) | inrange(``ffind'',7510,7515)
		qui replace `newvar'=34 if inrange(``ffind'',2750,2759) | inrange(``ffind'',3993,3993) | inrange(``ffind'',7218,7218) | inrange(``ffind'',7300,7300) | inrange(``ffind'',7310,7319) | inrange(``ffind'',7320,7329) | inrange(``ffind'',7330,7339) | inrange(``ffind'',7340,7342) | inrange(``ffind'',7349,7349) | inrange(``ffind'',7350,7351) | inrange(``ffind'',7352,7352) | inrange(``ffind'',7353,7353) | inrange(``ffind'',7359,7359) | inrange(``ffind'',7360,7369) | inrange(``ffind'',7370,7372) | inrange(``ffind'',7374,7374) | inrange(``ffind'',7375,7375) | inrange(``ffind'',7376,7376) | inrange(``ffind'',7377,7377) | inrange(``ffind'',7378,7378) | inrange(``ffind'',7379,7379) | inrange(``ffind'',7380,7380) | inrange(``ffind'',7381,7382) | inrange(``ffind'',7383,7383) | inrange(``ffind'',7384,7384) | inrange(``ffind'',7385,7385) | inrange(``ffind'',7389,7390) | inrange(``ffind'',7391,7391) | inrange(``ffind'',7392,7392) | inrange(``ffind'',7393,7393) | inrange(``ffind'',7394,7394) | inrange(``ffind'',7396,7396) | inrange(``ffind'',7397,7397) | inrange(``ffind'',7399,7399) | inrange(``ffind'',7519,7519) | inrange(``ffind'',8700,8700) | inrange(``ffind'',8710,8713) | inrange(``ffind'',8720,8721) | inrange(``ffind'',8730,8734) | inrange(``ffind'',8740,8748) | inrange(``ffind'',8900,8910) | inrange(``ffind'',8911,8911) | inrange(``ffind'',8920,8999) | inrange(``ffind'',4220,4229)
		qui replace `newvar'=35 if inrange(``ffind'',3570,3579) | inrange(``ffind'',3680,3680) | inrange(``ffind'',3681,3681) | inrange(``ffind'',3682,3682) | inrange(``ffind'',3683,3683) | inrange(``ffind'',3684,3684) | inrange(``ffind'',3685,3685) | inrange(``ffind'',3686,3686) | inrange(``ffind'',3687,3687) | inrange(``ffind'',3688,3688) | inrange(``ffind'',3689,3689) | inrange(``ffind'',3695,3695) | inrange(``ffind'',7373,7373)
		qui replace `newvar'=36 if inrange(``ffind'',3622,3622) | inrange(``ffind'',3661,3661) | inrange(``ffind'',3662,3662) | inrange(``ffind'',3663,3663) | inrange(``ffind'',3664,3664) | inrange(``ffind'',3665,3665) | inrange(``ffind'',3666,3666) | inrange(``ffind'',3669,3669) | inrange(``ffind'',3670,3679) | inrange(``ffind'',3810,3810) | inrange(``ffind'',3812,3812)
		qui replace `newvar'=37 if inrange(``ffind'',3811,3811) | inrange(``ffind'',3820,3820) | inrange(``ffind'',3821,3821) | inrange(``ffind'',3822,3822) | inrange(``ffind'',3823,3823) | inrange(``ffind'',3824,3824) | inrange(``ffind'',3825,3825) | inrange(``ffind'',3826,3826) | inrange(``ffind'',3827,3827) | inrange(``ffind'',3829,3829) | inrange(``ffind'',3830,3839)
		qui replace `newvar'=38 if inrange(``ffind'',2520,2549) | inrange(``ffind'',2600,2639) | inrange(``ffind'',2670,2699) | inrange(``ffind'',2760,2761) | inrange(``ffind'',3950,3955)
		qui replace `newvar'=39 if inrange(``ffind'',2440,2449) | inrange(``ffind'',2640,2659) | inrange(``ffind'',3220,3221) | inrange(``ffind'',3410,3412)
		qui replace `newvar'=40 if inrange(``ffind'',4000,4013) | inrange(``ffind'',4040,4049) | inrange(``ffind'',4100,4100) | inrange(``ffind'',4110,4119) | inrange(``ffind'',4120,4121) | inrange(``ffind'',4130,4131) | inrange(``ffind'',4140,4142) | inrange(``ffind'',4150,4151) | inrange(``ffind'',4170,4173) | inrange(``ffind'',4190,4199) | inrange(``ffind'',4200,4200) | inrange(``ffind'',4210,4219) | inrange(``ffind'',4230,4231) | inrange(``ffind'',4240,4249) | inrange(``ffind'',4400,4499) | inrange(``ffind'',4500,4599) | inrange(``ffind'',4600,4699) | inrange(``ffind'',4700,4700) | inrange(``ffind'',4710,4712) | inrange(``ffind'',4720,4729) | inrange(``ffind'',4730,4739) | inrange(``ffind'',4740,4749) | inrange(``ffind'',4780,4780) | inrange(``ffind'',4782,4782) | inrange(``ffind'',4783,4783) | inrange(``ffind'',4784,4784) | inrange(``ffind'',4785,4785) | inrange(``ffind'',4789,4789)
		qui replace `newvar'=41 if inrange(``ffind'',5000,5000) | inrange(``ffind'',5010,5015) | inrange(``ffind'',5020,5023) | inrange(``ffind'',5030,5039) | inrange(``ffind'',5040,5042) | inrange(``ffind'',5043,5043) | inrange(``ffind'',5044,5044) | inrange(``ffind'',5045,5045) | inrange(``ffind'',5046,5046) | inrange(``ffind'',5047,5047) | inrange(``ffind'',5048,5048) | inrange(``ffind'',5049,5049) | inrange(``ffind'',5050,5059) | inrange(``ffind'',5060,5060) | inrange(``ffind'',5063,5063) | inrange(``ffind'',5064,5064) | inrange(``ffind'',5065,5065) | inrange(``ffind'',5070,5078) | inrange(``ffind'',5080,5080) | inrange(``ffind'',5081,5081) | inrange(``ffind'',5082,5082) | inrange(``ffind'',5083,5083) | inrange(``ffind'',5084,5084) | inrange(``ffind'',5085,5085) | inrange(``ffind'',5086,5087) | inrange(``ffind'',5088,5088) | inrange(``ffind'',5090,5090) | inrange(``ffind'',5091,5092) | inrange(``ffind'',5093,5093) | inrange(``ffind'',5094,5094) | inrange(``ffind'',5099,5099) | inrange(``ffind'',5100,5100) | inrange(``ffind'',5110,5113) | inrange(``ffind'',5120,5122) | inrange(``ffind'',5130,5139) | inrange(``ffind'',5140,5149) | inrange(``ffind'',5150,5159) | inrange(``ffind'',5160,5169) | inrange(``ffind'',5170,5172) | inrange(``ffind'',5180,5182) | inrange(``ffind'',5190,5199)
		qui replace `newvar'=42 if inrange(``ffind'',5200,5200) | inrange(``ffind'',5210,5219) | inrange(``ffind'',5220,5229) | inrange(``ffind'',5230,5231) | inrange(``ffind'',5250,5251) | inrange(``ffind'',5260,5261) | inrange(``ffind'',5270,5271) | inrange(``ffind'',5300,5300) | inrange(``ffind'',5310,5311) | inrange(``ffind'',5320,5320) | inrange(``ffind'',5330,5331) | inrange(``ffind'',5334,5334) | inrange(``ffind'',5340,5349) | inrange(``ffind'',5390,5399) | inrange(``ffind'',5400,5400) | inrange(``ffind'',5410,5411) | inrange(``ffind'',5412,5412) | inrange(``ffind'',5420,5429) | inrange(``ffind'',5430,5439) | inrange(``ffind'',5440,5449) | inrange(``ffind'',5450,5459) | inrange(``ffind'',5460,5469) | inrange(``ffind'',5490,5499) | inrange(``ffind'',5500,5500) | inrange(``ffind'',5510,5529) | inrange(``ffind'',5530,5539) | inrange(``ffind'',5540,5549) | inrange(``ffind'',5550,5559) | inrange(``ffind'',5560,5569) | inrange(``ffind'',5570,5579) | inrange(``ffind'',5590,5599) | inrange(``ffind'',5600,5699) | inrange(``ffind'',5700,5700) | inrange(``ffind'',5710,5719) | inrange(``ffind'',5720,5722) | inrange(``ffind'',5730,5733) | inrange(``ffind'',5734,5734) | inrange(``ffind'',5735,5735) | inrange(``ffind'',5736,5736) | inrange(``ffind'',5750,5799) | inrange(``ffind'',5900,5900) | inrange(``ffind'',5910,5912) | inrange(``ffind'',5920,5929) | inrange(``ffind'',5930,5932) | inrange(``ffind'',5940,5940) | inrange(``ffind'',5941,5941) | inrange(``ffind'',5942,5942) | inrange(``ffind'',5943,5943) | inrange(``ffind'',5944,5944) | inrange(``ffind'',5945,5945) | inrange(``ffind'',5946,5946) | inrange(``ffind'',5947,5947) | inrange(``ffind'',5948,5948) | inrange(``ffind'',5949,5949) | inrange(``ffind'',5950,5959) | inrange(``ffind'',5960,5969) | inrange(``ffind'',5970,5979) | inrange(``ffind'',5980,5989) | inrange(``ffind'',5990,5990) | inrange(``ffind'',5992,5992) | inrange(``ffind'',5993,5993) | inrange(``ffind'',5994,5994) | inrange(``ffind'',5995,5995) | inrange(``ffind'',5999,5999)
		qui replace `newvar'=43 if inrange(``ffind'',5800,5819) | inrange(``ffind'',5820,5829) | inrange(``ffind'',5890,5899) | inrange(``ffind'',7000,7000) | inrange(``ffind'',7010,7019) | inrange(``ffind'',7040,7049) | inrange(``ffind'',7213,7213)
		qui replace `newvar'=44 if inrange(``ffind'',6000,6000) | inrange(``ffind'',6010,6019) | inrange(``ffind'',6020,6020) | inrange(``ffind'',6021,6021) | inrange(``ffind'',6022,6022) | inrange(``ffind'',6023,6024) | inrange(``ffind'',6025,6025) | inrange(``ffind'',6026,6026) | inrange(``ffind'',6027,6027) | inrange(``ffind'',6028,6029) | inrange(``ffind'',6030,6036) | inrange(``ffind'',6040,6059) | inrange(``ffind'',6060,6062) | inrange(``ffind'',6080,6082) | inrange(``ffind'',6090,6099) | inrange(``ffind'',6100,6100) | inrange(``ffind'',6110,6111) | inrange(``ffind'',6112,6113) | inrange(``ffind'',6120,6129) | inrange(``ffind'',6130,6139) | inrange(``ffind'',6140,6149) | inrange(``ffind'',6150,6159) | inrange(``ffind'',6160,6169) | inrange(``ffind'',6170,6179) | inrange(``ffind'',6190,6199)
		qui replace `newvar'=45 if inrange(``ffind'',6300,6300) | inrange(``ffind'',6310,6319) | inrange(``ffind'',6320,6329) | inrange(``ffind'',6330,6331) | inrange(``ffind'',6350,6351) | inrange(``ffind'',6360,6361) | inrange(``ffind'',6370,6379) | inrange(``ffind'',6390,6399) | inrange(``ffind'',6400,6411)
		qui replace `newvar'=46 if inrange(``ffind'',6500,6500) | inrange(``ffind'',6510,6510) | inrange(``ffind'',6512,6512) | inrange(``ffind'',6513,6513) | inrange(``ffind'',6514,6514) | inrange(``ffind'',6515,6515) | inrange(``ffind'',6517,6519) | inrange(``ffind'',6520,6529) | inrange(``ffind'',6530,6531) | inrange(``ffind'',6532,6532) | inrange(``ffind'',6540,6541) | inrange(``ffind'',6550,6553) | inrange(``ffind'',6590,6599) | inrange(``ffind'',6610,6611)
		qui replace `newvar'=47 if inrange(``ffind'',6200,6299) | inrange(``ffind'',6700,6700) | inrange(``ffind'',6710,6719) | inrange(``ffind'',6720,6722) | inrange(``ffind'',6723,6723) | inrange(``ffind'',6724,6724) | inrange(``ffind'',6725,6725) | inrange(``ffind'',6726,6726) | inrange(``ffind'',6730,6733) | inrange(``ffind'',6740,6779) | inrange(``ffind'',6790,6791) | inrange(``ffind'',6792,6792) | inrange(``ffind'',6793,6793) | inrange(``ffind'',6794,6794) | inrange(``ffind'',6795,6795) | inrange(``ffind'',6798,6798) | inrange(``ffind'',6799,6799)
		qui replace `newvar'=48 if missing(`newvar') & ~missing(``ffind'')

		}
	else if ``ftyp''==49 {
		label define `newvar' 1 "Agriculture" 2 "Food Products" 3 "Candy & Soda" 4 "Beer & Liquor" 5 "Tobacco Products" 6 "Recreation" 7 "Entertainment" 8 "Printing and Publishing" 9 "Consumer Goods" 10 "Apparel" 11 "Healthcare" 12 "Medical Equipment" 13 "Pharmaceutical Products" 14 "Chemicals" 15 "Rubber and Plastic Products" 16 "Textiles" 17 "Construction Materials" 18 "Construction" 19 "Steel Works Etc" 20 "Fabricated Products" 21 "Machinery" 22 "Electrical Equipment" 23 "Automobiles and Trucks" 24 "Aircraft" 25 "Shipbuilding, Railroad Equipment" 26 "Defense" 27 "Precious Metals" 28 "Non-Metallic and Industrial Metal Mining" 29 "Coal" 30 "Petroleum and Natural Gas" 31 "Utilities" 32 "Communication" 33 "Personal Services" 34 "Business Services" 35 "Computer Hardware" 36 "Computer Software" 37 "Electronic Equipment" 38 "Measuring and Control Equipment" 39 "Business Supplies" 40 "Shipping Containers" 41 "Transportation" 42 "Wholesale" 43 "Retail" 44 "Restaraunts, Hotels, Motels" 45 "Banking" 46 "Insurance" 47 "Real Estate" 48 "Trading" 49 "Almost Nothing"
		label values `newvar' `newvar'

		qui replace `newvar'=1 if inrange(``ffind'',100,199) | inrange(``ffind'',200,299) | inrange(``ffind'',700,799) | inrange(``ffind'',910,919) | inrange(``ffind'',2048,2048)
		qui replace `newvar'=2 if inrange(``ffind'',2000,2009) | inrange(``ffind'',2010,2019) | inrange(``ffind'',2020,2029) | inrange(``ffind'',2030,2039) | inrange(``ffind'',2040,2046) | inrange(``ffind'',2050,2059) | inrange(``ffind'',2060,2063) | inrange(``ffind'',2070,2079) | inrange(``ffind'',2090,2092) | inrange(``ffind'',2095,2095) | inrange(``ffind'',2098,2099)
		qui replace `newvar'=3 if inrange(``ffind'',2064,2068) | inrange(``ffind'',2086,2086) | inrange(``ffind'',2087,2087) | inrange(``ffind'',2096,2096) | inrange(``ffind'',2097,2097)
		qui replace `newvar'=4 if inrange(``ffind'',2080,2080) | inrange(``ffind'',2082,2082) | inrange(``ffind'',2083,2083) | inrange(``ffind'',2084,2084) | inrange(``ffind'',2085,2085)
		qui replace `newvar'=5 if inrange(``ffind'',2100,2199)
		qui replace `newvar'=6 if inrange(``ffind'',920,999) | inrange(``ffind'',3650,3651) | inrange(``ffind'',3652,3652) | inrange(``ffind'',3732,3732) | inrange(``ffind'',3930,3931) | inrange(``ffind'',3940,3949)
		qui replace `newvar'=7 if inrange(``ffind'',7800,7829) | inrange(``ffind'',7830,7833) | inrange(``ffind'',7840,7841) | inrange(``ffind'',7900,7900) | inrange(``ffind'',7910,7911) | inrange(``ffind'',7920,7929) | inrange(``ffind'',7930,7933) | inrange(``ffind'',7940,7949) | inrange(``ffind'',7980,7980) | inrange(``ffind'',7990,7999)
		qui replace `newvar'=8 if inrange(``ffind'',2700,2709) | inrange(``ffind'',2710,2719) | inrange(``ffind'',2720,2729) | inrange(``ffind'',2730,2739) | inrange(``ffind'',2740,2749) | inrange(``ffind'',2770,2771) | inrange(``ffind'',2780,2789) | inrange(``ffind'',2790,2799)
		qui replace `newvar'=9 if inrange(``ffind'',2047,2047) | inrange(``ffind'',2391,2392) | inrange(``ffind'',2510,2519) | inrange(``ffind'',2590,2599) | inrange(``ffind'',2840,2843) | inrange(``ffind'',2844,2844) | inrange(``ffind'',3160,3161) | inrange(``ffind'',3170,3171) | inrange(``ffind'',3172,3172) | inrange(``ffind'',3190,3199) | inrange(``ffind'',3229,3229) | inrange(``ffind'',3260,3260) | inrange(``ffind'',3262,3263) | inrange(``ffind'',3269,3269) | inrange(``ffind'',3230,3231) | inrange(``ffind'',3630,3639) | inrange(``ffind'',3750,3751) | inrange(``ffind'',3800,3800) | inrange(``ffind'',3860,3861) | inrange(``ffind'',3870,3873) | inrange(``ffind'',3910,3911) | inrange(``ffind'',3914,3914) | inrange(``ffind'',3915,3915) | inrange(``ffind'',3960,3962) | inrange(``ffind'',3991,3991) | inrange(``ffind'',3995,3995)
		qui replace `newvar'=10 if inrange(``ffind'',2300,2390) | inrange(``ffind'',3020,3021) | inrange(``ffind'',3100,3111) | inrange(``ffind'',3130,3131) | inrange(``ffind'',3140,3149) | inrange(``ffind'',3150,3151) | inrange(``ffind'',3963,3965)
		qui replace `newvar'=11 if inrange(``ffind'',8000,8099)
		qui replace `newvar'=12 if inrange(``ffind'',3693,3693) | inrange(``ffind'',3840,3849) | inrange(``ffind'',3850,3851)
		qui replace `newvar'=13 if inrange(``ffind'',2830,2830) | inrange(``ffind'',2831,2831) | inrange(``ffind'',2833,2833) | inrange(``ffind'',2834,2834) | inrange(``ffind'',2835,2835) | inrange(``ffind'',2836,2836)
		qui replace `newvar'=14 if inrange(``ffind'',2800,2809) | inrange(``ffind'',2810,2819) | inrange(``ffind'',2820,2829) | inrange(``ffind'',2850,2859) | inrange(``ffind'',2860,2869) | inrange(``ffind'',2870,2879) | inrange(``ffind'',2890,2899)
		qui replace `newvar'=15 if inrange(``ffind'',3031,3031) | inrange(``ffind'',3041,3041) | inrange(``ffind'',3050,3053) | inrange(``ffind'',3060,3069) | inrange(``ffind'',3070,3079) | inrange(``ffind'',3080,3089) | inrange(``ffind'',3090,3099)
		qui replace `newvar'=16 if inrange(``ffind'',2200,2269) | inrange(``ffind'',2270,2279) | inrange(``ffind'',2280,2284) | inrange(``ffind'',2290,2295) | inrange(``ffind'',2297,2297) | inrange(``ffind'',2298,2298) | inrange(``ffind'',2299,2299) | inrange(``ffind'',2393,2395) | inrange(``ffind'',2397,2399)
		qui replace `newvar'=17 if inrange(``ffind'',800,899) | inrange(``ffind'',2400,2439) | inrange(``ffind'',2450,2459) | inrange(``ffind'',2490,2499) | inrange(``ffind'',2660,2661) | inrange(``ffind'',2950,2952) | inrange(``ffind'',3200,3200) | inrange(``ffind'',3210,3211) | inrange(``ffind'',3240,3241) | inrange(``ffind'',3250,3259) | inrange(``ffind'',3261,3261) | inrange(``ffind'',3264,3264) | inrange(``ffind'',3270,3275) | inrange(``ffind'',3280,3281) | inrange(``ffind'',3290,3293) | inrange(``ffind'',3295,3299) | inrange(``ffind'',3420,3429) | inrange(``ffind'',3430,3433) | inrange(``ffind'',3440,3441) | inrange(``ffind'',3442,3442) | inrange(``ffind'',3446,3446) | inrange(``ffind'',3448,3448) | inrange(``ffind'',3449,3449) | inrange(``ffind'',3450,3451) | inrange(``ffind'',3452,3452) | inrange(``ffind'',3490,3499) | inrange(``ffind'',3996,3996)
		qui replace `newvar'=18 if inrange(``ffind'',1500,1511) | inrange(``ffind'',1520,1529) | inrange(``ffind'',1530,1539) | inrange(``ffind'',1540,1549) | inrange(``ffind'',1600,1699) | inrange(``ffind'',1700,1799)
		qui replace `newvar'=19 if inrange(``ffind'',3300,3300) | inrange(``ffind'',3310,3317) | inrange(``ffind'',3320,3325) | inrange(``ffind'',3330,3339) | inrange(``ffind'',3340,3341) | inrange(``ffind'',3350,3357) | inrange(``ffind'',3360,3369) | inrange(``ffind'',3370,3379) | inrange(``ffind'',3390,3399)
		qui replace `newvar'=20 if inrange(``ffind'',3400,3400) | inrange(``ffind'',3443,3443) | inrange(``ffind'',3444,3444) | inrange(``ffind'',3460,3469) | inrange(``ffind'',3470,3479)
		qui replace `newvar'=21 if inrange(``ffind'',3510,3519) | inrange(``ffind'',3520,3529) | inrange(``ffind'',3530,3530) | inrange(``ffind'',3531,3531) | inrange(``ffind'',3532,3532) | inrange(``ffind'',3533,3533) | inrange(``ffind'',3534,3534) | inrange(``ffind'',3535,3535) | inrange(``ffind'',3536,3536) | inrange(``ffind'',3538,3538) | inrange(``ffind'',3540,3549) | inrange(``ffind'',3550,3559) | inrange(``ffind'',3560,3569) | inrange(``ffind'',3580,3580) | inrange(``ffind'',3581,3581) | inrange(``ffind'',3582,3582) | inrange(``ffind'',3585,3585) | inrange(``ffind'',3586,3586) | inrange(``ffind'',3589,3589) | inrange(``ffind'',3590,3599)
		qui replace `newvar'=22 if inrange(``ffind'',3600,3600) | inrange(``ffind'',3610,3613) | inrange(``ffind'',3620,3621) | inrange(``ffind'',3623,3629) | inrange(``ffind'',3640,3644) | inrange(``ffind'',3645,3645) | inrange(``ffind'',3646,3646) | inrange(``ffind'',3648,3649) | inrange(``ffind'',3660,3660) | inrange(``ffind'',3690,3690) | inrange(``ffind'',3691,3692) | inrange(``ffind'',3699,3699)
		qui replace `newvar'=23 if inrange(``ffind'',2296,2296) | inrange(``ffind'',2396,2396) | inrange(``ffind'',3010,3011) | inrange(``ffind'',3537,3537) | inrange(``ffind'',3647,3647) | inrange(``ffind'',3694,3694) | inrange(``ffind'',3700,3700) | inrange(``ffind'',3710,3710) | inrange(``ffind'',3711,3711) | inrange(``ffind'',3713,3713) | inrange(``ffind'',3714,3714) | inrange(``ffind'',3715,3715) | inrange(``ffind'',3716,3716) | inrange(``ffind'',3792,3792) | inrange(``ffind'',3790,3791) | inrange(``ffind'',3799,3799)
		qui replace `newvar'=24 if inrange(``ffind'',3720,3720) | inrange(``ffind'',3721,3721) | inrange(``ffind'',3723,3724) | inrange(``ffind'',3725,3725) | inrange(``ffind'',3728,3729)
		qui replace `newvar'=25 if inrange(``ffind'',3730,3731) | inrange(``ffind'',3740,3743)
		qui replace `newvar'=26 if inrange(``ffind'',3760,3769) | inrange(``ffind'',3795,3795) | inrange(``ffind'',3480,3489)
		qui replace `newvar'=27 if inrange(``ffind'',1040,1049)
		qui replace `newvar'=28 if inrange(``ffind'',1000,1009) | inrange(``ffind'',1010,1019) | inrange(``ffind'',1020,1029) | inrange(``ffind'',1030,1039) | inrange(``ffind'',1050,1059) | inrange(``ffind'',1060,1069) | inrange(``ffind'',1070,1079) | inrange(``ffind'',1080,1089) | inrange(``ffind'',1090,1099) | inrange(``ffind'',1100,1119) | inrange(``ffind'',1400,1499)
		qui replace `newvar'=29 if inrange(``ffind'',1200,1299)
		qui replace `newvar'=30 if inrange(``ffind'',1300,1300) | inrange(``ffind'',1310,1319) | inrange(``ffind'',1320,1329) | inrange(``ffind'',1330,1339) | inrange(``ffind'',1370,1379) | inrange(``ffind'',1380,1380) | inrange(``ffind'',1381,1381) | inrange(``ffind'',1382,1382) | inrange(``ffind'',1389,1389) | inrange(``ffind'',2900,2912) | inrange(``ffind'',2990,2999)
		qui replace `newvar'=31 if inrange(``ffind'',4900,4900) | inrange(``ffind'',4910,4911) | inrange(``ffind'',4920,4922) | inrange(``ffind'',4923,4923) | inrange(``ffind'',4924,4925) | inrange(``ffind'',4930,4931) | inrange(``ffind'',4932,4932) | inrange(``ffind'',4939,4939) | inrange(``ffind'',4940,4942)
		qui replace `newvar'=32 if inrange(``ffind'',4800,4800) | inrange(``ffind'',4810,4813) | inrange(``ffind'',4820,4822) | inrange(``ffind'',4830,4839) | inrange(``ffind'',4840,4841) | inrange(``ffind'',4880,4889) | inrange(``ffind'',4890,4890) | inrange(``ffind'',4891,4891) | inrange(``ffind'',4892,4892) | inrange(``ffind'',4899,4899)
		qui replace `newvar'=33 if inrange(``ffind'',7020,7021) | inrange(``ffind'',7030,7033) | inrange(``ffind'',7200,7200) | inrange(``ffind'',7210,7212) | inrange(``ffind'',7214,7214) | inrange(``ffind'',7215,7216) | inrange(``ffind'',7217,7217) | inrange(``ffind'',7219,7219) | inrange(``ffind'',7220,7221) | inrange(``ffind'',7230,7231) | inrange(``ffind'',7240,7241) | inrange(``ffind'',7250,7251) | inrange(``ffind'',7260,7269) | inrange(``ffind'',7270,7290) | inrange(``ffind'',7291,7291) | inrange(``ffind'',7292,7299) | inrange(``ffind'',7395,7395) | inrange(``ffind'',7500,7500) | inrange(``ffind'',7520,7529) | inrange(``ffind'',7530,7539) | inrange(``ffind'',7540,7549) | inrange(``ffind'',7600,7600) | inrange(``ffind'',7620,7620) | inrange(``ffind'',7622,7622) | inrange(``ffind'',7623,7623) | inrange(``ffind'',7629,7629) | inrange(``ffind'',7630,7631) | inrange(``ffind'',7640,7641) | inrange(``ffind'',7690,7699) | inrange(``ffind'',8100,8199) | inrange(``ffind'',8200,8299) | inrange(``ffind'',8300,8399) | inrange(``ffind'',8400,8499) | inrange(``ffind'',8600,8699) | inrange(``ffind'',8800,8899) | inrange(``ffind'',7510,7515)
		qui replace `newvar'=34 if inrange(``ffind'',2750,2759) | inrange(``ffind'',3993,3993) | inrange(``ffind'',7218,7218) | inrange(``ffind'',7300,7300) | inrange(``ffind'',7310,7319) | inrange(``ffind'',7320,7329) | inrange(``ffind'',7330,7339) | inrange(``ffind'',7340,7342) | inrange(``ffind'',7349,7349) | inrange(``ffind'',7350,7351) | inrange(``ffind'',7352,7352) | inrange(``ffind'',7353,7353) | inrange(``ffind'',7359,7359) | inrange(``ffind'',7360,7369) | inrange(``ffind'',7374,7374) | inrange(``ffind'',7376,7376) | inrange(``ffind'',7377,7377) | inrange(``ffind'',7378,7378) | inrange(``ffind'',7379,7379) | inrange(``ffind'',7380,7380) | inrange(``ffind'',7381,7382) | inrange(``ffind'',7383,7383) | inrange(``ffind'',7384,7384) | inrange(``ffind'',7385,7385) | inrange(``ffind'',7389,7390) | inrange(``ffind'',7391,7391) | inrange(``ffind'',7392,7392) | inrange(``ffind'',7393,7393) | inrange(``ffind'',7394,7394) | inrange(``ffind'',7396,7396) | inrange(``ffind'',7397,7397) | inrange(``ffind'',7399,7399) | inrange(``ffind'',7519,7519) | inrange(``ffind'',8700,8700) | inrange(``ffind'',8710,8713) | inrange(``ffind'',8720,8721) | inrange(``ffind'',8730,8734) | inrange(``ffind'',8740,8748) | inrange(``ffind'',8900,8910) | inrange(``ffind'',8911,8911) | inrange(``ffind'',8920,8999) | inrange(``ffind'',4220,4229)
		qui replace `newvar'=35 if inrange(``ffind'',3570,3579) | inrange(``ffind'',3680,3680) | inrange(``ffind'',3681,3681) | inrange(``ffind'',3682,3682) | inrange(``ffind'',3683,3683) | inrange(``ffind'',3684,3684) | inrange(``ffind'',3685,3685) | inrange(``ffind'',3686,3686) | inrange(``ffind'',3687,3687) | inrange(``ffind'',3688,3688) | inrange(``ffind'',3689,3689) | inrange(``ffind'',3695,3695)
		qui replace `newvar'=36 if inrange(``ffind'',7370,7372) | inrange(``ffind'',7375,7375) | inrange(``ffind'',7373,7373)
		qui replace `newvar'=37 if inrange(``ffind'',3622,3622) | inrange(``ffind'',3661,3661) | inrange(``ffind'',3662,3662) | inrange(``ffind'',3663,3663) | inrange(``ffind'',3664,3664) | inrange(``ffind'',3665,3665) | inrange(``ffind'',3666,3666) | inrange(``ffind'',3669,3669) | inrange(``ffind'',3670,3679) | inrange(``ffind'',3810,3810) | inrange(``ffind'',3812,3812)
		qui replace `newvar'=38 if inrange(``ffind'',3811,3811) | inrange(``ffind'',3820,3820) | inrange(``ffind'',3821,3821) | inrange(``ffind'',3822,3822) | inrange(``ffind'',3823,3823) | inrange(``ffind'',3824,3824) | inrange(``ffind'',3825,3825) | inrange(``ffind'',3826,3826) | inrange(``ffind'',3827,3827) | inrange(``ffind'',3829,3829) | inrange(``ffind'',3830,3839)
		qui replace `newvar'=39 if inrange(``ffind'',2520,2549) | inrange(``ffind'',2600,2639) | inrange(``ffind'',2670,2699) | inrange(``ffind'',2760,2761) | inrange(``ffind'',3950,3955)
		qui replace `newvar'=40 if inrange(``ffind'',2440,2449) | inrange(``ffind'',2640,2659) | inrange(``ffind'',3220,3221) | inrange(``ffind'',3410,3412)
		qui replace `newvar'=41 if inrange(``ffind'',4000,4013) | inrange(``ffind'',4040,4049) | inrange(``ffind'',4100,4100) | inrange(``ffind'',4110,4119) | inrange(``ffind'',4120,4121) | inrange(``ffind'',4130,4131) | inrange(``ffind'',4140,4142) | inrange(``ffind'',4150,4151) | inrange(``ffind'',4170,4173) | inrange(``ffind'',4190,4199) | inrange(``ffind'',4200,4200) | inrange(``ffind'',4210,4219) | inrange(``ffind'',4230,4231) | inrange(``ffind'',4240,4249) | inrange(``ffind'',4400,4499) | inrange(``ffind'',4500,4599) | inrange(``ffind'',4600,4699) | inrange(``ffind'',4700,4700) | inrange(``ffind'',4710,4712) | inrange(``ffind'',4720,4729) | inrange(``ffind'',4730,4739) | inrange(``ffind'',4740,4749) | inrange(``ffind'',4780,4780) | inrange(``ffind'',4782,4782) | inrange(``ffind'',4783,4783) | inrange(``ffind'',4784,4784) | inrange(``ffind'',4785,4785) | inrange(``ffind'',4789,4789)
		qui replace `newvar'=42 if inrange(``ffind'',5000,5000) | inrange(``ffind'',5010,5015) | inrange(``ffind'',5020,5023) | inrange(``ffind'',5030,5039) | inrange(``ffind'',5040,5042) | inrange(``ffind'',5043,5043) | inrange(``ffind'',5044,5044) | inrange(``ffind'',5045,5045) | inrange(``ffind'',5046,5046) | inrange(``ffind'',5047,5047) | inrange(``ffind'',5048,5048) | inrange(``ffind'',5049,5049) | inrange(``ffind'',5050,5059) | inrange(``ffind'',5060,5060) | inrange(``ffind'',5063,5063) | inrange(``ffind'',5064,5064) | inrange(``ffind'',5065,5065) | inrange(``ffind'',5070,5078) | inrange(``ffind'',5080,5080) | inrange(``ffind'',5081,5081) | inrange(``ffind'',5082,5082) | inrange(``ffind'',5083,5083) | inrange(``ffind'',5084,5084) | inrange(``ffind'',5085,5085) | inrange(``ffind'',5086,5087) | inrange(``ffind'',5088,5088) | inrange(``ffind'',5090,5090) | inrange(``ffind'',5091,5092) | inrange(``ffind'',5093,5093) | inrange(``ffind'',5094,5094) | inrange(``ffind'',5099,5099) | inrange(``ffind'',5100,5100) | inrange(``ffind'',5110,5113) | inrange(``ffind'',5120,5122) | inrange(``ffind'',5130,5139) | inrange(``ffind'',5140,5149) | inrange(``ffind'',5150,5159) | inrange(``ffind'',5160,5169) | inrange(``ffind'',5170,5172) | inrange(``ffind'',5180,5182) | inrange(``ffind'',5190,5199)
		qui replace `newvar'=43 if inrange(``ffind'',5200,5200) | inrange(``ffind'',5210,5219) | inrange(``ffind'',5220,5229) | inrange(``ffind'',5230,5231) | inrange(``ffind'',5250,5251) | inrange(``ffind'',5260,5261) | inrange(``ffind'',5270,5271) | inrange(``ffind'',5300,5300) | inrange(``ffind'',5310,5311) | inrange(``ffind'',5320,5320) | inrange(``ffind'',5330,5331) | inrange(``ffind'',5334,5334) | inrange(``ffind'',5340,5349) | inrange(``ffind'',5390,5399) | inrange(``ffind'',5400,5400) | inrange(``ffind'',5410,5411) | inrange(``ffind'',5412,5412) | inrange(``ffind'',5420,5429) | inrange(``ffind'',5430,5439) | inrange(``ffind'',5440,5449) | inrange(``ffind'',5450,5459) | inrange(``ffind'',5460,5469) | inrange(``ffind'',5490,5499) | inrange(``ffind'',5500,5500) | inrange(``ffind'',5510,5529) | inrange(``ffind'',5530,5539) | inrange(``ffind'',5540,5549) | inrange(``ffind'',5550,5559) | inrange(``ffind'',5560,5569) | inrange(``ffind'',5570,5579) | inrange(``ffind'',5590,5599) | inrange(``ffind'',5600,5699) | inrange(``ffind'',5700,5700) | inrange(``ffind'',5710,5719) | inrange(``ffind'',5720,5722) | inrange(``ffind'',5730,5733) | inrange(``ffind'',5734,5734) | inrange(``ffind'',5735,5735) | inrange(``ffind'',5736,5736) | inrange(``ffind'',5750,5799) | inrange(``ffind'',5900,5900) | inrange(``ffind'',5910,5912) | inrange(``ffind'',5920,5929) | inrange(``ffind'',5930,5932) | inrange(``ffind'',5940,5940) | inrange(``ffind'',5941,5941) | inrange(``ffind'',5942,5942) | inrange(``ffind'',5943,5943) | inrange(``ffind'',5944,5944) | inrange(``ffind'',5945,5945) | inrange(``ffind'',5946,5946) | inrange(``ffind'',5947,5947) | inrange(``ffind'',5948,5948) | inrange(``ffind'',5949,5949) | inrange(``ffind'',5950,5959) | inrange(``ffind'',5960,5969) | inrange(``ffind'',5970,5979) | inrange(``ffind'',5980,5989) | inrange(``ffind'',5990,5990) | inrange(``ffind'',5992,5992) | inrange(``ffind'',5993,5993) | inrange(``ffind'',5994,5994) | inrange(``ffind'',5995,5995) | inrange(``ffind'',5999,5999)
		qui replace `newvar'=44 if inrange(``ffind'',5800,5819) | inrange(``ffind'',5820,5829) | inrange(``ffind'',5890,5899) | inrange(``ffind'',7000,7000) | inrange(``ffind'',7010,7019) | inrange(``ffind'',7040,7049) | inrange(``ffind'',7213,7213)
		qui replace `newvar'=45 if inrange(``ffind'',6000,6000) | inrange(``ffind'',6010,6019) | inrange(``ffind'',6020,6020) | inrange(``ffind'',6021,6021) | inrange(``ffind'',6022,6022) | inrange(``ffind'',6023,6024) | inrange(``ffind'',6025,6025) | inrange(``ffind'',6026,6026) | inrange(``ffind'',6027,6027) | inrange(``ffind'',6028,6029) | inrange(``ffind'',6030,6036) | inrange(``ffind'',6040,6059) | inrange(``ffind'',6060,6062) | inrange(``ffind'',6080,6082) | inrange(``ffind'',6090,6099) | inrange(``ffind'',6100,6100) | inrange(``ffind'',6110,6111) | inrange(``ffind'',6112,6113) | inrange(``ffind'',6120,6129) | inrange(``ffind'',6130,6139) | inrange(``ffind'',6140,6149) | inrange(``ffind'',6150,6159) | inrange(``ffind'',6160,6169) | inrange(``ffind'',6170,6179) | inrange(``ffind'',6190,6199)
		qui replace `newvar'=46 if inrange(``ffind'',6300,6300) | inrange(``ffind'',6310,6319) | inrange(``ffind'',6320,6329) | inrange(``ffind'',6330,6331) | inrange(``ffind'',6350,6351) | inrange(``ffind'',6360,6361) | inrange(``ffind'',6370,6379) | inrange(``ffind'',6390,6399) | inrange(``ffind'',6400,6411)
		qui replace `newvar'=47 if inrange(``ffind'',6500,6500) | inrange(``ffind'',6510,6510) | inrange(``ffind'',6512,6512) | inrange(``ffind'',6513,6513) | inrange(``ffind'',6514,6514) | inrange(``ffind'',6515,6515) | inrange(``ffind'',6517,6519) | inrange(``ffind'',6520,6529) | inrange(``ffind'',6530,6531) | inrange(``ffind'',6532,6532) | inrange(``ffind'',6540,6541) | inrange(``ffind'',6550,6553) | inrange(``ffind'',6590,6599) | inrange(``ffind'',6610,6611)
		qui replace `newvar'=48 if inrange(``ffind'',6200,6299) | inrange(``ffind'',6700,6700) | inrange(``ffind'',6710,6719) | inrange(``ffind'',6720,6722) | inrange(``ffind'',6723,6723) | inrange(``ffind'',6724,6724) | inrange(``ffind'',6725,6725) | inrange(``ffind'',6726,6726) | inrange(``ffind'',6730,6733) | inrange(``ffind'',6740,6779) | inrange(``ffind'',6790,6791) | inrange(``ffind'',6792,6792) | inrange(``ffind'',6793,6793) | inrange(``ffind'',6794,6794) | inrange(``ffind'',6795,6795) | inrange(``ffind'',6798,6798) | inrange(``ffind'',6799,6799)
		qui replace `newvar'=49 if missing(`newvar') & ~missing(``ffind'')

		}
	else {
		di as error "Type must be 5, 10, 12, 17, 30, 38, 48 or 49"
		exit 111
		}


end
