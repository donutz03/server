
cd "C:\Users\korisnik\Google Drive\_freelance\21_07_26_db_ionut"

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
keep rf Date //keep only the data and risk free rate
replace rf = rf / 100 //to have it as decimal, consistent with other return variables
save ff, replace

* at this step, I went to WRDS and collected data from two sections
* 1) total assets, market value, and total equity come from Compustat database
* 2) daily stock prices are obtained from CCM (CRSP Compustat Merged database); Why? Because we have a list of tickers and hence we must get the data from CCM (normally stock prices are obtained directly from CRSP but CRSP identifier is PERMNO but we identify S&P firms by TICKER)

* prepare the compustat file for merging
use senad_ionut_210726_comp, clear
drop indfmt consol popsrc datafmt curcd costat //drop some redundant variables
rename fyear year //rename
save senad_ionut_210726_comp_edited, replace
// the data above is uniquely identified at gvkey year level, meaning that one line of data corresponds to one gvkey/year combination

* combine CRSP and Compustat data
use senad_ionut_210726_ccm, clear
drop cheqv trfd iid  //drop some redundant variables
generate year = year(datadate) //extract the year of the datadate variable- to be used for merging
rename GVKEY gvkey //make the gvkey variable name consistent in the two datasets
merge m:1 gvkey year using senad_ionut_210726_comp_edited, keep(match) nogen
//m:1 stands for many-to-one where many means that the data in memory (stock prices data) has multiple records at gvkey/year level while one means that in the using data (annual data on total assets and market value) there is only one line per gvkey/year observation
//keep(match) means keep only observations that have data in both files (master and using)
//nogen means do not generate the _merge variable which is always generated as part of the merging process

* merge in S&P return data
rename datadate Date //rename the variable to match its name in the SP500 dataset downloaded from WRDS
merge m:1 Date using SP500, keep(match) nogen

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

//ssc install rangestat
rangestat (reg) r_ew sprtrn, interval(LPERMNO 0 0)
//rangestat command repeats the CAPM regression for each firm (as specified in the interval option) while regressions stock return on the S&P 500 index return* estimation window tag
drop reg_r2 reg_adj_r2 se_sprtrn se_cons //drop the redundant variables
drop if reg_nobs < 146 //drop cases where regression is estimated using periods shorter than 6 months (150 trading days)
codebook LPERMNO //this leaves us with 468 firms

gen r_pred = b_cons + b_sprtrn * sprtrn //generate a CAPM-based prediction of stock return
gen ar = r - r_pred if ew != 1 //finally, generate abnormal return as difference between actual stock return and CAPM-based prediction (note: generate the variable only for the testing period (after estimation window has ended))

keep gvkey LPERMNO Date cshoc sic tic at ceq ch mkvalt ew ar //keep the essential variables
drop if ew == 1 //drop data for the estimation window, i.e. keep only the data after it 

save AR, replace

*-------------------------------------------------------------------------------
* added on 21 09 26: event time plot around Dec 11th
use AR, clear

* generate time variable equals zero at event data, -1, -2 etc before that, and 1, 2 etc after that
bys LPERMNO (Date): g n = _n
g temp_n_at_event = n if Date == td(11dec2020)
bys LPERMNO: egen n_at_event = min(temp_n_at_event)
g t = n - n_at_event
drop n n_at_event temp_n_at_event

