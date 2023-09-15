/// This script prepares daily data for prediction.

dis "Starting Daily script..."
clear 
cd "../data/inputs"
use "CRSP_Daily.dta"

keep if SHRCD<=11 // Drop
replace RET=DLRET if DLRET !=. // Replace with delisting returns when available.
drop if missing(RET) // If returns are still missing, drop this row.
merge m:1 date using "Fama_French_Daily.dta" // Import risk free and factors from FF data
keep if _merge==3 // Keep only overlaps with FF data.
drop _merge

gen xret = RET - rf // generate excess returns on the risk free
sort PERMNO date, stable // sort by company date
by PERMNO: gen T =_n // generate a running index for each company
xtset PERMNO T, daily // define the panel
gen ym=mofd(date) // define yearmonth variables

//bys PERMNO ym: generate N=_N // Drop firms with less than 15 daily returns in a month
//drop if N<15

/// Daily CAPM Construction

bys PERMNO ym: egen av_xret = mean(xret) // average excess return per firm year
bys PERMNO ym: egen av_mktrf = mean(mktrf) // we take average market return per firm year to ensure matching firm/market observations.

gen Mex = xret - av_xret // (y - ybar)
gen Mmk = mktrf - av_mktrf // (x - xbar)
gen Mcross = Mex*Mmk //  (y - ybar)(x - xbar)
gen Mmk2 = Mmk^2 // (x - xbar)^2

// Construct sample averages by firm/year
by PERMNO ym: egen covariance = mean(Mcross)
by PERMNO ym: egen variance = mean(Mmk2) 
gen Beta_Daily = covariance/variance // Beta is cov(x,y)/var(x)
gen Alpha_Daily = av_xret - Beta_Daily*av_mktrf // Alpha is ybar - xbar*beta
gen CAPM_Residuals = xret - Alpha_Daily - Beta_Daily*av_mktrf // Construct CAPM residuals.

// Construct Idiosyncratic volatility
by PERMNO ym: egen IVar = mean(CAPM_Residuals^2) // Idiosyncratic Variance
gen IV = sqrt(IVar)

// Redefine the panel structure
xtset PERMNO T, daily

/// Construct Duration variables
gen NRet =  RET <0
gen PRet =  RET >0

////////////////////////////////////////////////////////////////////////////////
/////////////// Daily variables are constructed for the current month //////////
////////////////////////////////////////////////////////////////////////////////

// Start with current days return
gen ND1Daily = NRet
gen PD1Daily = PRet

forvalues i = 1/12{
  local j = `i' + 1
  generate ND`j'Daily = ND`i'Daily * l`i'.NRet // Example: ND2 is true if both ND1 is true AND l2.NRet is true
	generate PD`j'Daily = PD`i'Daily * l`i'.PRet // Same with Positive returns.
}

/// Organize variables to keep
keep PERMNO ym Beta_Daily Alpha_Daily IV ND*Daily PD*Daily
collapse (last) Beta_Daily Alpha_Daily IV ND*Daily PD*Daily, by(PERMNO ym)

/// Output dta file
save "../Daily_Variables.dta", replace
dis "Daily script done"
