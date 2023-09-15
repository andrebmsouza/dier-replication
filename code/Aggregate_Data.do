/// This script aggregates monthly, weekly and daily data to use for prediction.

dis "Aggregating data for prediction..."
clear
use "../data/Monthly_Variables.dta"
merge 1:1 PERMNO ym  using "../data/Weekly_Variables.dta"
keep if _merge==3
drop _merge
merge 1:1 PERMNO ym  using "../data/Daily_Variables.dta"
keep if _merge==3
drop _merge

xtset PERMNO ym, monthly // Set panel structure

// We drop PRet and NRet to redefine them so that their sum is 1.
// Note: We consider runs of strictly positive or negative, but we predict weakly negative.
// Again, we do this so that there are only two categories for prediction (Positive or Negative).

drop PRet NRet
gen PRet = RET > 0
gen NRet = RET <= 0

xtset PERMNO ym, monthly

// Variables were created contemporaneously, now we lag them so that
// MND1 is 1 if the previous month return was negative
// WND1 is 1 if the last week of the previous month had negative returns, and
// DPD1 is 1 if the last day of the previous month had negative returns.
 
forvalues j=1/12{
	gen MND`j'= l1.ND`j'Monthly
	gen MPD`j'= l1.PD`j'Monthly
	gen WND`j'= l1.ND`j'Weekly
	gen WPD`j'= l1.PD`j'Weekly
	gen DND`j'= l1.ND`j'Daily
	gen DPD`j'= l1.PD`j'Daily
}

// We then generate the lenght of runs monthly, weekly and daily returns
egen MN = rowtotal(MND1 MND2 MND3 MND4 MND5 MND6 MND7 MND8 MND9 MND10 MND11 MND12)
egen MP = rowtotal(MPD1 MPD2 MPD3 MND4 MPD5 MPD6 MPD7 MPD8 MPD9 MPD10 MPD11 MPD12)
egen WN = rowtotal(WND1 WND2 WND3 WND4 WND5 WND6 WND7 WND8 WND9 WND10 WND11 WND12)
egen WP = rowtotal(WPD1 WPD2 WPD3 WND4 WPD5 WPD6 WPD7 WPD8 WPD9 WPD10 WPD11 WPD12)
egen DN = rowtotal(DND1 DND2 DND3 DND4 DND5 DND6 DND7 DND8 DND9 DND10 DND11 DND12)
egen DP = rowtotal(DPD1 DPD2 DPD3 DND4 DPD5 DPD6 DPD7 DPD8 DPD9 DPD10 DPD11 DPD12)

// And the same for Idiosyncratic volatility
gen IVL = l1.IV^2
***********************************************

// We then impose some regularity conditions
bys PERMNO: gen NT=_N
gen SampleEst = 1 if (abs(RET) > 0) & (NT > 24) & (MN!=MP) & (WN!=WP) & (DN!=DP)
/// We impose the following conditions on the ESTIMATION sample (not PREDICTION):
/// 1: We dont use 0 returns on the left hand side, but we generate predictions for them.
// We do this to keep the target variable a binary variable, as opposed to having 3 categories.
/// 2: We require at least 24 months of data for each company to be in the estimation sample.
/// 3: We require non zero returns for the last month, as well as for the last weeks and days of the last month.

// If there are any remaining missing returns, we drop them
drop if missing(RET)

// And we merge with Fama French data to get market returns
merge m:1 ym using "../data/inputs/FF_3F_Monthly.dta"
keep if _merge==3
drop _merge

xtset PERMNO ym, monthly // Recover panel structure
gen lag_market=l1.mktrf // lag market so that it can be used in predictive regressions

// We keep only firms for which we have the last 12 months of return.
drop if missing(MND12)
keep PRet MN WN DN MP WP DP lag_market IVL SampleEst ym PERMNO
save "../data/Prediction_Dataset.dta", replace
