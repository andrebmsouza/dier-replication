/// This script prepares monthly data for prediction.
dis "Starting Monthly script..."
clear 
cd "../data/inputs"
use "CRSP_Monthly.dta"

keep if SHRCD <= 11 // Drop
replace RET = DLRET if (DLRET!=.) & (DLRET!=.a) // Replace with delisting returns when available.
drop if missing(RET)

// Keep only NYSE, ASE, NASDAQ stocks
// EXCHCD, 1	New York Stock Exchange, 2	American Stock Exchange, 3	The Nasdaq Stock Market(SM)
drop if EXCHCD < 1 | EXCHCD > 3

gen ym = mofd(date) // Set monthly running variable
duplicates drop PERMNO ym, force // Drop duplicates in terms of PERMNO and ym.
merge m:1 ym using "FF_3F_Monthly.dta" // Merge FF3F Data
keep if _merge==3
xtset PERMNO ym, monthly // Define the panel

// Clean out some not needed variables
drop umd smb hml dateff _merge

// Define panel
xtset PERMNO ym, monthly
gen price = abs(PRC) // Price as absolute value of prices
replace price = l1.price if missing(SHROUT) // Forward fill prices
replace SHROUT = l1.SHROUT if missing(SHROUT) // Forward fill SHROUT
gen mcap = price*SHROUT // generate market cap
gen lag_mcap = l1.mcap // lag market cap

// Create Duration Variables
gen NRet = RET < 0
gen PRet = RET > 0
gen ND1Monthly = NRet
gen PD1Monthly = PRet

forvalues i = 1/12{
  local j = `i' + 1
  gen ND`j'Monthly = ND`i'Monthly * l`i'.NRet // Example: ND2 is true if both ND1 is true AND l2.NRet is true
  gen PD`j'Monthly = PD`i'Monthly * l`i'.PRet // Same with Positive returns.
}

gen lgret = ln( 1 + RET ) // P_t/P_{t-1} = 1 + RET, take logs on both sides
gen MOM = exp( l2.lgret + l3.lgret + l4.lgret + l5.lgret + l6.lgret + ///
               l7.lgret + l8.lgret + l9.lgret + l10.lgret + l11.lgret + l12.lgret )-1
               // Momentum as the 2-12 returns.
               
gen STR = l1.RET // Short term reversal as 0-1 returns

// Select Variables to keep
keep PERMNO ym  date lag_mcap NRet PRet ND*Monthly PD*Monthly RET PRIMEXCH MOM STR CUSIP SHROUT PRC

// Save files
save "../Monthly_Variables.dta", replace

dis "Monthly script done"