collapse (mean) ar, by(t)
twoway (line ar t) if inrange(t,-5,5), ytitle(Mean Abnormal Return) yline(0) ylabel(-0.01(0.005)0.01, nogrid) xtitle(Time Around the Event) xlabel(#11) title(Mean Abnormal Returns Around the Event Date) graphregion(fcolor(white))
graph export graph1.png, as(png) replace

* event time plot around Dec 18th
use AR, clear

* generate time variable equals zero at event data, -1, -2 etc before that, and 1, 2 etc after that
bys LPERMNO (Date): g n = _n
g temp_n_at_event = n if Date == td(18dec2020)
bys LPERMNO: egen n_at_event = min(temp_n_at_event)
g t = n - n_at_event
drop n n_at_event temp_n_at_event

collapse (mean) ar, by(t)
twoway (line ar t)
twoway (line ar t) if inrange(t,-5,5), ytitle(Mean Abnormal Return) yline(0) ylabel(-0.01(0.005)0.01, nogrid) xtitle(Time Around the Event) xlabel(#11) title(Mean Abnormal Returns Around the Event Date) graphregion(fcolor(white))
graph export graph2.png, as(png) replace

* event time plot around both announcement dates
use AR, clear
collapse (mean) ar, by(Date)
twoway (line ar Date)
twoway (line ar Date) if inrange(Date,td(04dec2020),td(25dec2020)), ytitle(Mean Abnormal Return) yline(0) ylabel(-0.01(0.005)0.01, nogrid) xtitle(Time Around the Event) xlabel(#11, angle(45)) title(Mean Abnormal Returns Around the Event Date) graphregion(fcolor(white)) xline(22260 22267, lpattern(dash) lcolor(maroon)) text(0.01 22263 "Announcement 1") text(0.01 22270 "Announcement 2")
graph export graph3.png, as(png) replace

*-------------------------------------------------------------------------------
* Event Date: Dec 11
use AR, clear

* generate time variable equals zero at event data, -1, -2 etc before that, and 1, 2 etc after that
sort LPERMNO Date
browse LPERMNO Date 
bysort LPERMNO (Date): generate n = _n //generate n variable which simply counts observations for each firm separately (while data is sorted on Date)
generate temp_n_at_event = n if Date == td(11dec2020) //identify n value for which Date equals Dec 11th
bysort LPERMNO: egen n_at_event = min(temp_n_at_event) //make n_at_event available for all records of a firm instead of having it in a single line only
generate t = n - n_at_event //finaly, create time variable as difference between n and n_at_event
drop n n_at_event temp_n_at_event //drop redundant variables

generate period1 = inrange(t,0,0) //tag period1 which spans dates as in the parenthesis (0,0) so that we can cumulate returns over that period
generate period2 = inrange(t,0,1)
generate period3 = inrange(t,-1,1)
generate period4 = inrange(t,-3,3)
generate period5 = inrange(t,-5,5)
generate period6 = inrange(t,0,5)
generate period7 = inrange(t,0,3)

bysort LPERMNO: egen car1 = sum(ar) if period1 == 1
bysort LPERMNO: egen car2 = sum(ar) if period2 == 1
bysort LPERMNO: egen car3 = sum(ar) if period3 == 1
bysort LPERMNO: egen car4 = sum(ar) if period4 == 1
bysort LPERMNO: egen car5 = sum(ar) if period5 == 1
bysort LPERMNO: egen car6 = sum(ar) if period6 == 1
bysort LPERMNO: egen car7 = sum(ar) if period7 == 1

/* the loop below does the same summation of abrnomal returns as the code above does	
forvalues i = 1/7 {
	bysort LPERMNO: egen car`i' = sum(ar) if period`i' == 1
}
*/
keep LPERMNO cshoc sic at ceq ch mkvalt car* //keep the necessary variables
collapse (firstnm) cshoc sic at ceq ch mkvalt car*, by(LPERMNO)

label var car1 "CAAR(0,0)"
label var car2 "CAAR(0,1)"
label var car3 "CAAR(-1,1)"
label var car4 "CAAR(-3,3)"
label var car5 "CAAR(-5,5)"
label var car6 "CAAR(0,5)"
label var car7 "CAAR(0,3)"

//ssc install asdoc
* run t-tests for all 7 CAR to test if they are significantly different than 0
* also use the asdoc command to export the results to a Word document
asdoc ttest car1 == 0, save(results/CAAR.doc) label replace
forv i = 2/7 {
	asdoc ttest car`i' == 0, save(results/CAAR.doc) label rowappend
}

* added on 21 09 25
* sic variable is currently a string and we need to have it as numeric
destring sic, replace
//ssc install ffind
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
forvalues i = 1/7 {
	eststo model`i': regress car`i' ln_at i.ff12
}
* use the esttab command below to export the results to an rtf file (a type of Word document)
esttab model* using results/regressions_dec11.rtf, replace label noomit nobase b(%4.3f) se(%3.2f) modelwidth(8)

*-------------------------------------------------------------------------------
* Dec 18
use AR, clear

bys LPERMNO (Date): g n = _n
g temp_n_at_event = n if Date == td(18dec2020)
bys LPERMNO: egen n_at_event = min(temp_n_at_event)
g t = n - n_at_event
drop n n_at_event temp_n_at_event

generate period1 = inrange(t,0,0)
generate period2 = inrange(t,0,1)
generate period3 = inrange(t,-1,1)
generate period4 = inrange(t,-3,3)
generate period5 = inrange(t,-5,5)
generate period6 = inrange(t,0,5)
generate period7 = inrange(t,0,3)

forv i = 1/7 {
	bys LPERMNO: egen car`i' = sum(ar) if period`i' == 1
}

keep LPERMNO cshoc sic at ceq ch mkvalt car*
collapse (firstnm) cshoc sic at ceq ch mkvalt car*, by(LPERMNO)

label var car1 "CAAR(0,0)"
label var car2 "CAAR(0,1)"
label var car3 "CAAR(-1,1)"
label var car4 "CAAR(-3,3)"
label var car5 "CAAR(-5,5)"
label var car6 "CAAR(0,5)"
label var car7 "CAAR(0,3)"

//ssc install asdoc
asdoc ttest car1 == 0, save(results/CAAR.doc) label append
forv i = 2/7 {
	asdoc ttest car`i' == 0, save(results/CAAR.doc) label rowappend
}

* added on 21 09 25
destring sic, replace
ffind sic, newvar(ff12) type(12)

* generate ln of total assets variable, make histograms of both
hist at, xtitle(Total Assets) graphregion(fcolor(white))
graph export at.png, as(png) replace
generate ln_at = ln(at)
label variable ln_at "Natural Logarithm of Total Assets"
hist ln_at, xtitle(Natural Logarithm of Total Assets) graphregion(fcolor(white))
graph export ln_at.png, as(png) replace

forvalues i = 1/7 {
	eststo model`i': regress car`i' ln_at i.ff12
}
esttab model* using results/regressions_dec18.rtf, replace label noomit nobase b(%4.3f) se(%3.2f) modelwidth(8)
