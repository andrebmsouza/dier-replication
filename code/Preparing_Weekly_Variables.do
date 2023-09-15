/// This script prepares weekly data for prediction.
dis "Starting Weekly script..."
clear 
cd "../data/inputs"
use "CRSP_Daily.dta"

keep if SHRCD<=11 // Drop
replace RET=DLRET if DLRET !=. // Replace with delisting returns when available.
drop if missing(RET) // If returns are still missing, drop this row.
sort PERMNO date, stable // sort by company date
by PERMNO: gen T=_n // generate a running index for each company
xtset PERMNO T, daily // define the panel
generate ym = mofd(date) // define yearmonth variables
gen weeks = wofd(date) // generate weekmonthyear variables

//bys PERMNO ym: generate N =_N // Count the number of daily returns in a month this firm has
//drop if N < 15 // Drop months for which there is less than 15 days of trading.

/// Weekly data construction
gen lgret = ln(1+RET) // Weekly returns are aggregated log returns
collapse (sum) lgret (last) ym, by(PERMNO weeks)
gen RET = exp(lgret) - 1

xtset PERMNO weeks, weekly // Define panel structure
/// Construct Duration variables
gen NRet =  RET <0
gen PRet =  RET >0

// Start with current days return
gen ND1Weekly = NRet
gen PD1Weekly = PRet

forvalues i = 1/12{
  local j = `i' + 1
  generate ND`j'Weekly = ND`i'Weekly * l`i'.NRet // Example: ND2 is true if both ND1 is true AND l2.NRet is true
	generate PD`j'Weekly = PD`i'Weekly * l`i'.PRet // Same with Positive returns.
}


/// Organize variables to keep
keep PERMNO ym ND*Weekly PD*Weekly
collapse (last) ND*Weekly PD*Weekly, by(PERMNO ym)

/// Output dta file
save "../Weekly_Variables.dta", replace
dis "Weekly script done"
